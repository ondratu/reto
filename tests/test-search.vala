Reto.RowModel make_model (string text) {
    return new Reto.RowModel (Reto.CsvParser.parse (text.data));
}

string positions (Reto.SearchResult result) {
    string[] parts = {};
    for (int i = 0; i < result.count; i++) {
        parts += result.position_at (i).to_string ();
    }
    return string.joinv (",", parts);
}

void assert_found (string query, string text, int start, int end) {
    int s;
    int e;
    assert_true (new Reto.Matcher (query).find (text, out s, out e));
    assert_cmpint (s, CompareOperator.EQ, start);
    assert_cmpint (e, CompareOperator.EQ, end);
}

void test_find () {
    assert_found ("lo", "Hello", 3, 5);
    assert_found ("h", "Hello", 0, 1);
    assert_found ("Hello", "hello", 0, 5);
}

void test_find_ignores_case () {
    assert_found ("ČESKY", "Je to česky", 6, 12);
}

void test_find_offsets_are_bytes () {
    assert_found ("b", "čb", 2, 3);
}

void test_find_no_match () {
    var matcher = new Reto.Matcher ("xyz");
    assert_false (matcher.matches ("abc"));
    assert_false (matcher.matches ("xy"));
    assert_false (matcher.matches (""));
}

void test_find_partial_start () {
    assert_found ("aab", "aaab", 1, 4);
}

void test_empty_query () {
    var matcher = new Reto.Matcher ("");
    assert_true (matcher.is_empty);
    assert_false (matcher.matches ("abc"));
}

void test_first_column () {
    var matcher = new Reto.Matcher ("b");
    string[] cells = { "a", "xB", "b" };
    assert_cmpint (matcher.first_column (cells, 10), CompareOperator.EQ, 1);
    assert_cmpint (matcher.first_column (cells, 1), CompareOperator.EQ, -1);
    string[] none = { "a" };
    assert_cmpint (matcher.first_column (none, 10), CompareOperator.EQ, -1);
}

void test_find_rows () {
    var model = make_model ("k,v\nfoo,1\nbar,Foo\nbaz,2\n");
    var result = model.find_rows ("foo", model.view, 10);
    assert_cmpuint (result.count, CompareOperator.EQ, 2);
    assert_cmpstr (positions (result), CompareOperator.EQ, "0,1");
}

void test_find_rows_empty_query () {
    var model = make_model ("k\nfoo\n");
    assert_cmpuint (
        model.find_rows ("", model.view, 10).count, CompareOperator.EQ, 0
    );
}

void test_find_rows_short_rows () {
    var model = make_model ("a,b\nx\ny,z\n");
    var result = model.find_rows ("z", model.view, 10);
    assert_cmpstr (positions (result), CompareOperator.EQ, "1");
}

void test_find_rows_column_limit () {
    var model = make_model ("a,b\nx,q\n");
    assert_cmpuint (
        model.find_rows ("q", model.view, 1).count, CompareOperator.EQ, 0
    );
    assert_cmpuint (
        model.find_rows ("q", model.view, 2).count, CompareOperator.EQ, 1
    );
}

void test_find_rows_follows_view () {
    var model = make_model ("k\nb\na\nb\n");
    model.set_order (0, false);
    // Sorted: a, b, b.
    assert_cmpstr (
        positions (model.find_rows ("b", model.view, 10)),
        CompareOperator.EQ, "1,2"
    );
    model.set_filter (0, "b");
    assert_cmpstr (
        positions (model.find_rows ("b", model.view, 10)),
        CompareOperator.EQ, "0,1"
    );
    assert_cmpuint (
        model.find_rows ("a", model.view, 10).count, CompareOperator.EQ, 0
    );
}

void test_step () {
    var model = make_model ("k\na\nb\na\na\n");
    var result = model.find_rows ("a", model.view, 10);
    assert_cmpint (result.step (-1, 1), CompareOperator.EQ, 0);
    assert_cmpint (result.step (-1, -1), CompareOperator.EQ, 2);
    assert_cmpint (result.step (0, 1), CompareOperator.EQ, 1);
    assert_cmpint (result.step (2, 1), CompareOperator.EQ, 0);
    assert_cmpint (result.step (0, -1), CompareOperator.EQ, 2);
}

void test_step_no_matches () {
    var model = make_model ("k\na\n");
    var result = model.find_rows ("x", model.view, 10);
    assert_cmpint (result.step (-1, 1), CompareOperator.EQ, -1);
    assert_cmpint (result.step (0, -1), CompareOperator.EQ, -1);
}

void test_describe () {
    var matcher = new Reto.Matcher ("lo");
    var h = matcher.describe ("Hello", false);
    assert_true (h.found);
    assert_false (h.current);
    assert_cmpint (h.start, CompareOperator.EQ, 3);
    assert_cmpint (h.end, CompareOperator.EQ, 5);
    assert_true (matcher.describe ("Hello", true).current);
}

void test_describe_no_match () {
    var h = new Reto.Matcher ("x").describe ("Hello", true);
    assert_false (h.found);
    assert_false (h.current);
}

void test_find_rows_anchor () {
    var model = make_model ("k,v\nb,1\nb,2\n");
    var first = model.get_record (0);
    var result = model.find_rows ("b", model.view, 10, first);
    assert_cmpint (result.anchor_index, CompareOperator.EQ, 0);

    model.set_order (1, true);
    // The record moved to second place but is still a match.
    result = model.find_rows ("b", model.view, 10, first);
    assert_cmpint (result.anchor_index, CompareOperator.EQ, 1);
}

void test_find_rows_anchor_gone () {
    var model = make_model ("k\nb\na\n");
    var a = model.get_record (1);
    assert_cmpint (
        model.find_rows ("b", model.view, 10, a).anchor_index,
        CompareOperator.EQ, -1
    );
    assert_cmpint (
        model.find_rows ("b", model.view, 10).anchor_index,
        CompareOperator.EQ, -1
    );
}

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/search/find", test_find);
    Test.add_func ("/search/ignores-case", test_find_ignores_case);
    Test.add_func ("/search/byte-offsets", test_find_offsets_are_bytes);
    Test.add_func ("/search/no-match", test_find_no_match);
    Test.add_func ("/search/partial-start", test_find_partial_start);
    Test.add_func ("/search/empty-query", test_empty_query);
    Test.add_func ("/search/first-column", test_first_column);
    Test.add_func ("/search/rows", test_find_rows);
    Test.add_func ("/search/rows-empty-query", test_find_rows_empty_query);
    Test.add_func ("/search/rows-short", test_find_rows_short_rows);
    Test.add_func ("/search/rows-column-limit", test_find_rows_column_limit);
    Test.add_func ("/search/rows-follow-view", test_find_rows_follows_view);
    Test.add_func ("/search/step", test_step);
    Test.add_func ("/search/step-no-matches", test_step_no_matches);
    Test.add_func ("/search/describe", test_describe);
    Test.add_func ("/search/describe-no-match", test_describe_no_match);
    Test.add_func ("/search/rows-anchor", test_find_rows_anchor);
    Test.add_func ("/search/rows-anchor-gone", test_find_rows_anchor_gone);
    Test.run ();
}
