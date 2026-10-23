public class Reto.Application : Adw.Application {
    private const ActionEntry[] ACTION_ENTRIES = {
        { "shortcuts", on_shortcuts },
        { "about", on_about },
        { "quit", on_quit },
    };

    public Application () {
        Object (
            application_id: Config.APP_ID,
            flags: ApplicationFlags.HANDLES_OPEN,
            resource_base_path: "/cz/zeropage/Reto"
        );
    }

    construct {
        add_action_entries (ACTION_ENTRIES, this);
        foreach (var shortcut in Shortcuts.ALL) {
            if (shortcut.action != null) {
                set_accels_for_action (
                    shortcut.action, shortcut.accels.split (" ")
                );
            }
        }
    }

    protected override void activate () {
        var window = active_window ?? new Window (this);
        window.present ();
    }

    protected override void open (File[] files, string hint) {
        foreach (var file in files) {
            var window = new Window (this);
            window.open_file (file);
            window.present ();
        }
    }

    private void on_shortcuts () {
        var window = active_window as Adw.ApplicationWindow;
        if (window == null || window.visible_dialog is Adw.ShortcutsDialog) {
            return;
        }
        var dialog = new Adw.ShortcutsDialog ();
        Adw.ShortcutsSection? section = null;
        foreach (var shortcut in Shortcuts.ALL) {
            if (section == null || section.title != shortcut.section) {
                section = new Adw.ShortcutsSection (shortcut.section);
                dialog.add (section);
            }
            section.add (new Adw.ShortcutsItem (
                shortcut.title, shortcut.accels
            ));
        }
        dialog.present (window);
    }

    private void on_about () {
        var about = new Adw.AboutDialog () {
            application_name = "Reto",
            application_icon = Config.APP_ID,
            version = Config.VERSION,
            comments = "A simple CSV file viewer",
            website = "https://github.com/ondratu/reto",
            issue_url = "https://github.com/ondratu/reto/issues",
            license_type = Gtk.License.MIT_X11,
            copyright = "© 2026 Reto contributors",
            developers = { "Ondřej Tůma" },
        };
        about.present (active_window);
    }

    private void on_quit () {
        quit ();
    }
}
