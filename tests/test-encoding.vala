// Czech text "Příliš žluťoučký kůň" in the legacy encodings, as bytes.
const uint8[] CP1250 = {
    0x50, 0xF8, 0xED, 0x6C, 0x69, 0x9A, 0x20, 0x9E, 0x6C, 0x75, 0x9D,
    0x6F, 0x75, 0xE8, 0x6B, 0xFD, 0x20, 0x6B, 0xF9, 0xF2,
};
const uint8[] LATIN2 = {
    0x50, 0xF8, 0xED, 0x6C, 0x69, 0xB9, 0x20, 0xBE, 0x6C, 0x75, 0xBB,
    0x6F, 0x75, 0xE8, 0x6B, 0xFD, 0x20, 0x6B, 0xF9, 0xF2,
};
const string CZECH = "Příliš žluťoučký kůň";

string decode (uint8[] data, string encoding) throws Error {
    var bytes = Reto.Encodings.decode (data, encoding);
    // Bytes are not NUL-terminated.
    var text = new StringBuilder ();
    text.append_len ((string) bytes.get_data (), bytes.length);
    return text.str;
}

// The decoded text, or the failure reported as the test failure.
string decoded (uint8[] data, string encoding) {
    try {
        return decode (data, encoding);
    } catch (Error e) {
        Test.fail_printf ("%s: %s", encoding, e.message);
        return "";
    }
}

void assert_detected (uint8[] data, string expected) {
    assert_cmpstr (
        Reto.Encodings.detect (data), CompareOperator.EQ, expected
    );
}

void test_detect_empty_is_utf8 () {
    assert_detected (new uint8[0], "UTF-8");
}

void test_detect_ascii_is_utf8 () {
    assert_detected ("a,b\n1,2\n".data, "UTF-8");
}

void test_detect_valid_utf8 () {
    assert_detected (CZECH.data, "UTF-8");
}

void test_detect_utf8_bom () {
    assert_detected ({ 0xEF, 0xBB, 0xBF, 'a', ',', 'b' }, "UTF-8");
}

void test_detect_utf16_boms () {
    assert_detected ({ 0xFF, 0xFE, 'a', 0 }, "UTF-16LE");
    assert_detected ({ 0xFE, 0xFF, 0, 'a' }, "UTF-16BE");
}

void test_detect_utf32_bom_wins_over_utf16 () {
    assert_detected ({ 0xFF, 0xFE, 0, 0, 'a', 0, 0, 0 }, "UTF-32LE");
    assert_detected ({ 0, 0, 0xFE, 0xFF, 0, 0, 0, 'a' }, "UTF-32BE");
}

void test_detect_invalid_utf8_falls_back () {
    assert_detected (CP1250, Reto.Encodings.FALLBACK);
    assert_detected (LATIN2, Reto.Encodings.FALLBACK);
}

void test_detect_truncated_utf8_falls_back () {
    // A multi-byte sequence cut at the very end is not valid UTF-8.
    assert_detected ({ 'a', 0xC5 }, Reto.Encodings.FALLBACK);
}

void test_fallback_is_windows_1250 () {
    assert_cmpstr (
        Reto.Encodings.FALLBACK, CompareOperator.EQ, "WINDOWS-1250"
    );
}

void test_decode_windows_1250 () {
    assert_cmpstr (decoded (CP1250, "WINDOWS-1250"), CompareOperator.EQ, CZECH);
}

void test_decode_iso_8859_2 () {
    assert_cmpstr (decoded (LATIN2, "ISO-8859-2"), CompareOperator.EQ, CZECH);
}

void test_decode_utf8_passes_through () {
    assert_cmpstr (decoded (CZECH.data, "UTF-8"), CompareOperator.EQ, CZECH);
}

void test_decode_strips_utf8_bom () {
    uint8[] data = { 0xEF, 0xBB, 0xBF, 'a' };
    assert_cmpstr (decoded (data, "UTF-8"), CompareOperator.EQ, "a");
}

void test_decode_strips_utf16_bom () {
    uint8[] data = { 0xFF, 0xFE, 'a', 0, 'b', 0 };
    assert_cmpstr (decoded (data, "UTF-16LE"), CompareOperator.EQ, "ab");
}

void test_decode_utf8_keeps_everything_but_the_bom () {
    uint8[] data = { 0xEF, 0xBB, 0xBF, 'a', 0xC5, 0xBE, '\n' };
    assert_cmpstr (decoded (data, "UTF-8"), CompareOperator.EQ, "až\n");
}

void test_decode_utf16_with_bom () {
    uint8[] data = { 0xFE, 0xFF, 0, 'a', 0, 'b' };
    assert_cmpstr (decoded (data, "UTF-16"), CompareOperator.EQ, "ab");
}

void test_decode_invalid_utf8_is_an_error () {
    try {
        decode (CP1250, "UTF-8");
        assert_not_reached ();
    } catch (Error e) {
        assert_true (e is ConvertError);
    }
}

void test_decode_undefined_byte_is_an_error () {
    // 0x81 is not assigned in Windows-1250.
    try {
        decode ({ 'a', 0x81, 'b' }, "WINDOWS-1250");
        assert_not_reached ();
    } catch (Error e) {
        assert_true (e is ConvertError);
    }
}

void test_decode_undefined_byte_in_other_code_pages_is_an_error () {
    // 0x81 is not assigned in Windows-874, the Windows iconv maps it to U+0081.
    foreach (var encoding in new string[] { "CP874", "WINDOWS-1252" }) {
        try {
            decode ({ 'a', 0x81, 'b' }, encoding);
            assert_not_reached ();
        } catch (Error e) {
            assert_true (e is ConvertError);
        }
    }
}

void test_decode_unknown_encoding_is_an_error () {
    try {
        decode ("a".data, "NO-SUCH-ENCODING");
        assert_not_reached ();
    } catch (Error e) {
        assert_true (e is ConvertError);
    }
}

void test_decode_empty () {
    assert_cmpstr (decoded (new uint8[0], "WINDOWS-1250"),
        CompareOperator.EQ, "");
}

// Every offered encoding must be known to iconv on this system, otherwise
// the menu would offer a choice that can only fail.
void test_all_choices_are_supported () {
    foreach (var choice in Reto.Encodings.choices ()) {
        try {
            Reto.Encodings.decode ("a".data, choice.id);
        } catch (Error e) {
            // Wide encodings need whole code units, "a" alone is cut short.
            if (!choice.id.has_prefix ("UTF-16") &&
                !choice.id.has_prefix ("UTF-32")) {
                Test.fail_printf ("%s: %s", choice.id, e.message);
            }
        }
    }
}

// The listed names are checked where the iconv is complete. The one of
// Windows lacks some encodings, which the menu then leaves out.
void test_no_choice_is_left_out () {
#if WINDOWS
    Test.skip ("The iconv of Windows lacks some encodings");
#else
    assert_cmpint (Reto.Encodings.choices ().length, CompareOperator.EQ,
        Reto.Encodings.all_choices ().length);
#endif
}

void test_choices_have_unique_ids () {
    var seen = new GenericSet<string> (str_hash, str_equal);
    foreach (var choice in Reto.Encodings.all_choices ()) {
        assert_true (seen.add (choice.id));
    }
}

void test_choices_cover_the_fallback () {
    bool found = false;
    foreach (var choice in Reto.Encodings.choices ()) {
        found = found || choice.id == Reto.Encodings.FALLBACK;
    }
    assert_true (found);
}

void test_label_of () {
    assert_cmpstr (Reto.Encodings.label_of ("WINDOWS-1250"),
        CompareOperator.EQ, "Windows-1250");
    // An unlisted encoding is shown by its own name.
    assert_cmpstr (Reto.Encodings.label_of ("X-UNLISTED"),
        CompareOperator.EQ, "X-UNLISTED");
}

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/encoding/detect-empty", test_detect_empty_is_utf8);
    Test.add_func ("/encoding/detect-ascii", test_detect_ascii_is_utf8);
    Test.add_func ("/encoding/detect-utf8", test_detect_valid_utf8);
    Test.add_func ("/encoding/detect-utf8-bom", test_detect_utf8_bom);
    Test.add_func ("/encoding/detect-utf16-bom", test_detect_utf16_boms);
    Test.add_func ("/encoding/detect-utf32-bom",
        test_detect_utf32_bom_wins_over_utf16);
    Test.add_func ("/encoding/detect-fallback",
        test_detect_invalid_utf8_falls_back);
    Test.add_func ("/encoding/detect-truncated",
        test_detect_truncated_utf8_falls_back);
    Test.add_func ("/encoding/fallback", test_fallback_is_windows_1250);
    Test.add_func ("/encoding/decode-1250", test_decode_windows_1250);
    Test.add_func ("/encoding/decode-latin2", test_decode_iso_8859_2);
    Test.add_func ("/encoding/decode-utf8", test_decode_utf8_passes_through);
    Test.add_func ("/encoding/decode-utf8-bom", test_decode_strips_utf8_bom);
    Test.add_func ("/encoding/decode-utf16-bom",
        test_decode_strips_utf16_bom);
    Test.add_func ("/encoding/decode-utf8-content",
        test_decode_utf8_keeps_everything_but_the_bom);
    Test.add_func ("/encoding/decode-utf16", test_decode_utf16_with_bom);
    Test.add_func ("/encoding/decode-invalid-utf8",
        test_decode_invalid_utf8_is_an_error);
    Test.add_func ("/encoding/decode-undefined-byte",
        test_decode_undefined_byte_is_an_error);
    Test.add_func ("/encoding/decode-undefined-byte-code-pages",
        test_decode_undefined_byte_in_other_code_pages_is_an_error);
    Test.add_func ("/encoding/decode-unknown",
        test_decode_unknown_encoding_is_an_error);
    Test.add_func ("/encoding/decode-empty", test_decode_empty);
    Test.add_func ("/encoding/choices-supported",
        test_all_choices_are_supported);
    Test.add_func ("/encoding/choices-complete", test_no_choice_is_left_out);
    Test.add_func ("/encoding/choices-unique", test_choices_have_unique_ids);
    Test.add_func ("/encoding/choices-fallback",
        test_choices_cover_the_fallback);
    Test.add_func ("/encoding/label-of", test_label_of);
    Test.run ();
}
