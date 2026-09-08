import gleam/option
import glot_frontend/public/editor/code_editor/document
import glot_frontend/public/editor/code_editor/keys
import glot_frontend/public/editor/code_editor/message
import glot_frontend/public/editor/code_editor/search
import support/code_editor_driver as driver

fn query(term: String) -> search.Query {
  search.Query(..search.empty_query(), search: term)
}

pub fn literal_matches_are_found_across_lines_test() {
  let doc = document.from_string("one two\nthree two\ntwo")

  assert search.matches(doc, query("two")) == [#(4, 7), #(14, 17), #(18, 21)]
  assert search.count(doc, query("two")) == 3
}

pub fn search_is_case_insensitive_unless_asked_test() {
  let doc = document.from_string("Value value VALUE")

  assert search.count(doc, query("value")) == 3
  assert search.count(
      doc,
      search.Query(..query("value"), case_sensitive: True),
    )
    == 1
}

pub fn whole_word_search_ignores_partial_matches_test() {
  let doc = document.from_string("in inside inn in")
  let whole = search.Query(..query("in"), whole_word: True)

  assert search.matches(doc, whole) == [#(0, 2), #(14, 16)]
}

pub fn regular_expressions_report_utf16_offsets_test() {
  let doc = document.from_string("a1 b22 c333")
  let pattern = search.Query(..query("[0-9]+"), regexp: True)

  assert search.matches(doc, pattern) == [#(1, 2), #(4, 6), #(8, 11)]
}

pub fn an_invalid_regular_expression_matches_nothing_test() {
  let doc = document.from_string("abc")
  assert search.matches(doc, search.Query(..query("("), regexp: True)) == []
}

pub fn find_next_wraps_around_the_document_test() {
  let doc = document.from_string("x y x")

  assert search.find_next(doc, query("x"), 1) == option.Some(#(4, 5))
  assert search.find_next(doc, query("x"), 5) == option.Some(#(0, 1))
  assert search.find_previous(doc, query("x"), 0) == option.Some(#(4, 5))
}

pub fn matches_can_be_limited_to_the_rendered_viewport_test() {
  let doc = document.from_string("a\na\na\na")

  assert search.matches_in_lines(doc, query("a"), 1, 3) == [#(2, 3), #(4, 5)]
}

pub fn the_panel_finds_and_replaces_test() {
  let editing =
    driver.new("alpha beta alpha")
    |> driver.send(message.SearchFieldChanged(message.SearchTerm, "alpha"))
    |> driver.send(
      message.SearchFieldChanged(message.ReplacementTerm, "gamma"),
    )
    |> driver.send(message.SearchReplaceClicked(True))

  assert driver.text_of(editing) == "gamma beta gamma"
}

pub fn replacing_one_match_leaves_the_others_test() {
  let editing =
    driver.new("alpha beta alpha")
    |> driver.send(message.SearchFieldChanged(message.SearchTerm, "alpha"))
    |> driver.send(
      message.SearchFieldChanged(message.ReplacementTerm, "gamma"),
    )
    |> driver.send(message.SearchReplaceClicked(False))

  assert driver.text_of(editing) == "gamma beta alpha"
}

pub fn opening_the_search_panel_seeds_it_from_the_selection_test() {
  let editing =
    driver.new("needle haystack")
    |> driver.select(0, 6)
    |> driver.press(keys.ctrl("f"))

  assert editing.model.search.open
  assert editing.model.search.query.search == "needle"
}


pub fn bulk_replace_preserves_selection_mapping_and_undo_across_unicode_lines_test() {
  let original = "🦊 value\nvalue é\nvalue"
  let editing = driver.new(original) |> driver.select(9, 9)
    |> driver.send(message.SearchFieldChanged(message.SearchTerm, "value"))
    |> driver.send(message.SearchFieldChanged(message.ReplacementTerm, "x\ny"))
    |> driver.send(message.SearchReplaceClicked(True))
  assert driver.text_of(editing) == "🦊 x\ny\nx\ny é\nx\ny"
  assert driver.caret(editing) == 7
  let restored = editing |> driver.press(keys.ctrl("z"))
  assert driver.text_of(restored) == original
  assert restored |> driver.press(keys.Key(..keys.ctrl("z"), shift: True)) |> driver.text_of == "🦊 x\ny\nx\ny é\nx\ny"
}
