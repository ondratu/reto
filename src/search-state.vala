/**
 * A search to run in a thread, made by {@link SearchState.begin}.
 */
public class Reto.SearchRequest {
    public uint ticket;
    public RowModel model;
    public string query;
    public RowView view;
    public Record? anchor;
}

/**
 * What the search of a table is on: the matches in the rows shown, the match
 * the user is at and the cell it is in. It decides when a result is still
 * wanted and how to stay on the same record when the rows move, and leaves
 * the widgets to the window.
 */
public class Reto.SearchState {
    private Generation generation = new Generation ();
    // What ''result'' was made for: the query and the rows it was looking at.
    private RowView? view = null;
    // The record the search was on before the rows moved, to stay on it.
    private Record? anchor = null;

    public SearchResult? result { get; private set; default = null; }
    public string query { get; private set; default = ""; }
    // Index of the match the search is on, or -1.
    public int current { get; private set; default = -1; }
    // The cell of that match, or -1.
    public int row { get; private set; default = -1; }
    public int column { get; private set; default = -1; }

    public bool has_matches {
        get { return result != null && result.count > 0; }
    }

    /**
     * Forgets the search. A search still running is dropped.
     */
    public void reset () {
        generation.invalidate ();
        result = null;
        query = "";
        view = null;
        anchor = null;
        current = -1;
        row = -1;
        column = -1;
    }

    /**
     * Whether the search is behind ''text'', the text typed in the search
     * entry.
     */
    public bool is_stale (string text) {
        return text != query;
    }

    /**
     * Starts a search for ''text'' in the rows shown now. Returns what to
     * look for, or null if there is nothing to look for, in which case the
     * search is reset. It will go to the first match if ''jump'' is set,
     * otherwise it stays on the record it was on, if that still matches.
     */
    public SearchRequest? begin (RowModel? model, string text, bool jump) {
        if (jump) {
            anchor = null;
        }
        if (model == null || text == "") {
            reset ();
            return null;
        }
        return new SearchRequest () {
            ticket = generation.next (),
            model = model,
            query = text,
            view = model.view,
            anchor = anchor,
        };
    }

    /**
     * Takes the result of a request. Returns false, and changes nothing, if
     * there is no result, a newer search was started since or the table shows
     * another file now.
     */
    public bool finish (
        SearchRequest request, SearchResult? found, RowModel? shown,
        bool jump
    ) {
        if (found == null || !generation.is_current (request.ticket) ||
            request.model != shown) {
            return false;
        }
        result = found;
        query = request.query;
        view = request.view;
        anchor = null;
        current = jump ? found.step (-1, 1) : found.anchor_index;
        return true;
    }

    /**
     * Moves to the next match (''delta'' 1) or the previous one (-1). Does
     * nothing without matches.
     */
    public void step (int delta) {
        if (has_matches) {
            current = result.step (current, delta);
        }
    }

    /**
     * Remembers the record the search is on. Call it before the rows of the
     * model change, then start a search without ''jump'' to stay on it.
     */
    public void remember_anchor (RowModel model) {
        if (view == model.view) {
            anchor = row >= 0 ? model.get_record (row) : null;
        }
    }

    /**
     * Finds the cell of the match the search is on, looking at no more than
     * ''max_columns'' columns.
     */
    public void locate (RowModel? model, int max_columns) {
        row = -1;
        column = -1;
        if (result == null || current < 0 || current >= result.count ||
            model == null) {
            return;
        }
        row = (int) result.position_at (current);
        var record = model.get_record (row);
        if (record != null) {
            column = result.matcher.first_column (record.cells, max_columns);
        }
    }
}
