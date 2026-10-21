public class Reto.Row : Object {
    public string[] cells { get; construct; }

    public Row (string[] cells) {
        Object (cells: cells);
    }
}

/**
 * Plain record as parsed, without the GObject overhead of a Row.
 */
public class Reto.Record {
    public string[] cells;

    public Record (string[] cells) {
        this.cells = cells;
    }
}
