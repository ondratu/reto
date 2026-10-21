/**
 * Read-only list of parsed records. The first record is the header, the rest
 * are rows. Rows are created on demand, so a large file costs one string
 * array per record rather than one object.
 */
public class Reto.RowModel : Object, ListModel {
    private GenericArray<Record> records;

    /**
     * The rows currently shown. Replace it with {@link show_view}.
     */
    public RowView view { get; private set; default = new RowView (); }

    public string[] header { get; private set; default = {}; }
    public int n_columns { get; private set; }

    public RowModel (GenericArray<Record> records) {
        this.records = records;
        if (records.length > 0) {
            header = records[0].cells;
        }
        foreach (var record in records) {
            n_columns = int.max (n_columns, record.cells.length);
        }
    }

    /**
     * Title of a column: its header cell, or the 1-based number if empty.
     */
    public string get_column_title (int column) {
        if (column < header.length && header[column] != "") {
            return header[column];
        }
        return (column + 1).to_string ();
    }

    /**
     * Number of rows in the file, whatever the filters show.
     */
    public uint n_rows {
        get { return records.length > 0 ? records.length - 1 : 0; }
    }

    /**
     * The value a column is filtered by, or null if it is not filtered.
     */
    public string? get_filter (int column) {
        var filters = view.filters;
        return column >= 0 && column < filters.length ? filters[column] : null;
    }

    public Type get_item_type () {
        return typeof (Row);
    }

    public uint get_n_items () {
        if (view.filtered != null) {
            return view.filtered.length;
        }
        return n_rows;
    }

    public Object? get_item (uint position) {
        if (position >= get_n_items ()) {
            return null;
        }
        Record record;
        if (view.filtered != null) {
            record = view.filtered[position];
        } else if (view.sorted != null) {
            record = view.sorted[position];
        } else {
            record = records[position + 1];
        }
        return new Row (record.cells);
    }

    /**
     * Builds the view for an order and a set of filters. Does not touch the
     * model, so it can run in a thread; hand the result to {@link show_view}.
     * ''previous'' is the view shown now: its sorted rows are reused if it
     * is already ordered the same way.
     *
     * Columns where every non-empty cell is a number sort numerically, the
     * others alphabetically. The sort is stable. A negative ''column'' keeps
     * the file order. ''filters'' holds, per column, the value a cell must
     * equal, or null for no filter.
     */
    public RowView build_view (
        int column, bool descending, string?[] filters, RowView previous
    ) {
        var result = new RowView () {
            column = column,
            descending = descending,
            filters = filters,
        };
        if (column >= 0) {
            if (previous.sorted != null && previous.column == column &&
                previous.descending == descending) {
                result.sorted = previous.sorted;
            } else {
                result.sorted = sort_by (column, descending);
            }
        }
        result.filtered = filter_rows (result.sorted, filters);
        return result;
    }

    /**
     * Shows the rows of a view made by {@link build_view}.
     */
    public void show_view (RowView view) {
        uint removed = get_n_items ();
        this.view = view;
        items_changed (0, removed, get_n_items ());
    }

    /**
     * Orders the rows by a column, or by file order if ''column'' is
     * negative, keeping the filters. Blocks while sorting.
     */
    public void set_order (int column, bool descending) {
        show_view (build_view (column, descending, view.filters, view));
    }

    /**
     * Shows only the rows whose cell in a column equals ''value'', or all
     * rows again if null. Filters of different columns combine. Blocks while
     * filtering.
     */
    public void set_filter (int column, string? value) {
        if (column < 0 || column >= n_columns) {
            return;
        }
        var filters = copy_filters (view.filters, n_columns);
        filters[column] = value;
        show_view (build_view (view.column, view.descending, filters, view));
    }

    /**
     * Copy of a filter array, resized to ''n'' columns.
     */
    public static string?[] copy_filters (string?[] filters, int n) {
        string?[] copy = new string?[n];
        for (int i = 0; i < int.min (n, filters.length); i++) {
            copy[i] = filters[i];
        }
        return copy;
    }

    private GenericArray<Record> sort_by (int column, bool descending) {
        bool numeric = true;
        for (int i = 1; i < records.length && numeric; i++) {
            numeric = is_number (cell_at (records[i], column));
        }

        var entries = new GenericArray<SortEntry> (records.length);
        for (int i = 1; i < records.length; i++) {
            entries.add (new SortEntry (
                records[i], cell_at (records[i], column), numeric
            ));
        }

        entries.sort_with_data ((a, b) => {
            int result = a.compare (b);
            return descending ? -result : result;
        });

        var rows = new GenericArray<Record> (entries.length);
        foreach (var entry in entries) {
            rows.add (entry.record);
        }
        return rows;
    }

    private GenericArray<Record>? filter_rows (
        GenericArray<Record>? sorted, string?[] filters
    ) {
        bool active = false;
        foreach (var value in filters) {
            active = active || value != null;
        }
        if (!active) {
            return null;
        }

        var rows = new GenericArray<Record> ();
        for (int i = 0; i < n_rows; i++) {
            var record = sorted != null ? sorted[i] : records[i + 1];
            if (matches (record, filters)) {
                rows.add (record);
            }
        }
        return rows;
    }

    private static bool matches (Record record, string?[] filters) {
        for (int column = 0; column < filters.length; column++) {
            if (filters[column] != null &&
                cell_at (record, column) != filters[column]) {
                return false;
            }
        }
        return true;
    }

    /**
     * Returns the distinct values of a column in alphabetical order, or null
     * if there are more than ''limit'' of them. Does not touch the model, so
     * it can run in a thread.
     */
    public GenericArray<string>? distinct_values (int column, int limit) {
        var seen = new GenericSet<string> (str_hash, str_equal);
        var values = new GenericArray<string> ();
        for (int i = 1; i < records.length; i++) {
            unowned string cell = cell_at (records[i], column);
            if (!seen.contains (cell)) {
                if (values.length >= limit) {
                    return null;
                }
                seen.add (cell);
                values.add (cell);
            }
        }

        values.sort_with_data ((a, b) => a.collate (b));
        return values;
    }

    private static unowned string cell_at (Record record, int column) {
        return column < record.cells.length ? record.cells[column] : "";
    }

    private static bool is_number (string cell) {
        double number;
        return cell == "" || (
            double.try_parse (cell, out number) && number.is_finite ()
        );
    }
}

/**
 * A record with the sort key of one column, computed once so the comparisons
 * do not have to collate or parse strings again. Empty cells sort first.
 */
private class Reto.SortEntry {
    public Record record;
    private string key = "";
    private double number = -double.MAX;
    private bool numeric;

    public SortEntry (Record record, string cell, bool numeric) {
        this.record = record;
        this.numeric = numeric;
        if (!numeric) {
            key = cell.collate_key ();
        } else if (cell != "") {
            number = double.parse (cell);
        }
    }

    public int compare (SortEntry other) {
        if (numeric) {
            return number < other.number ? -1 : (number > other.number ? 1 : 0);
        }
        return strcmp (key, other.key);
    }
}

/**
 * Which rows a {@link RowModel} shows: in what order and through which
 * filters. Built by {@link RowModel.build_view} and not changed afterwards,
 * so it can be handed between threads.
 */
public class Reto.RowView {
    public int column = -1;
    public bool descending = false;
    public string?[] filters = {};
    // Rows in sorted order, or null for file order.
    public GenericArray<Record>? sorted = null;
    // The rows that pass the filters, or null if no filter is active.
    public GenericArray<Record>? filtered = null;
}
