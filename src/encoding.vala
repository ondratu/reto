namespace Reto.Encodings {
    /** What is assumed when the data is not valid UTF-8. */
    public const string FALLBACK = "WINDOWS-1250";

    /** A character encoding offered in the menu, in a named group. */
    public struct Choice {
        public string group;
        public string id;
        public string label;

        public Choice (string group, string id, string label) {
            this.group = group;
            this.id = id;
            this.label = label;
        }
    }

    // The ids are iconv names, available in the glibc of Linux, which
    // includes the Flatpak runtime. Windows code pages are listed with the
    // ISO and DOS ones used for the same language, as people know them by
    // the language.
    public Choice[] choices () {
        return {
            Choice ("Unicode", "UTF-8", "UTF-8"),
            Choice ("Unicode", "UTF-16", "UTF-16"),
            Choice ("Unicode", "UTF-16LE", "UTF-16LE"),
            Choice ("Unicode", "UTF-16BE", "UTF-16BE"),
            Choice ("Unicode", "UTF-32LE", "UTF-32LE"),
            Choice ("Unicode", "UTF-32BE", "UTF-32BE"),

            Choice ("Western European", "WINDOWS-1252", "Windows-1252"),
            Choice ("Western European", "ISO-8859-1", "ISO-8859-1"),
            Choice ("Western European", "ISO-8859-15", "ISO-8859-15"),
            Choice ("Western European", "MACINTOSH", "Mac Roman"),
            Choice ("Western European", "CP850", "DOS CP850"),
            Choice ("Western European", "CP437", "DOS CP437"),

            Choice ("Central European", "WINDOWS-1250", "Windows-1250"),
            Choice ("Central European", "ISO-8859-2", "ISO-8859-2"),
            Choice ("Central European", "CP852", "DOS CP852"),
            Choice ("Central European", "ISO-8859-16", "ISO-8859-16"),

            Choice ("Northern European", "ISO-8859-10", "ISO-8859-10"),
            Choice ("Northern European", "ISO-8859-14", "ISO-8859-14"),
            Choice ("Northern European", "CP865", "DOS CP865"),

            Choice ("Baltic", "WINDOWS-1257", "Windows-1257"),
            Choice ("Baltic", "ISO-8859-13", "ISO-8859-13"),
            Choice ("Baltic", "ISO-8859-4", "ISO-8859-4"),

            Choice ("Cyrillic", "WINDOWS-1251", "Windows-1251"),
            Choice ("Cyrillic", "KOI8-R", "KOI8-R"),
            Choice ("Cyrillic", "KOI8-U", "KOI8-U"),
            Choice ("Cyrillic", "ISO-8859-5", "ISO-8859-5"),
            Choice ("Cyrillic", "CP866", "DOS CP866"),
            Choice ("Cyrillic", "CP855", "DOS CP855"),

            Choice ("Greek", "WINDOWS-1253", "Windows-1253"),
            Choice ("Greek", "ISO-8859-7", "ISO-8859-7"),

            Choice ("Turkish", "WINDOWS-1254", "Windows-1254"),
            Choice ("Turkish", "ISO-8859-9", "ISO-8859-9"),
            Choice ("Turkish", "CP857", "DOS CP857"),

            Choice ("Hebrew", "WINDOWS-1255", "Windows-1255"),
            Choice ("Hebrew", "ISO-8859-8", "ISO-8859-8"),

            Choice ("Arabic", "WINDOWS-1256", "Windows-1256"),
            Choice ("Arabic", "ISO-8859-6", "ISO-8859-6"),

            Choice ("Vietnamese", "WINDOWS-1258", "Windows-1258"),

            Choice ("Thai", "CP874", "Windows-874"),
            Choice ("Thai", "TIS-620", "TIS-620"),

            Choice ("Japanese", "CP932", "Shift_JIS (Windows-31J)"),
            Choice ("Japanese", "EUC-JP", "EUC-JP"),
            Choice ("Japanese", "ISO-2022-JP", "ISO-2022-JP"),

            Choice ("Simplified Chinese", "GBK", "GBK"),
            Choice ("Simplified Chinese", "GB18030", "GB18030"),
            Choice ("Simplified Chinese", "GB2312", "GB2312"),

            Choice ("Traditional Chinese", "BIG5", "Big5"),
            Choice ("Traditional Chinese", "BIG5-HKSCS", "Big5-HKSCS"),
            Choice ("Traditional Chinese", "EUC-TW", "EUC-TW"),

            Choice ("Korean", "CP949", "UHC (Windows-949)"),
            Choice ("Korean", "EUC-KR", "EUC-KR"),
        };
    }

    /** The menu label of an encoding, or its own name when it is unlisted. */
    public string label_of (string encoding) {
        foreach (var choice in choices ()) {
            if (choice.id == encoding) {
                return choice.label;
            }
        }
        return encoding;
    }

    /**
     * Guesses the encoding of the data: a byte order mark decides, then
     * valid UTF-8 (which plain ASCII is too), otherwise {@link FALLBACK}.
     *
     * A UTF-16LE text that starts with U+0000 looks like a UTF-32LE mark
     * (FF FE 00 00) and is taken for it. The two cannot be told apart.
     *
     * A legacy 8-bit text is rarely valid UTF-8 by chance, but the legacy
     * encodings cannot be told apart by their bytes, hence the manual choice.
     */
    public string detect (uint8[] data) {
        int len = data.length;
        if (len >= 4 && data[0] == 0xFF && data[1] == 0xFE
            && data[2] == 0 && data[3] == 0) {
            return "UTF-32LE";
        }
        if (len >= 4 && data[0] == 0 && data[1] == 0
            && data[2] == 0xFE && data[3] == 0xFF) {
            return "UTF-32BE";
        }
        if (len >= 2 && data[0] == 0xFF && data[1] == 0xFE) {
            return "UTF-16LE";
        }
        if (len >= 2 && data[0] == 0xFE && data[1] == 0xFF) {
            return "UTF-16BE";
        }
        if (len == 0 || ((string) data).validate (len)) {
            return "UTF-8";
        }
        return FALLBACK;
    }

    /**
     * Converts the data from the encoding to UTF-8 without a byte order
     * mark. Bytes that do not belong to the encoding are an error and are
     * not replaced, so a wrong choice is never silently shown as text.
     */
    public Bytes decode (uint8[] data, string encoding) throws ConvertError {
        if (data.length == 0) {
            return new Bytes (new uint8[0]);
        }
        if (encoding.up () == "UTF-8") {
            // Nothing to convert, only to check and to cut the mark off.
            if (!((string) data).validate (data.length)) {
                throw new ConvertError.ILLEGAL_SEQUENCE (
                    "Invalid byte sequence in conversion input"
                );
            }
            bool bom = data.length >= 3 && data[0] == 0xEF
                && data[1] == 0xBB && data[2] == 0xBF;
            return new Bytes (bom ? data[3:data.length] : data);
        }
        size_t written;
        string text = convert (
            (string) data, data.length, "UTF-8", encoding, null, out written
        );
        unowned uint8[] raw = (uint8[]) text;
        raw.length = (int) written;
        // U+FEFF is EF BB BF in UTF-8, whatever the source encoding was.
        bool bom = written >= 3 && raw[0] == 0xEF && raw[1] == 0xBB
            && raw[2] == 0xBF;
        return new Bytes (bom ? raw[3:raw.length] : raw);
    }
}
