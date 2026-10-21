[GtkTemplate (ui = "/cz/zeropage/Reto/window.ui")]
public class Reto.Window : Adw.ApplicationWindow {
    private const ActionEntry[] ACTION_ENTRIES = {
        { "open", on_open },
    };

    private const int MAX_COLUMNS = 500;

    private Cancellable cancellable = new Cancellable ();

    [GtkChild]
    private unowned Gtk.Stack stack;
    [GtkChild]
    private unowned Gtk.ColumnView table;

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
        while (table.columns.get_n_items () > 0) {
            var column = (Gtk.ColumnViewColumn) table.columns.get_item (0);
            table.remove_column (column);
        }

        for (int i = 0; i < int.min (model.n_columns, MAX_COLUMNS); i++) {
            table.append_column (new Gtk.ColumnViewColumn (
                model.get_column_title (i), create_factory (i)
            ));
        }
        table.model = new Gtk.NoSelection (model);
        stack.visible_child_name = "table";
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
