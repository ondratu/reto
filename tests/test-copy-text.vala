Reto.RowModel make_model (string text) {
    return new Reto.RowModel (Reto.CsvParser.parse (text.data));
}

void assert_text (string actual, string expected) {
    assert_cmpstr (actual, CompareOperator.EQ, expected);
}

void test_quote () {
    assert_text (Reto.CopyText.quote ("plain text"), "plain text");
    assert_text (Reto.CopyText.quote (""), "");
    assert_text (Reto.CopyText.quote ("a\tb"), "\"a\tb\"");
    assert_text (Reto.CopyText.quote ("a\nb"), "\"a\nb\"");
    assert_text (Reto.CopyText.quote ("a\rb"), "\"a\rb\"");
    assert_text (Reto.CopyText.quote ("say \"hi\""), "\"say \"\"hi\"\"\"");
}

Reto.Record[] records_of (Reto.RowModel model, uint[] positions) {
    Reto.Record[] records = {};
    foreach (var position in positions) {
        records += model.get_record (position);
    }
    return records;
}

void test_row () {
    var model = make_model ("name,age\nAnn,30\nBob,41\n");
    var records = records_of (model, { 1 });
    assert_text (Reto.CopyText.rows (model, records, 2, false), "Bob\t41");
    assert_text (
        Reto.CopyText.rows (model, records, 2, true),
        "name\tage\nBob\t41"
    );
}

void test_rows () {
    var model = make_model ("name,age\nAnn,30\nBob,41\nCyd,5\n");
    var records = records_of (model, { 2, 0 });
    assert_text (
        Reto.CopyText.rows (model, records, 2, false),
        "Cyd\t5\nAnn\t30"
    );
    assert_text (
        Reto.CopyText.rows (model, records, 2, true),
        "name\tage\nCyd\t5\nAnn\t30"
    );
}

void test_no_rows () {
    var model = make_model ("name,age\nAnn,30\n");
    assert_text (Reto.CopyText.rows (model, {}, 2, false), "");
    assert_text (Reto.CopyText.rows (model, {}, 2, true), "name\tage");
}

void test_row_limits_columns () {
    var model = make_model ("a,b,c\n1,2,3\n");
    var records = records_of (model, { 0 });
    assert_text (Reto.CopyText.rows (model, records, 2, false), "1\t2");
}

void test_row_pads_short_records () {
    var model = make_model ("a,b,c\n1\n");
    var records = records_of (model, { 0 });
    assert_text (Reto.CopyText.rows (model, records, 3, false), "1\t\t");
}

void test_row_quotes () {
    var model = make_model ("a,b\n\"x\ty\",\"1\n2\"\n");
    var records = records_of (model, { 0 });
    assert_text (
        Reto.CopyText.rows (model, records, 2, false), "\"x\ty\"\t\"1\n2\""
    );
}

void test_row_titles_of_empty_header_cells () {
    var model = make_model ("a,\n1,2\n");
    assert_text (
        Reto.CopyText.rows (model, records_of (model, { 0 }), 2, true),
        "a\t2\n1\t2"
    );
}

void test_column () {
    var model = make_model ("k,v\na,1\nb,2\nc,3\n");
    var values = model.column_values (model.view, 1);
    assert_text (Reto.CopyText.column (model, 1, values, false), "1\n2\n3");
    assert_text (Reto.CopyText.column (model, 1, values, true), "v\n1\n2\n3");
}

void test_column_follows_the_view () {
    var model = make_model ("k,v\na,1\nb,2\nc,3\n");
    model.set_order (0, true);
    model.set_filter (1, "3");
    var values = model.column_values (model.view, 0);
    assert_text (Reto.CopyText.column (model, 0, values, false), "c");

    model.set_filter (1, null);
    values = model.column_values (model.view, 0);
    assert_text (Reto.CopyText.column (model, 0, values, true), "k\nc\nb\na");
}

void test_column_without_rows () {
    var model = make_model ("k,v\n");
    var values = model.column_values (model.view, 0);
    assert_text (Reto.CopyText.column (model, 0, values, false), "");
    assert_text (Reto.CopyText.column (model, 0, values, true), "k");
}

void test_column_beyond_the_record () {
    var model = make_model ("k,v\na\n");
    var values = model.column_values (model.view, 1);
    assert_text (Reto.CopyText.column (model, 1, values, false), "");
}

void test_scopes () {
    var model = make_model ("k,v\na,1\n");
    var record = records_of (model, { 0 });
    var cell = Reto.CopyText.Scope.CELL;
    assert_text (
        Reto.CopyText.for_scope (cell, model, record, 2, "x"), "x"
    );
    assert_text (
        Reto.CopyText.for_scope (
            Reto.CopyText.Scope.ROW, model, record, 2, "x"
        ), "a\t1"
    );
    assert_text (
        Reto.CopyText.for_scope (
            Reto.CopyText.Scope.ROW_HEADER, model, record, 2, "x"
        ), "k\tv\na\t1"
    );
    assert_null (Reto.CopyText.for_scope (
        Reto.CopyText.Scope.COLUMN, model, record, 2, "x"
    ));
    assert_null (Reto.CopyText.for_scope ("nonsense", model, record, 2, "x"));
    assert_true (Reto.CopyText.is_column (Reto.CopyText.Scope.COLUMN));
    assert_true (Reto.CopyText.is_column (Reto.CopyText.Scope.COLUMN_HEADER));
    assert_false (Reto.CopyText.is_column (Reto.CopyText.Scope.ROW));
    assert_true (Reto.CopyText.has_header (Reto.CopyText.Scope.COLUMN_HEADER));
    assert_false (Reto.CopyText.has_header (Reto.CopyText.Scope.COLUMN));
}

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/copy-text/quote", test_quote);
    Test.add_func ("/copy-text/row", test_row);
    Test.add_func ("/copy-text/rows", test_rows);
    Test.add_func ("/copy-text/rows-none", test_no_rows);
    Test.add_func ("/copy-text/row-limit", test_row_limits_columns);
    Test.add_func ("/copy-text/row-pad", test_row_pads_short_records);
    Test.add_func ("/copy-text/row-quote", test_row_quotes);
    Test.add_func ("/copy-text/row-titles",
        test_row_titles_of_empty_header_cells);
    Test.add_func ("/copy-text/column", test_column);
    Test.add_func ("/copy-text/column-view", test_column_follows_the_view);
    Test.add_func ("/copy-text/column-empty", test_column_without_rows);
    Test.add_func ("/copy-text/column-short", test_column_beyond_the_record);
    Test.add_func ("/copy-text/scopes", test_scopes);
    Test.run ();
}
