public class Reto.Application : Adw.Application {
    private const ActionEntry[] ACTION_ENTRIES = {
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
        set_accels_for_action ("app.quit", { "<Control>q" });
        set_accels_for_action ("win.open", { "<Control>o" });
        set_accels_for_action ("win.reset", { "<Control><Shift>r" });
        set_accels_for_action ("win.find", { "<Control>f" });
        set_accels_for_action (
            "win.find-next", { "F3", "<Control>g" }
        );
        set_accels_for_action (
            "win.find-previous", { "<Shift>F3", "<Control><Shift>g" }
        );
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

    private void on_about () {
        var about = new Adw.AboutDialog () {
            application_name = _("Reto"),
            application_icon = Config.APP_ID,
            version = Config.VERSION,
            comments = _("A simple CSV file viewer"),
            website = "https://github.com/ondratu/reto",
            issue_url = "https://github.com/ondratu/reto/issues",
            license_type = Gtk.License.MIT_X11,
            copyright = "© 2026 Reto contributors",
            developers = { "Ondřej Tůma" },
            translator_credits = _("translator-credits"),
        };
        about.present (active_window);
    }

    private void on_quit () {
        quit ();
    }
}
