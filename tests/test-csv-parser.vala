// Serializes records as "a|b/c|d" to keep the expectations short.
string dump (GenericArray<Reto.Record> records) {
    string[] lines = {};
    foreach (var record in records) {
        lines += string.joinv ("|", record.cells);
    }
    return string.joinv ("/", lines);
}

void assert_parsed (string text, string expected, char delimiter = '\0') {
    var records = Reto.CsvParser.parse (text.data, delimiter);
    assert_cmpstr (dump (records), CompareOperator.EQ, expected);
}

void assert_delimiter (string text, char expected) {
    assert_true (Reto.CsvParser.detect_delimiter (text.data) == expected);
}

void test_simple () {
    assert_parsed ("a,b,c\n1,2,3\n", "a|b|c/1|2|3");
}

void test_empty () {
    var records = Reto.CsvParser.parse (new uint8[0]);
    assert_cmpuint (records.length, CompareOperator.EQ, 0);
    assert_parsed ("\n\n", "");
}

void test_no_trailing_newline () {
    assert_parsed ("a,b\n1,2", "a|b/1|2");
}

void test_crlf () {
    assert_parsed ("a,b\r\n1,2\r\n", "a|b/1|2");
}

void test_blank_lines_skipped () {
    assert_parsed ("a\n\n\nb\n", "a/b");
}

void test_empty_fields () {
    assert_parsed ("a,,c\n,\n", "a||c/|");
    assert_parsed ("a,b,", "a|b|");
}

void test_empty_quoted_field () {
    var records = Reto.CsvParser.parse ("\"\"\n".data);
    assert_cmpuint (records.length, CompareOperator.EQ, 1);
    assert_cmpuint (records[0].cells.length, CompareOperator.EQ, 1);
    assert_cmpstr (records[0].cells[0], CompareOperator.EQ, "");
}

void test_quoted_delimiter () {
    assert_parsed ("\"Doe, J\",x\n", "Doe, J|x");
}

void test_quoted_newline () {
    var records = Reto.CsvParser.parse ("\"a\nb\",c\nd,e\n".data);
    assert_cmpuint (records.length, CompareOperator.EQ, 2);
    assert_cmpstr (records[0].cells[0], CompareOperator.EQ, "a\nb");
}

void test_escaped_quote () {
    assert_parsed ("\"say \"\"hi\"\"\",x\n", "say \"hi\"|x");
}

void test_quote_inside_unquoted_field () {
    assert_parsed ("a\"b,c\n", "a\"b|c");
}

void test_unterminated_quote () {
    assert_parsed ("\"abc,def\n", "abc,def\n");
}

void test_bom_skipped () {
    assert_parsed ("﻿a,b\n", "a|b");
}

void test_ragged_rows () {
    var records = Reto.CsvParser.parse ("a,b,c\n1\n".data);
    assert_cmpuint (records[0].cells.length, CompareOperator.EQ, 3);
    assert_cmpuint (records[1].cells.length, CompareOperator.EQ, 1);
}

void test_unicode () {
    assert_parsed ("jméno;město\nŽofie;Plzeň\n", "jméno|město/Žofie|Plzeň");
}

void test_invalid_utf8_repaired () {
    uint8[] data = { 'a', 0xFF, 'b', '\n' };
    var records = Reto.CsvParser.parse (data);
    assert_true (records[0].cells[0].validate ());
}

void test_explicit_delimiter () {
    assert_parsed ("a;b,c\n", "a|b,c", ';');
}

void test_detect_delimiter () {
    assert_delimiter ("a,b,c\n", ',');
    assert_delimiter ("a;b;c\n", ';');
    assert_delimiter ("a\tb\tc\n", '\t');
    assert_delimiter ("a|b|c\n", '|');
}

void test_detect_delimiter_defaults_to_comma () {
    assert_delimiter ("", ',');
    assert_delimiter ("single\n", ',');
}

void test_detect_delimiter_ignores_quotes () {
    assert_delimiter ("\"a,b,c\";d;e\n", ';');
}

void test_detect_delimiter_first_line_only () {
    assert_delimiter ("a;b\n1,2,3,4\n", ';');
}

void test_detect_delimiter_tie_prefers_comma () {
    assert_delimiter ("a,b;c\n", ',');
}

void test_parse_detects_delimiter () {
    assert_parsed ("a;b\n1;2\n", "a|b/1|2");
}

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/csv-parser/simple", test_simple);
    Test.add_func ("/csv-parser/empty", test_empty);
    Test.add_func ("/csv-parser/no-trailing-newline", test_no_trailing_newline);
    Test.add_func ("/csv-parser/crlf", test_crlf);
    Test.add_func ("/csv-parser/blank-lines-skipped", test_blank_lines_skipped);
    Test.add_func ("/csv-parser/empty-fields", test_empty_fields);
    Test.add_func ("/csv-parser/empty-quoted-field", test_empty_quoted_field);
    Test.add_func ("/csv-parser/quoted-delimiter", test_quoted_delimiter);
    Test.add_func ("/csv-parser/quoted-newline", test_quoted_newline);
    Test.add_func ("/csv-parser/escaped-quote", test_escaped_quote);
    Test.add_func (
        "/csv-parser/quote-inside-unquoted-field",
        test_quote_inside_unquoted_field
    );
    Test.add_func ("/csv-parser/unterminated-quote", test_unterminated_quote);
    Test.add_func ("/csv-parser/bom-skipped", test_bom_skipped);
    Test.add_func ("/csv-parser/ragged-rows", test_ragged_rows);
    Test.add_func ("/csv-parser/unicode", test_unicode);
    Test.add_func (
        "/csv-parser/invalid-utf8-repaired", test_invalid_utf8_repaired
    );
    Test.add_func ("/csv-parser/explicit-delimiter", test_explicit_delimiter);
    Test.add_func ("/csv-parser/detect-delimiter", test_detect_delimiter);
    Test.add_func (
        "/csv-parser/detect-delimiter-default",
        test_detect_delimiter_defaults_to_comma
    );
    Test.add_func (
        "/csv-parser/detect-delimiter-ignores-quotes",
        test_detect_delimiter_ignores_quotes
    );
    Test.add_func (
        "/csv-parser/detect-delimiter-first-line-only",
        test_detect_delimiter_first_line_only
    );
    Test.add_func (
        "/csv-parser/detect-delimiter-tie",
        test_detect_delimiter_tie_prefers_comma
    );
    Test.add_func (
        "/csv-parser/parse-detects-delimiter", test_parse_detects_delimiter
    );
    Test.run ();
}
