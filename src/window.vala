[GtkTemplate (ui = "/cz/zeropage/Reto/window.ui")]
public class Reto.Window : Adw.ApplicationWindow {
    private const ActionEntry[] ACTION_ENTRIES = {
        { "open", on_open },
    };

    public Window (Gtk.Application app) {
        Object (application: app);
    }

    construct {
        add_action_entries (ACTION_ENTRIES, this);
    }

    public void open_file (File file) {
        title = file.get_basename () ?? file.get_uri ();
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
