/**
 * Texts and rules of the table view that do not need any widget.
 */
namespace Reto.ViewState {
    /**
     * Number of columns to show: all of them, up to ''limit''.
     */
    public int shown_columns (RowModel model, int limit) {
        return int.min (model.n_columns, limit);
    }

    /**
     * The status line: the number of rows shown and the active filters.
     */
    public string describe_status (RowModel model, int limit) {
        var text = new StringBuilder ();
        text.append ("%u of %u rows".printf (
            model.get_n_items (), model.n_rows
        ));
        int n = shown_columns (model, limit);
        for (int i = 0; i < n; i++) {
            var value = model.get_filter (i);
            if (value != null) {
                text.append_printf (
                    "  ·  %s: %s", model.get_column_title (i),
                    value == "" ? "(empty)" : value
                );
            }
        }
        return text.str;
    }

    /**
     * The search counter. ''current'' is the index of the match the search
     * is on, or -1.
     */
    public string describe_search (
        string query, SearchResult? search, int current
    ) {
        if (query == "" || search == null) {
            return "";
        }
        uint count = search.count;
        if (count == 0) {
            return "No results";
        }
        if (current < 0) {
            return (count == 1 ? "%u match" : "%u matches").printf (count);
        }
        return "%d of %u".printf (current + 1, count);
    }

    /**
     * Whether the search for a query found nothing.
     */
    public bool search_failed (string query, SearchResult? search) {
        return query != "" && search != null && search.count == 0;
    }

    /**
     * The target of a filter menu item: "" is every value, otherwise "v"
     * followed by the value, so that an empty value can be told apart.
     */
    public string encode_filter (string? value) {
        return value == null ? "" : "v" + value;
    }

    /**
     * The value to filter by for a menu target, or null for every value.
     */
    public string? decode_filter (string target) {
        return target == "" ? null : target.substring (1);
    }

    /**
     * The label of a filter menu item for a value.
     */
    public string filter_label (string value) {
        // Underscores would be taken as mnemonics.
        return value == "" ? "(empty)" : value.replace ("_", "__");
    }

    /**
     * Reset is only available while there is a sort order or a filter.
     */
    public bool can_reset (int sort_column, string?[] filters) {
        if (sort_column >= 0) {
            return true;
        }
        foreach (var value in filters) {
            if (value != null) {
                return true;
            }
        }
        return false;
    }

    /**
     * Where to put the cursor after the rows changed, given the position of
     * the record it was on in the new rows (-1 if it is not shown anymore).
     */
    public int cursor_target (int found) {
        return found >= 0 ? found : 0;
    }

    /**
     * Whether there is a row to put the cursor on.
     */
    public bool can_move_cursor (int position, uint n_items) {
        return position >= 0 && (uint) position < n_items;
    }
}
