Reto.RowModel make_model (string text) {
    return new Reto.RowModel (Reto.CsvParser.parse (text.data));
}

// Runs a request the way the window does, minus the thread.
Reto.SearchResult run (Reto.SearchRequest request) {
    return request.model.find_rows (request.query, request.view, 10,
                                    request.anchor);
}

Reto.SearchState search_for (
    Reto.RowModel model, string text, bool jump = true
) {
    var state = new Reto.SearchState ();
    var request = state.begin (model, text, jump);
    assert_true (state.finish (request, run (request), model, jump));
    return state;
}

void test_initial () {
    var state = new Reto.SearchState ();
    assert_null (state.result);
    assert_false (state.has_matches);
    assert_cmpint (state.current, CompareOperator.EQ, -1);
    assert_cmpint (state.row, CompareOperator.EQ, -1);
    assert_false (state.is_stale (""));
    assert_true (state.is_stale ("a"));
}

void test_nothing_to_look_for () {
    var model = make_model ("k\na\n");
    var state = new Reto.SearchState ();
    assert_null (state.begin (model, "", true));
    assert_null (state.begin (null, "a", true));
}

void test_empty_query_resets () {
    var model = make_model ("k\na\n");
    var state = search_for (model, "a");
    assert_true (state.has_matches);
    assert_null (state.begin (model, "", true));
    assert_null (state.result);
    assert_cmpint (state.current, CompareOperator.EQ, -1);
    assert_true (state.is_stale ("a"));
}

void test_jump_to_first () {
    var model = make_model ("k\nb\na\nab\n");
    var state = search_for (model, "a");
    assert_cmpuint (state.result.count, CompareOperator.EQ, 2);
    assert_cmpint (state.current, CompareOperator.EQ, 0);
    assert_false (state.is_stale ("a"));
    state.locate (model, 10);
    assert_cmpint (state.row, CompareOperator.EQ, 1);
    assert_cmpint (state.column, CompareOperator.EQ, 0);
}

void test_locate_column () {
    var model = make_model ("x,y\n1,2\n3,needle\n");
    var state = search_for (model, "needle");
    state.locate (model, 10);
    assert_cmpint (state.row, CompareOperator.EQ, 1);
    assert_cmpint (state.column, CompareOperator.EQ, 1);
    // The match is out of reach of the column limit.
    state.locate (model, 1);
    assert_cmpint (state.column, CompareOperator.EQ, -1);
}

void test_no_matches () {
    var model = make_model ("k\na\n");
    var state = search_for (model, "z");
    assert_false (state.has_matches);
    assert_cmpint (state.current, CompareOperator.EQ, -1);
    state.step (1);
    assert_cmpint (state.current, CompareOperator.EQ, -1);
    state.locate (model, 10);
    assert_cmpint (state.row, CompareOperator.EQ, -1);
}

void test_step_wraps () {
    var model = make_model ("k\na\nb\na\n");
    var state = search_for (model, "a");
    assert_cmpint (state.current, CompareOperator.EQ, 0);
    state.step (1);
    assert_cmpint (state.current, CompareOperator.EQ, 1);
    state.step (1);
    assert_cmpint (state.current, CompareOperator.EQ, 0);
    state.step (-1);
    assert_cmpint (state.current, CompareOperator.EQ, 1);
}

void test_newer_search_wins () {
    var model = make_model ("k\na\nb\n");
    var state = new Reto.SearchState ();
    var old = state.begin (model, "a", true);
    var recent = state.begin (model, "b", true);
    assert_false (state.finish (old, run (old), model, true));
    assert_null (state.result);
    assert_true (state.finish (recent, run (recent), model, true));
    assert_cmpstr (state.query, CompareOperator.EQ, "b");
}

void test_reset_drops_running_search () {
    var model = make_model ("k\na\n");
    var state = new Reto.SearchState ();
    var request = state.begin (model, "a", true);
    state.reset ();
    assert_false (state.finish (request, run (request), model, true));
    assert_null (state.result);
}

void test_missing_result_is_dropped () {
    var model = make_model ("k\na\n");
    var state = new Reto.SearchState ();
    var request = state.begin (model, "a", true);
    assert_false (state.finish (request, null, model, true));
    assert_null (state.result);
}

void test_other_file_drops_result () {
    var model = make_model ("k\na\n");
    var state = new Reto.SearchState ();
    var request = state.begin (model, "a", true);
    var other = make_model ("k\na\n");
    assert_false (state.finish (request, run (request), other, true));
    assert_false (state.finish (request, run (request), null, true));
    assert_null (state.result);
}

void test_stays_on_record_when_rows_move () {
    var model = make_model ("k\na1\nb\na2\na3\n");
    var state = search_for (model, "a");
    state.step (1);
    state.step (1);
    state.locate (model, 10);
    // On a3, the last of three matches.
    assert_cmpint (state.current, CompareOperator.EQ, 2);
    assert_cmpint (state.row, CompareOperator.EQ, 3);

    state.remember_anchor (model);
    model.set_order (0, true);
    var request = state.begin (model, "a", false);
    assert_true (state.finish (request, run (request), model, false));
    state.locate (model, 10);
    // Sorted backwards: b, a3, a2, a1.
    assert_cmpint (state.current, CompareOperator.EQ, 0);
    assert_cmpint (state.row, CompareOperator.EQ, 1);
}

void test_jump_forgets_record () {
    var model = make_model ("k\na1\nb\na2\n");
    var state = search_for (model, "a");
    state.step (1);
    state.locate (model, 10);
    state.remember_anchor (model);
    model.set_order (0, true);
    var request = state.begin (model, "a", true);
    assert_null (request.anchor);
    assert_true (state.finish (request, run (request), model, true));
    assert_cmpint (state.current, CompareOperator.EQ, 0);
}

void test_anchor_filtered_out () {
    var model = make_model ("k,v\na,1\nb,1\na,2\n");
    var state = search_for (model, "a");
    state.step (1);
    state.locate (model, 10);
    state.remember_anchor (model);
    model.set_filter (1, "1");
    var request = state.begin (model, "a", false);
    assert_true (state.finish (request, run (request), model, false));
    // The record is gone, so the search is on no match.
    assert_cmpint (state.current, CompareOperator.EQ, -1);
    assert_cmpuint (state.result.count, CompareOperator.EQ, 1);
}

void test_anchor_ignored_for_other_rows () {
    var model = make_model ("k\na\nb\n");
    var state = search_for (model, "a");
    state.locate (model, 10);
    // The model shows other rows than the search was made for.
    model.set_order (0, true);
    state.remember_anchor (model);
    var request = state.begin (model, "a", false);
    assert_null (request.anchor);
}

void main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/search-state/initial", test_initial);
    Test.add_func ("/search-state/nothing", test_nothing_to_look_for);
    Test.add_func ("/search-state/empty-query", test_empty_query_resets);
    Test.add_func ("/search-state/jump", test_jump_to_first);
    Test.add_func ("/search-state/locate", test_locate_column);
    Test.add_func ("/search-state/no-matches", test_no_matches);
    Test.add_func ("/search-state/step", test_step_wraps);
    Test.add_func ("/search-state/newer", test_newer_search_wins);
    Test.add_func ("/search-state/reset", test_reset_drops_running_search);
    Test.add_func ("/search-state/missing", test_missing_result_is_dropped);
    Test.add_func ("/search-state/other-file", test_other_file_drops_result);
    Test.add_func ("/search-state/stay", test_stays_on_record_when_rows_move);
    Test.add_func ("/search-state/jump-forgets", test_jump_forgets_record);
    Test.add_func ("/search-state/filtered", test_anchor_filtered_out);
    Test.add_func (
        "/search-state/other-rows", test_anchor_ignored_for_other_rows
    );
    Test.run ();
}
