/**
 * Read-only list of parsed records. The first record is the header, the rest
 * are rows. Rows are created on demand, so a large file costs one string
 * array per record rather than one object.
 */
public class Reto.RowModel : Object, ListModel {
    private GenericArray<Record> records;
    private GenericArray<Record>? sorted = null;

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

    public Type get_item_type () {
        return typeof (Row);
    }

    public uint get_n_items () {
        return records.length > 0 ? records.length - 1 : 0;
    }

    public Object? get_item (uint position) {
        if (position >= get_n_items ()) {
            return null;
        }
        var record = sorted != null ? sorted[position] : records[position + 1];
        return new Row (record.cells);
    }

    /**
     * Returns the rows ordered by a column. Does not touch the model, so it
     * can run in a thread; hand the result to {@link set_sorted}. Columns
     * where every non-empty cell is a number sort numerically, the others
     * alphabetically. The sort is stable.
     */
    public GenericArray<Record> sort_by (int column, bool descending) {
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

    /**
     * Shows the rows in the order given by {@link sort_by}, or in file order
     * if null.
     */
    public void set_sorted (GenericArray<Record>? sorted) {
        this.sorted = sorted;
        uint n = get_n_items ();
        items_changed (0, n, n);
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
