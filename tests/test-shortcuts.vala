void test_accels_parse () {
    foreach (var shortcut in Reto.Shortcuts.ALL) {
        foreach (var accel in shortcut.accels.split (" ")) {
            uint key;
            Gdk.ModifierType mods;
            assert_true (Gtk.accelerator_parse (accel, out key, out mods));
            assert_true (key != 0);
        }
    }
}

void test_accels_are_unique () {
    // Keys of the find field are only active there, but still should not
    // repeat an accelerator, so every one is checked against all others.
    var seen = new HashTable<string, string> (str_hash, str_equal);
    foreach (var shortcut in Reto.Shortcuts.ALL) {
        foreach (var accel in shortcut.accels.split (" ")) {
            uint key;
            Gdk.ModifierType mods;
            Gtk.accelerator_parse (accel, out key, out mods);
            var id = Gtk.accelerator_name (key, mods);
            var other = seen.lookup (id);
            if (other != null) {
                Test.message (
                    "%s is used by %s and %s", id, other, shortcut.title
                );
            }
            assert_null (other);
            seen.insert (id, shortcut.title);
        }
    }
}

void test_entries_are_complete () {
    foreach (var shortcut in Reto.Shortcuts.ALL) {
        assert_true (shortcut.section != "");
        assert_true (shortcut.title != "");
        assert_true (shortcut.accels != "");
        if (shortcut.action != null) {
            // Actions are "win.name" or "app.name".
            assert_true (
                shortcut.action.has_prefix ("win.") ||
                shortcut.action.has_prefix ("app.")
            );
        }
    }
}

void test_sections_are_contiguous () {
    // The shortcuts dialog starts a new section whenever the name changes.
    var seen = new GenericSet<string> (str_hash, str_equal);
    string? last = null;
    foreach (var shortcut in Reto.Shortcuts.ALL) {
        if (shortcut.section != last) {
            assert_false (seen.contains (shortcut.section));
            seen.add (shortcut.section);
            last = shortcut.section;
        }
    }
}

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/shortcuts/parse", test_accels_parse);
    Test.add_func ("/shortcuts/unique", test_accels_are_unique);
    Test.add_func ("/shortcuts/complete", test_entries_are_complete);
    Test.add_func ("/shortcuts/sections", test_sections_are_contiguous);
    Test.run ();
}
