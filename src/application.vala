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

    // The single source for the accelerators and the shortcuts dialog. Entries
    // without an action are keys handled by a widget, not by an action.
    private const Shortcut[] SHORTCUTS = {
        { "File", "Open a File", "win.open", "<Control>o" },
        {
            "File", "Reset Sorting and Filters", "win.reset",
            "<Control><Shift>r"
        },
        { "Find", "Find in the Table", "win.find", "<Control>f" },
        {
            "Find", "Next Match", "win.find-next",
            "F3 <Control>g"
        },
        {
            "Find", "Previous Match", "win.find-previous",
            "<Shift>F3 <Control><Shift>g"
        },
        { "In the Find Field", "Next Match", null, "Return" },
        { "In the Find Field", "Previous Match", null, "<Shift>Return" },
        { "In the Find Field", "Close Find", null, "Escape" },
        {
            "General", "Keyboard Shortcuts", "app.shortcuts",
            "<Control>question"
        },
        { "General", "Quit", "app.quit", "<Control>q" },
    };

    private struct Shortcut {
        public string section;
        public string title;
        public string? action;
        // Space separated, as GTK parses them.
        public string accels;
    }

    construct {
        add_action_entries (ACTION_ENTRIES, this);
        foreach (var shortcut in SHORTCUTS) {
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
        foreach (var shortcut in SHORTCUTS) {
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
