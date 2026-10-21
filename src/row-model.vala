/**
 * Read-only list of parsed records. Rows are created on demand, so a large
 * file costs one string array per record rather than one object.
 */
public class Reto.RowModel : Object, ListModel {
    private GenericArray<Record> records;

    public int n_columns { get; private set; }

    public RowModel (GenericArray<Record> records) {
        this.records = records;
        foreach (var record in records) {
            n_columns = int.max (n_columns, record.cells.length);
        }
    }

    public Type get_item_type () {
        return typeof (Row);
    }

    public uint get_n_items () {
        return records.length;
    }

    public Object? get_item (uint position) {
        if (position >= records.length) {
            return null;
        }
        return new Row (records[position].cells);
    }
}
