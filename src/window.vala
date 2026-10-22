[GtkTemplate (ui = "/cz/zeropage/Reto/window.ui")]
public class Reto.Window : Adw.ApplicationWindow {
    private const ActionEntry[] ACTION_ENTRIES = {
        { "open", on_open },
        { "reset", on_reset },
    };

    private const int MAX_COLUMNS = 500;

    // A column with at most this many distinct values is treated as an enum
    // and gets a filter menu. CSV has no way to declare one.
    private const int MAX_ENUM_VALUES = 50;

    private Cancellable cancellable = new Cancellable ();
    private RowModel? model = null;
    private uint view_generation = 0;
    private ulong status_handler = 0;
    // What the user asked for. The model catches up once the thread is done.
    private int sort_column = -1;
    private bool sort_descending = false;
    private string?[] wanted_filters = {};
    private string[] filter_actions = {};

    [GtkChild]
    private unowned Gtk.Stack stack;
    [GtkChild]
    private unowned Gtk.ColumnView table;
    [GtkChild]
    private unowned Gtk.Spinner sort_spinner;
    [GtkChild]
    private unowned Gtk.Label status_label;

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
                _("Could not open file"), e.message
            );
            dialog.add_response ("close", _("_Close"));
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
        view_generation++;
        sort_spinner.visible = false;
        if (this.model != null) {
            this.model.disconnect (status_handler);
        }
        this.model = null;
        sort_column = -1;
        sort_descending = false;
        wanted_filters = new string?[model.n_columns];
        update_reset ();
        foreach (var name in filter_actions) {
            remove_action (name);
        }
        filter_actions = {};
        while (table.columns.get_n_items () > 0) {
            var column = (Gtk.ColumnViewColumn) table.columns.get_item (0);
            table.remove_column (column);
        }

        for (int i = 0; i < int.min (model.n_columns, MAX_COLUMNS); i++) {
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
        table.model = new Gtk.NoSelection (model);
        stack.visible_child_name = "table";
        add_filters.begin (model);
    }

    private void update_status () {
        if (model == null) {
            return;
        }
        var text = new StringBuilder ();
        text.append (_("%u of %u rows").printf (
            model.get_n_items (), model.n_rows
        ));
        for (int i = 0; i < int.min (model.n_columns, MAX_COLUMNS); i++) {
            var value = model.get_filter (i);
            if (value != null) {
                text.append_printf (
                    "  ·  %s: %s", model.get_column_title (i),
                    value == "" ? _("(empty)") : value
                );
            }
        }
        status_label.label = text.str;
    }

    private async void add_filters (RowModel model) {
        int n = int.min (model.n_columns, MAX_COLUMNS);
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
            // "" is every value; otherwise "v" followed by the value.
            string target = parameter.get_string ();
            var filters = RowModel.copy_filters (
                wanted_filters, model.n_columns
            );
            filters[index] = target == "" ? null : target.substring (1);
            wanted_filters = filters;
            update_reset ();
            refresh.begin (model);
        });
        add_action (action);
        filter_actions += name;

        var menu = new Menu ();
        var action_name = "win." + name;
        var all = new MenuItem (_("All values"), null);
        all.set_action_and_target_value (action_name, new Variant.string (""));
        menu.append_item (all);
        foreach (var value in values) {
            // Underscores would be taken as mnemonics.
            var label = value == "" ? _("(empty)") : value.replace ("_", "__");
            var item = new MenuItem (label, null);
            item.set_action_and_target_value (
                action_name, new Variant.string ("v" + value)
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
        bool active = sort_column >= 0;
        foreach (var value in wanted_filters) {
            active = active || value != null;
        }
        var reset = (SimpleAction) lookup_action ("reset");
        reset.set_enabled (active);
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
        var generation = ++view_generation;
        sort_spinner.visible = true;
        var column = sort_column;
        var descending = sort_descending;
        var filters = wanted_filters;
        var previous = model.view;
        RowView? view = null;
        SourceFunc callback = refresh.callback;
        new Thread<void> ("csv-view", () => {
            view = model.build_view (column, descending, filters, previous);
            Idle.add ((owned) callback);
        });
        yield;
        if (generation == view_generation) {
            model.show_view (view);
            sort_spinner.visible = false;
        }
    }

    private Gtk.ListItemFactory create_factory (int index) {
        var factory = new Gtk.SignalListItemFactory ();
        factory.setup.connect ((item) => {
            ((Gtk.ListItem) item).child = new Gtk.Label (null) {
                xalign = 0,
                ellipsize = Pango.EllipsizeMode.END,
            };
        });
        factory.bind.connect ((item) => {
            var list_item = (Gtk.ListItem) item;
            var cells = ((Row) list_item.item).cells;
            var label = (Gtk.Label) list_item.child;
            label.label = index < cells.length ? cells[index] : "";
        });
        return factory;
    }

    private void on_open () {
        var csv_filter = new Gtk.FileFilter () {
            name = _("CSV files"),
        };
        csv_filter.add_mime_type ("text/csv");
        csv_filter.add_suffix ("csv");

        var all_filter = new Gtk.FileFilter () {
            name = _("All files"),
        };
        all_filter.add_pattern ("*");

        var filters = new ListStore (typeof (Gtk.FileFilter));
        filters.append (csv_filter);
        filters.append (all_filter);

        var dialog = new Gtk.FileDialog () {
            title = _("Open CSV File"),
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
