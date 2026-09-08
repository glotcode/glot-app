//// Selection ranges.
////
//// A range is an anchor and a head, both document UTF-16 offsets. A selection
//// is a non-empty list of ranges plus the index of the primary one; more than
//// one range appears only for rectangular selection and for the Emacs
//// rectangular region, which are the two multi-range features Glot actually
//// exposed.

import gleam/int
import gleam/list

pub type Range {
  Range(anchor: Int, head: Int)
}

pub type Selection {
  Selection(ranges: List(Range), primary: Int, rectangular: Bool)
}

pub fn cursor(offset: Int) -> Range {
  Range(anchor: offset, head: offset)
}

pub fn range(anchor: Int, head: Int) -> Range {
  Range(anchor: anchor, head: head)
}

pub fn from(offset: Int) -> Selection {
  single(cursor(offset))
}

pub fn single(item: Range) -> Selection {
  Selection(ranges: [item], primary: 0, rectangular: False)
}

pub fn many(ranges: List(Range), rectangular: Bool) -> Selection {
  case ranges {
    [] -> from(0)
    [_, ..] ->
      Selection(
        ranges: ranges,
        primary: list.length(ranges) - 1,
        rectangular: rectangular,
      )
  }
}

pub fn main(selection: Selection) -> Range {
  case list.drop(selection.ranges, selection.primary) {
    [found, ..] -> found
    [] ->
      case selection.ranges {
        [first, ..] -> first
        [] -> cursor(0)
      }
  }
}

pub fn head(selection: Selection) -> Int {
  main(selection).head
}

pub fn anchor(selection: Selection) -> Int {
  main(selection).anchor
}

pub fn start(item: Range) -> Int {
  case item.anchor < item.head {
    True -> item.anchor
    False -> item.head
  }
}

pub fn end(item: Range) -> Int {
  case item.anchor > item.head {
    True -> item.anchor
    False -> item.head
  }
}

pub fn is_empty(item: Range) -> Bool {
  item.anchor == item.head
}

pub fn is_collapsed(selection: Selection) -> Bool {
  list.all(selection.ranges, is_empty)
}

/// The span covered by every range, used when an operation needs one region.
pub fn span(selection: Selection) -> Range {
  let starts = list.map(selection.ranges, start)
  let ends = list.map(selection.ranges, end)
  Range(
    anchor: list.fold(starts, min_or(starts), int_min),
    head: list.fold(ends, max_or(ends), int_max),
  )
}

fn min_or(values: List(Int)) -> Int {
  case values {
    [first, ..] -> first
    [] -> 0
  }
}

fn max_or(values: List(Int)) -> Int {
  case values {
    [first, ..] -> first
    [] -> 0
  }
}

fn int_min(a: Int, b: Int) -> Int {
  case a < b {
    True -> a
    False -> b
  }
}

fn int_max(a: Int, b: Int) -> Int {
  case a > b {
    True -> a
    False -> b
  }
}

/// Sort ranges by their start offset and drop ranges that fully overlap,
/// keeping the selection canonical after an edit maps offsets together.
pub fn normalize(selection: Selection) -> Selection {
  let sorted =
    selection.ranges
    |> list.sort(fn(left, right) {
      case start(left) == start(right) {
        True -> int.compare(end(left), end(right))
        False -> int.compare(start(left), start(right))
      }
    })

  case merge_overlapping(sorted, []) {
    [] -> from(0)
    ranges ->
      Selection(
        ranges: ranges,
        primary: document_clamp(
          selection.primary,
          0,
          list.length(ranges) - 1,
        ),
        rectangular: selection.rectangular,
      )
  }
}

fn merge_overlapping(
  remaining: List(Range),
  collected: List(Range),
) -> List(Range) {
  case remaining, collected {
    [], _ -> list.reverse(collected)
    [current, ..rest], [previous, ..earlier] ->
      case start(current) <= end(previous) && end(current) >= start(previous) {
        True ->
          merge_overlapping(rest, [
            Range(
              anchor: int_min(start(previous), start(current)),
              head: int_max(end(previous), end(current)),
            ),
            ..earlier
          ])
        False -> merge_overlapping(rest, [current, ..collected])
      }
    [current, ..rest], [] -> merge_overlapping(rest, [current])
  }
}

fn document_clamp(value: Int, low: Int, high: Int) -> Int {
  case value < low {
    True -> low
    False ->
      case value > high {
        True -> high
        False -> value
      }
  }
}

pub fn map_offsets(selection: Selection, transform: fn(Int) -> Int) -> Selection {
  Selection(
    ..selection,
    ranges: list.map(selection.ranges, fn(item) {
      Range(anchor: transform(item.anchor), head: transform(item.head))
    }),
  )
}
