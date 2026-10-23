[GtkTemplate (ui = "/cz/zeropage/Reto/window.ui")]
public class Reto.Window : Adw.ApplicationWindow {
    private const ActionEntry[] ACTION_ENTRIES = {
        { "open", on_open },
        { "reset", on_reset },
        { "find", on_find },
        { "find-next", on_find_next },
        { "find-previous", on_find_previous },
    };

    private const int MAX_COLUMNS = 500;

    // A column with at most this many distinct values is treated as an enum
    // and gets a filter menu. CSV has no way to declare one.
    private const int MAX_ENUM_VALUES = 50;

    private Cancellable cancellable = new Cancellable ();
    private RowModel? model = null;
    private Generation view_generation = new Generation ();
    private ulong status_handler = 0;
    // What the user asked for. The model catches up once the thread is done.
    private int sort_column = -1;
    private bool sort_descending = false;
    private string?[] wanted_filters = {};
    private string[] filter_actions = {};
    private SearchState search = new SearchState ();
    private GenericArray<Cell> cells = new GenericArray<Cell> ();

    [GtkChild]
    private unowned Gtk.Stack stack;
    [GtkChild]
    private unowned Gtk.ColumnView table;
    [GtkChild]
    private unowned Gtk.Spinner sort_spinner;
    [GtkChild]
    private unowned Gtk.Label status_label;
    [GtkChild]
    private unowned Gtk.SearchBar search_bar;
    [GtkChild]
    private unowned Gtk.SearchEntry search_entry;
    [GtkChild]
    private unowned Gtk.Label search_count;
    [GtkChild]
    private unowned Gtk.ToggleButton search_button;

    public Window (Gtk.Application app) {
        Object (application: app);
    }

    construct {
        add_action_entries (ACTION_ENTRIES, this);

        var drop_target = new Gtk.DropTarget (
            typeof (File), Gdk.DragAction.COPY
        );
        drop_target.drop.connect ((value, x, y) => {
            var file = value.get_object () as File;
            if (file != null) {
                open_file (file);
            }
            return file != null;
        });
        ((Gtk.Widget) this).add_controller (drop_target);

        table.sorter.changed.connect (on_sort_changed);
        update_reset ();

        search_bar.connect_entry (search_entry);
        search_entry.search_changed.connect (() => run_search.begin (true));
        search_entry.activate.connect (on_find_next);
        search_entry.next_match.connect (on_find_next);
        search_entry.previous_match.connect (on_find_previous);
        // Shift+Enter would be a plain Enter for the entry, so catch it first.
        var keys = new Gtk.EventControllerKey () {
            propagation_phase = Gtk.PropagationPhase.CAPTURE,
        };
        keys.key_pressed.connect ((keyval, keycode, state) => {
            bool enter = keyval == Gdk.Key.Return || keyval == Gdk.Key.KP_Enter;
            if (enter && (state & Gdk.ModifierType.SHIFT_MASK) != 0) {
                on_find_previous ();
                return true;
            }
            return false;
        });
        search_entry.add_controller (keys);
        search_bar.notify["search-mode-enabled"].connect (() => {
            if (!search_bar.search_mode_enabled) {
                search_entry.text = "";
                reset_search ();
            }
        });
        show_search (false);
    }

    public void open_file (File file) {
        load.begin (file);
    }

    private async void load (File file) {
        cancellable.cancel ();
        var token = cancellable = new Cancellable ();
        var previous_page = stack.visible_child_name;
        stack.visible_child_name = "loading";

        try {
            var bytes = yield file.load_bytes_async (token, null);
            var model = yield parse (bytes);
            if (token.is_cancelled ()) {
                return;
            }
            show_model (model);
            title = file.get_basename () ?? file.get_uri ();
        } catch (IOError.CANCELLED e) {
            return;
        } catch (Error e) {
            stack.visible_child_name = previous_page;
            var dialog = new Adw.AlertDialog (
                "Could not open file", e.message
            );
            dialog.add_response ("close", "_Close");
            dialog.present (this);
        }
    }

    private async RowModel parse (Bytes bytes) {
        RowModel? model = null;
        SourceFunc callback = parse.callback;
        new Thread<void> ("csv-parser", () => {
            model = new RowModel (CsvParser.parse (bytes.get_data ()));
            Idle.add ((owned) callback);
        });
        yield;
        return model;
    }

    private void show_model (RowModel model) {
        view_generation.invalidate ();
        sort_spinner.visible = false;
        if (this.model != null) {
            this.model.disconnect (status_handler);
        }
        this.model = null;
        sort_column = -1;
        sort_descending = false;
        wanted_filters = new string?[model.n_columns];
        update_reset ();
        // Closing the search bar resets the search.
        if (search_bar.search_mode_enabled) {
            search_bar.search_mode_enabled = false;
        } else {
            reset_search ();
        }
        search_button.sensitive = true;
        foreach (var name in filter_actions) {
            remove_action (name);
        }
        filter_actions = {};
        while (table.columns.get_n_items () > 0) {
            var column = (Gtk.ColumnViewColumn) table.columns.get_item (0);
            table.remove_column (column);
        }

        int n = ViewState.shown_columns (model, MAX_COLUMNS);
        for (int i = 0; i < n; i++) {
            table.append_column (new Gtk.ColumnViewColumn (
                model.get_column_title (i), create_factory (i)
            ) {
                id = i.to_string (),
                // The sort itself is done by the model, see on_sort_changed.
                sorter = new Gtk.CustomSorter ((a, b) => 0),
            });
        }
        this.model = model;
        status_handler = model.items_changed.connect (update_status);
        update_status ();
        table.model = new Gtk.SingleSelection (model);
        stack.visible_child_name = "table";
        // The table may still be scrolled where the previous file was.
        move_cursor (0, true);
        add_filters.begin (model);
    }

    private void update_status () {
        if (model == null) {
            return;
        }
        status_label.label = ViewState.describe_status (model, MAX_COLUMNS);
    }

    private async void add_filters (RowModel model) {
        int n = ViewState.shown_columns (model, MAX_COLUMNS);
        var values = new GenericArray<GenericArray<string>?> ();
        SourceFunc callback = add_filters.callback;
        new Thread<void> ("csv-enums", () => {
            for (int i = 0; i < n; i++) {
                values.add (model.distinct_values (i, MAX_ENUM_VALUES));
            }
            Idle.add ((owned) callback);
        });
        yield;
        if (model != this.model) {
            return;
        }

        for (int i = 0; i < n; i++) {
            var column = (Gtk.ColumnViewColumn?) table.columns.get_item (i);
            if (column != null && values[i] != null) {
                column.header_menu = create_filter_menu (model, i, values[i]);
            }
        }
    }

    private MenuModel create_filter_menu (
        RowModel model, int index, GenericArray<string> values
    ) {
        var name = "filter-%d".printf (index);
        var action = new SimpleAction.stateful (
            name, VariantType.STRING, new Variant.string ("")
        );
        action.activate.connect ((parameter) => {
            action.set_state (parameter);
            var filters = RowModel.copy_filters (
                wanted_filters, model.n_columns
            );
            filters[index] = ViewState.decode_filter (parameter.get_string ());
            wanted_filters = filters;
            update_reset ();
            refresh.begin (model);
        });
        add_action (action);
        filter_actions += name;

        var menu = new Menu ();
        var action_name = "win." + name;
        var all = new MenuItem ("All values", null);
        all.set_action_and_target_value (action_name, new Variant.string (""));
        menu.append_item (all);
        foreach (var value in values) {
            var item = new MenuItem (ViewState.filter_label (value), null);
            item.set_action_and_target_value (
                action_name,
                new Variant.string (ViewState.encode_filter (value))
            );
            menu.append_item (item);
        }
        return menu;
    }

    private void on_sort_changed () {
        if (model == null) {
            return;
        }
        var sorter = (Gtk.ColumnViewSorter) table.sorter;
        var column = sorter.get_primary_sort_column ();
        sort_column = column != null ? int.parse (column.id) : -1;
        sort_descending =
            sorter.get_primary_sort_order () == Gtk.SortType.DESCENDING;
        update_reset ();
        refresh.begin (model);
    }

    // Reset is only available while there is a sort order or a filter.
    private void update_reset () {
        var reset = (SimpleAction) lookup_action ("reset");
        reset.set_enabled (ViewState.can_reset (sort_column, wanted_filters));
    }

    private void on_reset () {
        if (model == null) {
            return;
        }
        wanted_filters = new string?[model.n_columns];
        foreach (var name in filter_actions) {
            var action = (SimpleAction) lookup_action (name);
            action.set_state (new Variant.string (""));
        }
        if (sort_column >= 0) {
            // Changes the sorter, so on_sort_changed refreshes the view.
            table.sort_by_column (null, Gtk.SortType.ASCENDING);
        } else {
            update_reset ();
            refresh.begin (model);
        }
    }

    // Sorts and filters in a thread, then shows the result. A newer request
    // makes the result of an older one obsolete.
    private async void refresh (RowModel model) {
        var ticket = view_generation.next ();
        sort_spinner.visible = true;
        var column = sort_column;
        var descending = sort_descending;
        var filters = wanted_filters;
        var previous = model.view;
        var cursor = get_cursor_record ();
        RowView? view = null;
        int cursor_position = -1;
        SourceFunc callback = refresh.callback;
        new Thread<void> ("csv-view", () => {
            view = model.build_view (column, descending, filters, previous);
            cursor_position = model.position_in (view, cursor);
            Idle.add ((owned) callback);
        });
        yield;
        if (view_generation.is_current (ticket)) {
            search.remember_anchor (model);
            model.show_view (view);
            // Stay on the record the cursor was on, if it is still shown.
            move_cursor (ViewState.cursor_target (cursor_position), false);
            sort_spinner.visible = false;
            if (search_entry.text != "") {
                // The rows moved, so the matches did too.
                run_search.begin (false);
            }
        }
    }

    // The record the cursor is on, or null.
    private Record? get_cursor_record () {
        var selection = (Gtk.SingleSelection) table.model;
        return selection != null ? model.get_record (selection.selected) : null;
    }

    // Puts the cursor on a row and scrolls to it. Does nothing without rows.
    private void move_cursor (int position, bool focus) {
        if (model == null || !ViewState.can_move_cursor (
            position, model.get_n_items ()
        )) {
            return;
        }
        var flags = Gtk.ListScrollFlags.SELECT;
        if (focus) {
            flags |= Gtk.ListScrollFlags.FOCUS;
        }
        table.scroll_to (position, null, flags, null);
    }

    private void on_find () {
        if (model == null) {
            return;
        }
        search_bar.search_mode_enabled = true;
        search_entry.grab_focus ();
    }

    private void on_find_next () {
        find_step (1);
    }

    private void on_find_previous () {
        find_step (-1);
    }

    private void find_step (int delta) {
        if (search.is_stale (search_entry.text)) {
            // The search is still catching up with what was typed.
            run_search.begin (true);
            return;
        }
        if (!search.has_matches) {
            return;
        }
        search.step (delta);
        show_search (true);
    }

    private void reset_search () {
        search.reset ();
        show_search (false);
    }

    // Looks for the text of the search entry in the rows shown now. The
    // search is on the first match if ''jump'' is set, otherwise it stays on
    // the record it was on, if that still matches.
    private async void run_search (bool jump) {
        var request = search.begin (model, search_entry.text, jump);
        if (request == null) {
            show_search (false);
            return;
        }

        search_count.label = "Searching…";
        SearchResult? result = null;
        SourceFunc callback = run_search.callback;
        new Thread<void> ("csv-search", () => {
            result = request.model.find_rows (
                request.query, request.view, MAX_COLUMNS, request.anchor
            );
            Idle.add ((owned) callback);
        });
        yield;
        if (search.finish (request, result, this.model, jump)) {
            show_search (jump);
        }
    }

    // Shows the state of the search: the count, the marked cells and the
    // available actions. Scrolls to the match the search is on if ''scroll''.
    private void show_search (bool scroll) {
        string query = search_entry.text;
        search_count.label = ViewState.describe_search (
            query, search.result, search.current
        );
        if (ViewState.search_failed (query, search.result)) {
            search_entry.add_css_class ("error");
        } else {
            search_entry.remove_css_class ("error");
        }
        ((SimpleAction) lookup_action ("find-next")).set_enabled (
            search.has_matches
        );
        ((SimpleAction) lookup_action ("find-previous")).set_enabled (
            search.has_matches
        );

        search.locate (model, MAX_COLUMNS);
        foreach (var cell in cells) {
            highlight_cell (cell);
        }
        if (scroll && search.column >= 0) {
            var column = (Gtk.ColumnViewColumn?) table.columns.get_item (
                search.column
            );
            // Not FOCUS, which would take the focus from the search entry.
            table.scroll_to (
                search.row, column, Gtk.ListScrollFlags.SELECT, null
            );
        }
    }

    private void highlight_cell (Cell cell) {
        cell.highlight (
            search.result != null ? search.result.matcher : null,
            search.row, search.column
        );
    }

    private Gtk.ListItemFactory create_factory (int index) {
        var factory = new Gtk.SignalListItemFactory ();
        factory.setup.connect ((item) => {
            var cell = new Cell (index);
            cells.add (cell);
            ((Gtk.ListItem) item).child = cell;
        });
        factory.teardown.connect ((item) => {
            cells.remove ((Cell) ((Gtk.ListItem) item).child);
        });
        factory.bind.connect ((item) => {
            var list_item = (Gtk.ListItem) item;
            var row_cells = ((Row) list_item.item).cells;
            var cell = (Cell) list_item.child;
            cell.row = (int) list_item.position;
            cell.text = index < row_cells.length ? row_cells[index] : "";
            highlight_cell (cell);
        });
        factory.unbind.connect ((item) => {
            ((Cell) ((Gtk.ListItem) item).child).row = -1;
        });
        return factory;
    }

    private void on_open () {
        var csv_filter = new Gtk.FileFilter () {
            name = "CSV files",
        };
        csv_filter.add_mime_type ("text/csv");
        csv_filter.add_suffix ("csv");

        var all_filter = new Gtk.FileFilter () {
            name = "All files",
        };
        all_filter.add_pattern ("*");

        var filters = new ListStore (typeof (Gtk.FileFilter));
        filters.append (csv_filter);
        filters.append (all_filter);

        var dialog = new Gtk.FileDialog () {
            title = "Open CSV File",
            filters = filters,
            default_filter = csv_filter,
        };

        dialog.open.begin (this, null, (obj, res) => {
            try {
                open_file (dialog.open.end (res));
            } catch (Gtk.DialogError e) {
                if (e.code != Gtk.DialogError.DISMISSED &&
                    e.code != Gtk.DialogError.CANCELLED) {
                    warning ("Could not open file: %s", e.message);
                }
            } catch (Error e) {
                warning ("Could not open file: %s", e.message);
            }
        });
    }
}
