/**
 * The text that goes to the clipboard when cells of the table are copied.
 * A single cell is copied as it is. Several cells are copied as tab
 * separated values, which spreadsheets paste into cells: a value with a tab,
 * a line break or a quote is put in quotes.
 */
namespace Reto.CopyText {
    /**
     * What the context menu of the table can copy. The values are the targets
     * of the copy action.
     */
    namespace Scope {
        public const string CELL = "cell";
        public const string ROW = "row";
        public const string ROW_HEADER = "row-header";
        public const string COLUMN = "column";
        public const string COLUMN_HEADER = "column-header";
    }

    /**
     * One value of tab separated text.
     */
    public string quote (string value) {
        if (value.index_of_char ('\t') < 0 && value.index_of_char ('\n') < 0 &&
            value.index_of_char ('\r') < 0 && value.index_of_char ('"') < 0) {
            return value;
        }
        return "\"%s\"".printf (value.replace ("\"", "\"\""));
    }

    /**
     * The first ''n_columns'' cells of a record as a line, followed by the
     * column titles on a line of their own above it if ''with_header''.
     */
    public string row (
        RowModel model, Record record, int n_columns, bool with_header
    ) {
        var cells = new string[n_columns];
        for (int i = 0; i < n_columns; i++) {
            cells[i] = quote (i < record.cells.length ? record.cells[i] : "");
        }
        var line = string.joinv ("\t", cells);
        if (!with_header) {
            return line;
        }
        var titles = new string[n_columns];
        for (int i = 0; i < n_columns; i++) {
            titles[i] = quote (model.get_column_title (i));
        }
        return string.joinv ("\t", titles) + "\n" + line;
    }

    /**
     * The values of a column, one per line, preceded by the title of the
     * column if ''with_header''.
     */
    public string column (
        RowModel model, int column, string[] values, bool with_header
    ) {
        var lines = new string[values.length];
        for (int i = 0; i < values.length; i++) {
            lines[i] = quote (values[i]);
        }
        var text = string.joinv ("\n", lines);
        if (!with_header) {
            return text;
        }
        var title = quote (model.get_column_title (column));
        return values.length > 0 ? title + "\n" + text : title;
    }

    /**
     * Whether a scope copies a column, which has to be collected first.
     */
    public bool is_column (string scope) {
        return scope == Scope.COLUMN || scope == Scope.COLUMN_HEADER;
    }

    /**
     * The text of a scope other than a column: ''cell_text'' for a cell, or
     * the row of ''record''. Null for a column or an unknown scope.
     */
    public string? for_scope (
        string scope, RowModel model, Record record, int n_columns,
        string cell_text
    ) {
        switch (scope) {
        case Scope.CELL:
            return cell_text;
        case Scope.ROW:
            return row (model, record, n_columns, false);
        case Scope.ROW_HEADER:
            return row (model, record, n_columns, true);
        default:
            return null;
        }
    }

    /**
     * Whether a scope includes the titles of the columns.
     */
    public bool has_header (string scope) {
        return scope == Scope.COLUMN_HEADER || scope == Scope.ROW_HEADER;
    }
}
