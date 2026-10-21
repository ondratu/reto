Reto.RowModel make_model (string text) {
    return new Reto.RowModel (Reto.CsvParser.parse (text.data));
}

void test_empty () {
    var model = make_model ("");
    assert_cmpuint (model.get_n_items (), CompareOperator.EQ, 0);
    assert_cmpint (model.n_columns, CompareOperator.EQ, 0);
    assert_null (model.get_item (0));
}

void test_item_type () {
    assert_true (make_model ("a\n").get_item_type () == typeof (Reto.Row));
}

void test_items () {
    var model = make_model ("a,b\n1,2\n3,4\n");
    assert_cmpuint (model.get_n_items (), CompareOperator.EQ, 2);

    var row = (Reto.Row) model.get_item (0);
    assert_cmpstr (row.cells[0], CompareOperator.EQ, "1");
    assert_cmpstr (row.cells[1], CompareOperator.EQ, "2");
}

void test_out_of_range () {
    var model = make_model ("a\n1\n");
    assert_null (model.get_item (1));
}

void test_header () {
    var model = make_model ("name,age\nAnn,30\n");
    assert_cmpint (model.header.length, CompareOperator.EQ, 2);
    assert_cmpstr (model.get_column_title (0), CompareOperator.EQ, "name");
    assert_cmpstr (model.get_column_title (1), CompareOperator.EQ, "age");
}

void test_header_only () {
    var model = make_model ("name,age\n");
    assert_cmpuint (model.get_n_items (), CompareOperator.EQ, 0);
    assert_cmpint (model.n_columns, CompareOperator.EQ, 2);
    assert_null (model.get_item (0));
}

void test_title_fallback () {
    var model = make_model ("a,,c\n1,2,3,4\n");
    assert_cmpstr (model.get_column_title (1), CompareOperator.EQ, "2");
    assert_cmpstr (model.get_column_title (3), CompareOperator.EQ, "4");
}

void test_n_columns_is_widest_row () {
    var model = make_model ("a\nb,c,d\ne,f\n");
    assert_cmpint (model.n_columns, CompareOperator.EQ, 3);
}

void test_list_model_interface () {
    ListModel model = make_model ("h\na\nb\n");
    assert_cmpuint (model.get_n_items (), CompareOperator.EQ, 2);
    assert_true (model.get_item (0) is Reto.Row);
}

string[] column_values (Reto.RowModel model, int column) {
    string[] values = {};
    for (uint i = 0; i < model.get_n_items (); i++) {
        var row = (Reto.Row) model.get_item (i);
        values += row.cells[column];
    }
    return values;
}

void assert_column (Reto.RowModel model, string expected) {
    assert_cmpstr (
        string.joinv (",", column_values (model, 0)),
        CompareOperator.EQ, expected
    );
}

void test_sort_text () {
    var model = make_model ("h\nb\nc\na\n");
    model.set_sorted (model.sort_by (0, false));
    assert_column (model, "a,b,c");
    model.set_sorted (model.sort_by (0, true));
    assert_column (model, "c,b,a");
}

void test_sort_numeric () {
    var model = make_model ("h\n10\n9\n\"\"\n-2.5\n");
    model.set_sorted (model.sort_by (0, false));
    assert_column (model, ",-2.5,9,10");
    model.set_sorted (model.sort_by (0, true));
    assert_column (model, "10,9,-2.5,");
}

void test_sort_nan_and_inf_as_text () {
    var model = make_model ("h\nnan\n10\ninf\n9\n");
    model.set_sorted (model.sort_by (0, false));
    assert_column (model, "10,9,inf,nan");
}

void test_sort_is_stable () {
    var model = make_model ("k,v\n1,a\n0,b\n1,c\n0,d\n");
    model.set_sorted (model.sort_by (0, false));
    assert_cmpstr (
        string.joinv (",", column_values (model, 1)),
        CompareOperator.EQ, "b,d,a,c"
    );
}

void test_sort_short_rows () {
    var model = make_model ("a,b\n1\n2,x\n");
    model.set_sorted (model.sort_by (1, true));
    assert_column (model, "2,1");
}

void test_clear_sort () {
    var model = make_model ("h\nb\na\n");
    model.set_sorted (model.sort_by (0, false));
    model.set_sorted (null);
    assert_column (model, "b,a");
}

void test_set_sorted_signal () {
    var model = make_model ("h\nb\na\n");
    uint removed = 0;
    uint added = 0;
    model.items_changed.connect ((position, r, a) => {
        removed = r;
        added = a;
    });
    model.set_sorted (model.sort_by (0, false));
    assert_cmpuint (removed, CompareOperator.EQ, 2);
    assert_cmpuint (added, CompareOperator.EQ, 2);
}

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/row-model/empty", test_empty);
    Test.add_func ("/row-model/item-type", test_item_type);
    Test.add_func ("/row-model/items", test_items);
    Test.add_func ("/row-model/out-of-range", test_out_of_range);
    Test.add_func ("/row-model/header", test_header);
    Test.add_func ("/row-model/header-only", test_header_only);
    Test.add_func ("/row-model/title-fallback", test_title_fallback);
    Test.add_func ("/row-model/n-columns", test_n_columns_is_widest_row);
    Test.add_func (
        "/row-model/list-model-interface", test_list_model_interface
    );
    Test.add_func ("/row-model/sort-text", test_sort_text);
    Test.add_func ("/row-model/sort-numeric", test_sort_numeric);
    Test.add_func ("/row-model/sort-nan-inf", test_sort_nan_and_inf_as_text);
    Test.add_func ("/row-model/sort-stable", test_sort_is_stable);
    Test.add_func ("/row-model/sort-short-rows", test_sort_short_rows);
    Test.add_func ("/row-model/clear-sort", test_clear_sort);
    Test.add_func ("/row-model/sorted-signal", test_set_sorted_signal);
    Test.run ();
}
