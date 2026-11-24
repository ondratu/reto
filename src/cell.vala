/**
 * A table cell. It marks the text found by a search and asks for a context
 * menu on a secondary click or a long press. The cell fills the whole area
 * of the table cell, see style.css, so that a click anywhere in it does the
 * same. See docs/selection-and-copy.md.
 */
public class Reto.Cell : Gtk.Box {
    private Gtk.Label label = new Gtk.Label (null) {
        xalign = 0f,
        hexpand = true,
        ellipsize = Pango.EllipsizeMode.END,
    };

    public int column { get; construct; }
    // The row the cell is bound to now, or -1.
    public int row = -1;

    public string text {
        get { return label.label; }
        set { label.label = value; }
    }

    /**
     * The secondary button was pressed (or the cell was long pressed) at a
     * point of the cell.
     */
    public signal void context_menu (double x, double y);

    public Cell (int column) {
        Object (column: column);
    }

    construct {
        append (label);

        var secondary = new Gtk.GestureClick () {
            button = Gdk.BUTTON_SECONDARY,
            propagation_phase = Gtk.PropagationPhase.CAPTURE,
        };
        secondary.pressed.connect ((n_press, x, y) => {
            secondary.set_state (Gtk.EventSequenceState.CLAIMED);
            context_menu (x, y);
        });
        add_controller (secondary);

        var long_press = new Gtk.GestureLongPress () {
            touch_only = true,
        };
        long_press.pressed.connect ((x, y) => {
            long_press.set_state (Gtk.EventSequenceState.CLAIMED);
            context_menu (x, y);
        });
        add_controller (long_press);
    }

    /**
     * Marks the cell if its text matches, with the match in bold. The cell at
     * ''current_row'' and ''current_column'' is the one the search is on.
     */
    public void highlight (
        Matcher? matcher, int current_row, int current_column
    ) {
        remove_css_class ("match");
        remove_css_class ("current-match");
        label.attributes = null;

        if (matcher == null || row < 0) {
            return;
        }
        var found = matcher.describe (
            text, row == current_row && column == current_column
        );
        if (!found.found) {
            return;
        }
        add_css_class (found.current ? "current-match" : "match");
        var bold = Pango.attr_weight_new (Pango.Weight.BOLD);
        bold.start_index = found.start;
        bold.end_index = found.end;
        var list = new Pango.AttrList ();
        list.insert ((owned) bold);
        label.attributes = list;
    }
}
