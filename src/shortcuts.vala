public struct Reto.Shortcut {
    public string section;
    public string title;
    public string? action;
    // Space separated, as GTK parses them.
    public string accels;
}

/**
 * The single source for the accelerators and the shortcuts dialog. Entries
 * without an action are keys handled by a widget, not by an action.
 */
namespace Reto.Shortcuts {
    public const Shortcut[] ALL = {
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
        { "Table", "Select All Rows", null, "<Control>a" },
        { "Table", "Copy the Selected Rows", null, "<Control>c" },
        {
            "General", "Keyboard Shortcuts", "app.shortcuts",
            "<Control>question"
        },
        { "General", "Quit", "app.quit", "<Control>q" },
    };
}
