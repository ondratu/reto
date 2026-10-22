/**
 * Case-insensitive substring match. Immutable, so it can be shared between
 * threads. Characters are compared one by one, so offsets into the text stay
 * valid even where changing case would change the length of a string.
 */
public class Reto.Matcher {
    private unichar[] needle = {};

    public bool is_empty {
        get { return needle.length == 0; }
    }

    public Matcher (string query) {
        int i = 0;
        unichar c;
        while (query.get_next_char (ref i, out c)) {
            needle += c.tolower ();
        }
    }

    /**
     * Finds the first match in ''text''. ''start'' and ''end'' are byte
     * offsets of the match. An empty query matches nothing.
     */
    public bool find (string text, out int start, out int end) {
        start = 0;
        end = 0;
        if (is_empty) {
            return false;
        }
        int from = 0;
        unichar first;
        while (text.get_next_char (ref from, out first)) {
            int pos = from;
            if (first.tolower () == needle[0] && match_rest (text, ref pos)) {
                end = pos;
                // ''from'' is past the first character of the match.
                start = from - first.to_string ().length;
                return true;
            }
        }
        return false;
    }

    public bool matches (string text) {
        int start;
        int end;
        return find (text, out start, out end);
    }

    /**
     * What to show of ''text'': whether it matches and where. ''is_current''
     * says that the search is on this cell.
     */
    public Highlight describe (string text, bool is_current) {
        var highlight = new Highlight ();
        highlight.found = find (text, out highlight.start, out highlight.end);
        highlight.current = highlight.found && is_current;
        return highlight;
    }

    /**
     * Index of the first cell that matches, looking at no more than ''limit''
     * cells, or -1.
     */
    public int first_column (string[] cells, int limit) {
        for (int i = 0; i < int.min (cells.length, limit); i++) {
            if (matches (cells[i])) {
                return i;
            }
        }
        return -1;
    }

    // The characters of the needle after its first one, from ''pos''.
    private bool match_rest (string text, ref int pos) {
        for (int i = 1; i < needle.length; i++) {
            unichar c;
            if (!text.get_next_char (ref pos, out c) ||
                c.tolower () != needle[i]) {
                return false;
            }
        }
        return true;
    }
}

/**
 * How a cell shows a search: whether its text matches, whether it is the cell
 * the search is on, and the byte offsets of the match.
 */
public class Reto.Highlight {
    public bool found = false;
    public bool current = false;
    public int start = 0;
    public int end = 0;
}

/**
 * Where a {@link Matcher} matches in the rows of a view: the positions of the
 * rows, in the order they are shown. Built by {@link RowModel.find_rows} and
 * not changed afterwards.
 */
public class Reto.SearchResult {
    public Matcher matcher;
    private uint[] positions = {};
    // Index of the match in the row asked for, or -1. See find_rows.
    public int anchor_index = -1;

    public uint count {
        get { return positions.length; }
    }

    public SearchResult (Matcher matcher) {
        this.matcher = matcher;
    }

    public void add (uint position) {
        positions += position;
    }

    /**
     * Position of the row of match number ''index''.
     */
    public uint position_at (int index) {
        return positions[index];
    }

    /**
     * Index of the match ''delta'' (1 or -1) away from match ''current'',
     * wrapping around. A ''current'' of -1 means no match is selected yet:
     * forwards goes to the first match, backwards to the last. Returns -1 if
     * there are no matches.
     */
    public int step (int current, int delta) {
        int n = (int) count;
        if (n == 0) {
            return -1;
        }
        if (current < 0) {
            return delta > 0 ? 0 : n - 1;
        }
        return (current + delta + n) % n;
    }
}
