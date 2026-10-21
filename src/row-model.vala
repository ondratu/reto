/**
 * Read-only list of parsed records. The first record is the header, the rest
 * are rows. Rows are created on demand, so a large file costs one string
 * array per record rather than one object.
 */
public class Reto.RowModel : Object, ListModel {
    private GenericArray<Record> records;

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
        return new Row (records[position + 1].cells);
    }
}
