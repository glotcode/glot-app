import glot_frontend/public/editor/code_editor/document
import glot_frontend/public/editor/code_editor/text
import gleam/list
import gleam/string

pub fn fast_segmentation_preserves_ascii_crlf_and_unicode_clusters_test() {
  list.each(["", "abcXYZ0123 =;\t\n", "a\r\nb\rc\n", "\r\n\r\n",
    "ascii e\u{0301} tail", "abc 👨‍👩‍👧‍👦 🇳🇴", "a\r\n界\u{0301}"], fn(source) {
    let expected = string.to_graphemes(source)
      |> list.map(fn(cluster) { text.Cluster(cluster, text.width(cluster)) })
    assert text.clusters(source) == expected
  })
}

pub fn utf16_width_counts_code_units_test() {
  assert text.width("abc") == 3
  // A non-BMP emoji is a surrogate pair.
  assert text.width("😀") == 2
  // A combining sequence is two code points but one cluster.
  assert text.width("e\u{0301}") == 2
  assert text.cluster_count("e\u{0301}") == 1
  // Tabs are a single unit.
  assert text.width("\ta") == 2
}

pub fn slicing_never_splits_a_cluster_test() {
  assert text.slice("a😀b", 0, 1) == "a"
  // Offset 2 is inside the surrogate pair, so the whole emoji is taken.
  assert text.slice("a😀b", 1, 2) == "😀"
  assert text.slice("a😀b", 1, 3) == "😀"
  assert text.drop("a😀b", 3) == "b"
}

pub fn shared_cluster_slices_preserve_boundaries_and_clamping_test() {
  let source = "a😀e\u{0301}\r\nz"
  let clusters = text.clusters(source)
  assert text.slice_clusters(clusters, -5, 100) == source
  assert text.slice_clusters(clusters, 2, 4) == "😀e\u{0301}"
  assert text.slice_clusters(clusters, 6, 7) == "\r\n"
  assert text.slice_clusters(clusters, 4, 4) == ""
  assert text.slice_clusters(clusters, 100, 200) == ""
  assert text.drop(source, -1) == source
  assert text.drop(source, 0) == source
  assert text.drop(source, 2) == "😀e\u{0301}\r\nz"
}

pub fn whole_line_slices_keep_unicode_and_separators_test() {
  let doc = document.from_string("a😀\ne\u{0301}\n")
  assert document.slice(doc, 0, 3) == "a😀"
  assert document.slice(doc, 4, 6) == "e\u{0301}"
  assert document.slice(doc, -1, 100) == "a😀\ne\u{0301}\n"
  assert document.slice(doc, 2, 3) == "😀"
}

pub fn cluster_boundaries_move_around_whole_characters_test() {
  assert text.next_boundary("a😀b", 1) == 3
  assert text.prev_boundary("a😀b", 3) == 1
  assert text.cluster_index("a😀b", 3) == 2
  assert text.offset_of_cluster("a😀b", 2) == 3
}

pub fn document_offsets_count_one_unit_per_line_break_test() {
  let doc = document.from_string("ab\ncd\n")
  assert document.line_count(doc) == 3
  assert document.length(doc) == 6
  assert document.line_start(doc, 1) == 3
  assert document.line_end(doc, 1) == 5
  assert document.position_at(doc, 4) == document.Position(line: 1, column: 1)
  assert document.offset_at(doc, document.Position(line: 2, column: 0)) == 6
}

pub fn document_offsets_are_utf16_across_lines_test() {
  let doc = document.from_string("😀\nx")
  assert document.length(doc) == 4
  assert document.line_start(doc, 1) == 3
  assert document.slice(doc, 0, 2) == "😀"
  assert document.slice(doc, 0, 4) == "😀\nx"
}

pub fn replace_rebuilds_the_line_index_test() {
  let doc = document.from_string("one\ntwo\nthree")
  let updated = document.replace(doc, 4, 7, "2")
  assert document.to_string(updated) == "one\n2\nthree"
  assert document.line_count(updated) == 3
  assert document.length(updated) == 11

  let split = document.replace(doc, 3, 3, "\nmid")
  assert document.line_count(split) == 4
  assert document.line_text(split, 1) == "mid"
}

pub fn replace_normalizes_pasted_line_endings_test() {
  let doc = document.from_string("a")
  let updated = document.replace(doc, 1, 1, "\r\nb\rc")
  assert document.to_string(updated) == "a\nb\nc"
  assert document.line_count(updated) == 3
}

pub fn bidirectional_text_keeps_logical_offsets_test() {
  let doc = document.from_string("abc \u{05D0}\u{05D1}\u{05D2} def")
  assert document.length(doc) == 11
  assert document.slice(doc, 4, 7) == "\u{05D0}\u{05D1}\u{05D2}"
}

pub fn lines_in_range_returns_indexed_viewport_lines_test() {
  let doc = document.from_string("a\nb\nc\nd")
  assert document.lines_in_range(doc, 1, 3)
    == [
      #(1, document.Line(text: "b", width: 1)),
      #(2, document.Line(text: "c", width: 1)),
    ]
}
