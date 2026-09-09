//// Reconciles a native textarea edit into a transaction.
////
//// The browser is allowed to edit the textarea directly — that is what keeps
//// IME composition, dictation, autocorrect, mobile keyboards, and drag-and-drop
//// working. Afterwards the new value is diffed against the document and the
//// difference becomes one transaction, so history and selection mapping stay
//// under Gleam's control.
////
//// The diff is line-oriented, then refined inside a single changed line, which
//// keeps it linear in the number of lines rather than in characters.

import gleam/list
import gleam/option.{type Option}
import gleam/string
import glot_frontend/public/editor/code_editor/document.{type Document}
import glot_frontend/public/editor/code_editor/text
import glot_frontend/public/editor/code_editor/transaction.{type Change}

pub fn diff(doc: Document, next: String) -> Option(Change) {
  let old_lines = list.map(doc.lines, fn(item) { item.text })
  let new_lines =
    next
    |> string.replace("\r\n", "\n")
    |> string.replace("\r", "\n")
    |> string.split("\n")

  case old_lines == new_lines {
    True -> option.None
    False -> {
      let old_count = list.length(old_lines)
      let new_count = list.length(new_lines)
      let prefix = common_prefix(old_lines, new_lines, 0)
      let limit = int_min(old_count, new_count) - prefix
      let suffix =
        common_suffix(
          list.reverse(old_lines),
          list.reverse(new_lines),
          0,
          limit,
        )
      let changed_old = old_count - suffix
      let inserted =
        new_lines
        |> list.drop(prefix)
        |> list.take(new_count - suffix - prefix)

      option.Some(refine(doc, case changed_old < old_count, inserted, prefix {
        // Lines survive after the change, so the region ends at the start of
        // the first surviving line and the replacement keeps its separator.
        True, [], _ ->
          transaction.Change(
            from: document.line_start(doc, prefix),
            to: document.line_start(doc, changed_old),
            insert: "",
          )
        True, _, _ ->
          transaction.Change(
            from: document.line_start(doc, prefix),
            to: document.line_start(doc, changed_old),
            insert: string.join(inserted, "\n") <> "\n",
          )

        // The change runs to the end of the document. Deleting the last lines
        // must take the separator that preceded them.
        False, [], 0 ->
          transaction.Change(from: 0, to: document.length(doc), insert: "")
        False, [], _ ->
          transaction.Change(
            from: document.line_end(doc, prefix - 1),
            to: document.length(doc),
            insert: "",
          )

        // Appending past the last line adds the separator in front.
        False, _, _ ->
          case prefix < old_count {
            True ->
              transaction.Change(
                from: document.line_start(doc, prefix),
                to: document.length(doc),
                insert: string.join(inserted, "\n"),
              )
            False ->
              transaction.Change(
                from: document.length(doc),
                to: document.length(doc),
                insert: "\n" <> string.join(inserted, "\n"),
              )
          }
      }))
    }
  }
}

/// Narrow the changed lines to the characters that actually changed, so
/// typing one character records one small change and groups cleanly in history.
fn refine(doc: Document, change: Change) -> Change {
  let removed = document.slice(doc, change.from, change.to)
  let old_clusters = text.clusters(removed)
  let new_clusters = text.clusters(change.insert)
  let old_width = change.to - change.from
  let new_width = list.fold(new_clusters, 0, fn(total, cluster) { total + cluster.width })
  let prefix = common_text_prefix(old_clusters, new_clusters, 0)
  let suffix =
    common_text_suffix(
      list.reverse(old_clusters),
      list.reverse(new_clusters),
      0,
      int_min(old_width, new_width) - prefix,
    )
  transaction.Change(
    from: change.from + prefix,
    to: change.to - suffix,
    insert: text.slice_clusters(
      new_clusters,
      prefix,
      new_width - suffix,
    ),
  )
}

fn common_prefix(left: List(String), right: List(String), count: Int) -> Int {
  case left, right {
    [a, ..rest_left], [b, ..rest_right] if a == b ->
      common_prefix(rest_left, rest_right, count + 1)
    _, _ -> count
  }
}

fn common_suffix(
  left: List(String),
  right: List(String),
  count: Int,
  limit: Int,
) -> Int {
  case count >= limit {
    True -> count
    False ->
      case left, right {
        [a, ..rest_left], [b, ..rest_right] if a == b ->
          common_suffix(rest_left, rest_right, count + 1, limit)
        _, _ -> count
      }
  }
}

// Segment once: repeatedly slicing/segmenting the unchanged suffix makes a
// one-character insertion at the beginning of a long line quadratic.
fn common_text_prefix(left: List(text.Cluster), right: List(text.Cluster), count: Int) -> Int {
  case left, right {
    [a, ..rest_left], [b, ..rest_right] if a.text == b.text ->
      common_text_prefix(rest_left, rest_right, count + a.width)
    _, _ -> count
  }
}

fn common_text_suffix(
  left: List(text.Cluster),
  right: List(text.Cluster),
  count: Int,
  limit: Int,
) -> Int {
  case left, right {
    [a, ..rest_left], [b, ..rest_right] if a.text == b.text && count + a.width <= limit ->
      common_text_suffix(rest_left, rest_right, count + a.width, limit)
    _, _ -> count
  }
}

fn int_min(a: Int, b: Int) -> Int {
  case a < b {
    True -> a
    False -> b
  }
}
