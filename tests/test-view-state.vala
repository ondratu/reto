Reto.RowModel make_model (string text) {
    return new Reto.RowModel (Reto.CsvParser.parse (text.data));
}

Reto.SearchResult make_result (uint matches) {
    var result = new Reto.SearchResult (new Reto.Matcher ("x"));
    for (uint i = 0; i < matches; i++) {
        result.add (i);
    }
    return result;
}

void assert_text (string actual, string expected) {
    assert_cmpstr (actual, CompareOperator.EQ, expected);
}

void test_shown_columns () {
    var model = make_model ("a,b,c\n1,2,3\n");
    assert_cmpint (
        Reto.ViewState.shown_columns (model, 500), CompareOperator.EQ, 3
    );
    assert_cmpint (
        Reto.ViewState.shown_columns (model, 2), CompareOperator.EQ, 2
    );
    assert_cmpint (
        Reto.ViewState.shown_columns (model, 3), CompareOperator.EQ, 3
    );
}

void test_status () {
    var model = make_model ("k,v\na,1\nb,2\nc,3\n");
    assert_text (
        Reto.ViewState.describe_status (model, 500), "3 of 3 rows"
    );
}

void test_status_filters () {
    var model = make_model ("k,v\na,1\nb,2\na,3\n");
    model.show_view (model.build_view (-1, false, { "a" }, model.view));
    assert_text (
        Reto.ViewState.describe_status (model, 500), "2 of 3 rows  ·  k: a"
    );
}

void test_status_empty_value () {
    var model = make_model ("k,\na,\nb,x\n");
    model.show_view (model.build_view (-1, false, { null, "" }, model.view));
    assert_text (
        Reto.ViewState.describe_status (model, 500),
        "1 of 2 rows  ·  2: (empty)"
    );
}

void test_status_column_limit () {
    var model = make_model ("k,v\na,1\nb,2\n");
    model.show_view (model.build_view (-1, false, { null, "1" }, model.view));
    assert_text (
        Reto.ViewState.describe_status (model, 1), "1 of 2 rows"
    );
}

void test_describe_search () {
    assert_text (
        Reto.ViewState.describe_search ("", null, -1), ""
    );
    assert_text (
        Reto.ViewState.describe_search ("x", null, -1), ""
    );
    assert_text (
        Reto.ViewState.describe_search ("", make_result (2), -1), ""
    );
    assert_text (
        Reto.ViewState.describe_search ("x", make_result (0), -1), "No results"
    );
    assert_text (
        Reto.ViewState.describe_search ("x", make_result (1), -1), "1 match"
    );
    assert_text (
        Reto.ViewState.describe_search ("x", make_result (3), -1), "3 matches"
    );
    assert_text (
        Reto.ViewState.describe_search ("x", make_result (3), 1), "2 of 3"
    );
}

void test_search_failed () {
    assert_true (Reto.ViewState.search_failed ("x", make_result (0)));
    assert_false (Reto.ViewState.search_failed ("x", make_result (1)));
    assert_false (Reto.ViewState.search_failed ("x", null));
    assert_false (Reto.ViewState.search_failed ("", make_result (0)));
}

void test_filter_round_trip () {
    assert_text (
        Reto.ViewState.encode_filter (null), ""
    );
    assert_null (Reto.ViewState.decode_filter (""));
    // An empty value is a filter, not "every value".
    assert_text (
        Reto.ViewState.encode_filter (""), "v"
    );
    assert_text (
        Reto.ViewState.decode_filter ("v"), ""
    );
    foreach (var value in new string[] { "a", "v", "č ě", "a_b" }) {
        assert_text (
            Reto.ViewState.decode_filter (
                Reto.ViewState.encode_filter (value)
            ), value
        );
    }
}

void test_filter_label () {
    assert_text (
        Reto.ViewState.filter_label (""), "(empty)"
    );
    assert_text (
        Reto.ViewState.filter_label ("abc"), "abc"
    );
    assert_text (
        Reto.ViewState.filter_label ("a_b_"), "a__b__"
    );
}

void test_can_reset () {
    assert_false (Reto.ViewState.can_reset (-1, {}));
    assert_false (Reto.ViewState.can_reset (-1, { null, null }));
    assert_true (Reto.ViewState.can_reset (0, {}));
    assert_true (Reto.ViewState.can_reset (-1, { null, "" }));
}

void test_cursor_target () {
    assert_cmpint (Reto.ViewState.cursor_target (5), CompareOperator.EQ, 5);
    assert_cmpint (Reto.ViewState.cursor_target (0), CompareOperator.EQ, 0);
    assert_cmpint (Reto.ViewState.cursor_target (-1), CompareOperator.EQ, 0);
}

void test_can_move_cursor () {
    assert_true (Reto.ViewState.can_move_cursor (0, 1));
    assert_true (Reto.ViewState.can_move_cursor (2, 3));
    assert_false (Reto.ViewState.can_move_cursor (0, 0));
    assert_false (Reto.ViewState.can_move_cursor (3, 3));
    assert_false (Reto.ViewState.can_move_cursor (-1, 3));
}

void test_generation () {
    var generation = new Reto.Generation ();
    var first = generation.next ();
    assert_true (generation.is_current (first));
    var second = generation.next ();
    assert_false (generation.is_current (first));
    assert_true (generation.is_current (second));
    generation.invalidate ();
    assert_false (generation.is_current (second));
}

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/view-state/shown-columns", test_shown_columns);
    Test.add_func ("/view-state/status", test_status);
    Test.add_func ("/view-state/status-filters", test_status_filters);
    Test.add_func ("/view-state/status-empty-value",
        test_status_empty_value);
    Test.add_func ("/view-state/status-column-limit",
        test_status_column_limit);
    Test.add_func ("/view-state/search-text", test_describe_search);
    Test.add_func ("/view-state/search-failed", test_search_failed);
    Test.add_func ("/view-state/filter-round-trip", test_filter_round_trip);
    Test.add_func ("/view-state/filter-label", test_filter_label);
    Test.add_func ("/view-state/can-reset", test_can_reset);
    Test.add_func ("/view-state/cursor-target", test_cursor_target);
    Test.add_func ("/view-state/can-move-cursor", test_can_move_cursor);
    Test.add_func ("/view-state/generation", test_generation);
    Test.run ();
}
