// Tests of the real window: that the widgets are wired to the actions and
// to the logic behind them. They need a display, see tests/meson.build.

Reto.Application app;

Reto.Window make_window () {
    var window = new Reto.Window (app);
    window.present ();
    return window;
}

Gtk.Widget? find_widget (Gtk.Widget root, string id) {
    if (((Gtk.Buildable) root).get_buildable_id () == id) {
        return root;
    }
    var child = root.get_first_child ();
    while (child != null) {
        var found = find_widget (child, id);
        if (found != null) {
            return found;
        }
        child = child.get_next_sibling ();
    }
    return null;
}

T widget<T> (Gtk.Widget root, string id) {
    var found = find_widget (root, id);
    assert_nonnull (found);
    assert_true (found is T);
    return (T) found;
}

SimpleAction window_action (Reto.Window window, string name) {
    var action = window.lookup_action (name);
    assert_nonnull (action);
    return (SimpleAction) action;
}

// Runs the main loop until the condition holds. False after 5 seconds.
delegate bool Condition ();

bool wait_for (Condition condition) {
    var context = MainContext.default ();
    var deadline = get_monotonic_time () + 5 * TimeSpan.SECOND;
    while (!condition ()) {
        if (get_monotonic_time () > deadline) {
            return false;
        }
        context.iteration (false);
        Thread.usleep (1000);
    }
    return true;
}

string write_csv (string text) {
    string path;
    try {
        var fd = FileUtils.open_tmp ("reto-XXXXXX.csv", out path);
        FileUtils.set_contents (path, text);
        FileUtils.close (fd);
    } catch (Error e) {
        error ("%s", e.message);
    }
    return path;
}

Reto.Window open_csv (string text) {
    var path = write_csv (text);
    var window = make_window ();
    var status = widget<Gtk.Label> (window, "status_label");
    window.open_file (File.new_for_path (path));
    var loaded = wait_for (() => status.label != "");
    FileUtils.remove (path);
    assert_true (loaded);
    return window;
}

void test_shortcut_actions_exist () {
    var window = make_window ();
    foreach (var shortcut in Reto.Shortcuts.ALL) {
        if (shortcut.action == null) {
            continue;
        }
        var parts = shortcut.action.split (".", 2);
        ActionMap map = parts[0] == "win" ? (ActionMap) window : app;
        if (map.lookup_action (parts[1]) == null) {
            Test.message ("no action %s", shortcut.action);
        }
        assert_nonnull (map.lookup_action (parts[1]));
    }
    window.destroy ();
}

void test_shortcut_accels_are_bound () {
    foreach (var shortcut in Reto.Shortcuts.ALL) {
        if (shortcut.action == null) {
            continue;
        }
        var bound = app.get_accels_for_action (shortcut.action);
        // GTK stores the accelerators in its own spelling.
        string[] expected = {};
        foreach (var accel in shortcut.accels.split (" ")) {
            uint key;
            Gdk.ModifierType mods;
            Gtk.accelerator_parse (accel, out key, out mods);
            expected += Gtk.accelerator_name (key, mods);
        }
        if (string.joinv (" ", bound) != string.joinv (" ", expected)) {
            Test.message ("%s is bound to [%s], expected [%s]",
                shortcut.action, string.joinv (" ", bound),
                string.joinv (" ", expected));
        }
        assert_cmpstrv (bound, expected);
    }
}

void collect_labels (Gtk.Widget root, GenericSet<string> texts) {
    if (root is Gtk.Label) {
        texts.add (((Gtk.Label) root).label);
    }
    var child = root.get_first_child ();
    while (child != null) {
        collect_labels (child, texts);
        child = child.get_next_sibling ();
    }
}

void test_shortcuts_dialog_lists_the_table () {
    var window = make_window ();
    app.activate_action ("shortcuts", null);
    var dialog = window.visible_dialog;
    assert_true (dialog is Adw.ShortcutsDialog);

    // A second request does not open another dialog.
    app.activate_action ("shortcuts", null);
    assert_true (window.visible_dialog == dialog);

    var texts = new GenericSet<string> (str_hash, str_equal);
    assert_true (wait_for (() => {
        collect_labels (dialog, texts);
        return texts.contains (Reto.Shortcuts.ALL[0].title);
    }));
    foreach (var shortcut in Reto.Shortcuts.ALL) {
        if (!texts.contains (shortcut.title)) {
            Test.message ("%s is not in the dialog", shortcut.title);
        }
        assert_true (texts.contains (shortcut.title));
    }
    dialog.force_close ();
    window.destroy ();
}

void test_empty_window () {
    var window = make_window ();
    var stack = widget<Gtk.Stack> (window, "stack");
    assert_cmpstr (stack.visible_child_name, CompareOperator.EQ, "empty");
    assert_false (widget<Gtk.ToggleButton> (window, "search_button").sensitive);
    assert_false (window_action (window, "reset").enabled);
    assert_false (window_action (window, "find-next").enabled);
    window.destroy ();
}

void test_open_shows_rows () {
    var window = open_csv ("k,v\na,1\nb,2\nc,3\n");
    assert_cmpstr (
        widget<Gtk.Stack> (window, "stack").visible_child_name,
        CompareOperator.EQ, "table"
    );
    assert_cmpstr (
        widget<Gtk.Label> (window, "status_label").label,
        CompareOperator.EQ, "3 of 3 rows"
    );
    var table = widget<Gtk.ColumnView> (window, "table");
    assert_cmpuint (table.columns.get_n_items (), CompareOperator.EQ, 2);
    assert_true (widget<Gtk.ToggleButton> (window, "search_button").sensitive);
    window.destroy ();
}

void test_search_counts_and_steps () {
    var window = open_csv ("k,v\nab,1\nb,2\nbb,3\n");
    var entry = widget<Gtk.SearchEntry> (window, "search_entry");
    var count = widget<Gtk.Label> (window, "search_count");

    window.activate_action ("find", null);
    assert_true (widget<Gtk.SearchBar> (window, "search_bar")
        .search_mode_enabled);

    entry.text = "b";
    // The search jumps to the first match.
    assert_true (wait_for (() => count.label == "1 of 3"));
    assert_true (window_action (window, "find-next").enabled);
    assert_true (window_action (window, "find-previous").enabled);

    window.activate_action ("find-next", null);
    assert_cmpstr (count.label, CompareOperator.EQ, "2 of 3");

    window.activate_action ("find-previous", null);
    assert_cmpstr (count.label, CompareOperator.EQ, "1 of 3");

    // Wraps around.
    window.activate_action ("find-previous", null);
    assert_cmpstr (count.label, CompareOperator.EQ, "3 of 3");

    entry.text = "zzz";
    assert_true (wait_for (() => count.label == "No results"));
    assert_true (entry.has_css_class ("error"));
    assert_false (window_action (window, "find-next").enabled);
    window.destroy ();
}

void test_closing_search_resets_it () {
    var window = open_csv ("k,v\nab,1\nb,2\n");
    var entry = widget<Gtk.SearchEntry> (window, "search_entry");
    var count = widget<Gtk.Label> (window, "search_count");
    var bar = widget<Gtk.SearchBar> (window, "search_bar");

    window.activate_action ("find", null);
    entry.text = "b";
    assert_true (wait_for (() => count.label == "1 of 2"));

    bar.search_mode_enabled = false;
    assert_cmpstr (entry.text, CompareOperator.EQ, "");
    assert_cmpstr (count.label, CompareOperator.EQ, "");
    assert_false (window_action (window, "find-next").enabled);
    window.destroy ();
}

void test_sort_enables_reset () {
    var window = open_csv ("k,v\nb,2\na,1\n");
    var table = widget<Gtk.ColumnView> (window, "table");
    var status = widget<Gtk.Label> (window, "status_label");
    var reset = window_action (window, "reset");
    assert_false (reset.enabled);

    var column = (Gtk.ColumnViewColumn) table.columns.get_item (0);
    table.sort_by_column (column, Gtk.SortType.ASCENDING);
    assert_true (reset.enabled);

    window.activate_action ("reset", null);
    assert_false (reset.enabled);
    assert_cmpstr (status.label, CompareOperator.EQ, "2 of 2 rows");
    window.destroy ();
}

void test_filter_menu_filters_rows () {
    var window = open_csv ("k,v\na,1\nb,2\na,3\n");
    var status = widget<Gtk.Label> (window, "status_label");
    var reset = window_action (window, "reset");

    // The filter actions appear once the distinct values are known.
    assert_true (wait_for (() => window.lookup_action ("filter-0") != null));
    window.activate_action (
        "filter-0", new Variant.string (Reto.ViewState.encode_filter ("a"))
    );
    assert_true (reset.enabled);
    assert_true (wait_for (() => status.label == "2 of 3 rows  ·  k: a"));

    window.activate_action ("reset", null);
    assert_true (wait_for (() => status.label == "3 of 3 rows"));
    assert_false (reset.enabled);
    window.destroy ();
}

void main (string[] args) {
    // The windows would open in the desktop of whoever runs the binary by
    // hand, so run only on the private display that Meson sets up.
    if (Environment.get_variable ("RETO_TEST_PRIVATE_DISPLAY") == null) {
        print ("1..0 # SKIP run it with meson test, it opens windows\n");
        return;
    }
    Environment.unset_variable ("WAYLAND_DISPLAY");
    Test.init (ref args);
    Gtk.init ();
    app = new Reto.Application ();
    // Do not take the name of a Reto that is running on this machine.
    app.flags |= ApplicationFlags.NON_UNIQUE;
    try {
        app.register ();
    } catch (Error e) {
        error ("%s", e.message);
    }
    Test.add_func ("/window/shortcut-actions", test_shortcut_actions_exist);
    Test.add_func ("/window/shortcut-accels", test_shortcut_accels_are_bound);
    Test.add_func ("/window/shortcuts-dialog",
        test_shortcuts_dialog_lists_the_table);
    Test.add_func ("/window/empty", test_empty_window);
    Test.add_func ("/window/open", test_open_shows_rows);
    Test.add_func ("/window/search", test_search_counts_and_steps);
    Test.add_func ("/window/search-close", test_closing_search_resets_it);
    Test.add_func ("/window/sort-reset", test_sort_enables_reset);
    Test.add_func ("/window/filter", test_filter_menu_filters_rows);
    Test.run ();
}
