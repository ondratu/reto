namespace Reto.CsvParser {
    private const string DELIMITERS = ",;\t|";

    /**
     * Guesses the delimiter from the first record: the most frequent
     * candidate outside quotes wins, a comma if there is none.
     */
    public char detect_delimiter (uint8[] data) {
        var counts = new int[DELIMITERS.length];
        bool quoted = false;
        for (int i = 0; i < data.length && (quoted || data[i] != '\n'); i++) {
            if (data[i] == '"') {
                quoted = !quoted;
            } else if (!quoted) {
                int pos = DELIMITERS.index_of_char (data[i]);
                if (pos >= 0) {
                    counts[pos]++;
                }
            }
        }

        int best = 0;
        for (int i = 1; i < counts.length; i++) {
            if (counts[i] > counts[best]) {
                best = i;
            }
        }
        return counts[best] > 0 ? (char) DELIMITERS[best] : ',';
    }

    /**
     * Parses RFC 4180 style CSV data (UTF-8) into records of fields.
     *
     * Blank lines are skipped and a leading byte order mark is ignored.
     * Without an explicit delimiter it is detected from the first record.
     */
    public GenericArray<Record> parse (uint8[] data, char delimiter = '\0') {
        if (delimiter == '\0') {
            delimiter = detect_delimiter (data);
        }

        var records = new GenericArray<Record> ();
        string[] fields = {};
        var field = new StringBuilder ();
        bool quoted = false;
        bool started = false;
        int len = data.length;
        bool bom = len >= 3 && data[0] == 0xEF && data[1] == 0xBB
            && data[2] == 0xBF;

        for (int i = bom ? 3 : 0; i < len; i++) {
            char c = (char) data[i];
            if (quoted) {
                if (c != '"') {
                    field.append_c (c);
                } else if (i + 1 < len && data[i + 1] == '"') {
                    field.append_c ('"');
                    i++;
                } else {
                    quoted = false;
                }
            } else if (c == '"' && field.len == 0) {
                quoted = true;
                started = true;
            } else if (c == delimiter) {
                fields += take_field (field);
                started = true;
            } else if (c == '\n') {
                if (started || field.len > 0) {
                    fields += take_field (field);
                    records.add (new Record (fields));
                    fields = {};
                    started = false;
                }
            } else if (c != '\r') {
                field.append_c (c);
            }
        }

        if (started || field.len > 0) {
            fields += take_field (field);
            records.add (new Record (fields));
        }
        return records;
    }

    private string take_field (StringBuilder field) {
        var text = field.str.make_valid ();
        field.truncate (0);
        return text;
    }
}
