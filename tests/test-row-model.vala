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
    Test.run ();
}
