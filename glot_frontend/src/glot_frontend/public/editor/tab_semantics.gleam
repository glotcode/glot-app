import gleam/int
import gleam/list
import gleam/option.{type Option}
import glot_frontend/public/editor/model.{type EditorTab, FileTab, StdinTab}

pub const panel_id = "editor-source-panel"

pub fn available_tabs(
  file_count: Int,
  stdin: Option(String),
) -> List(EditorTab) {
  let file_tabs = indexed_file_tabs(file_count, 0)
  case stdin {
    option.Some(_) -> list.append(file_tabs, [StdinTab])
    option.None -> file_tabs
  }
}

pub fn tab_id(tab: EditorTab) -> String {
  case tab {
    FileTab(index) -> "editor-file-tab-" <> int.to_string(index)
    StdinTab -> "editor-stdin-tab"
  }
}

pub fn keyboard_destination(
  tabs: List(EditorTab),
  current: EditorTab,
  key: String,
) -> Option(EditorTab) {
  case key {
    "Home" -> first_tab(tabs)
    "End" -> last_tab(tabs)
    "ArrowRight" | "ArrowDown" -> next_tab(tabs, current)
    "ArrowLeft" | "ArrowUp" -> previous_tab(tabs, current)
    _ -> option.None
  }
}

fn indexed_file_tabs(count: Int, index: Int) -> List(EditorTab) {
  case index >= count {
    True -> []
    False -> [FileTab(index), ..indexed_file_tabs(count, index + 1)]
  }
}

fn next_tab(tabs: List(EditorTab), current: EditorTab) -> Option(EditorTab) {
  case tabs {
    [] -> option.None
    [first, ..] -> find_next(tabs, current, first)
  }
}

fn find_next(
  tabs: List(EditorTab),
  current: EditorTab,
  first: EditorTab,
) -> Option(EditorTab) {
  case tabs {
    [] -> option.Some(first)
    [tab] if tab == current -> option.Some(first)
    [tab, next, ..] if tab == current -> option.Some(next)
    [_, ..rest] -> find_next(rest, current, first)
  }
}

fn previous_tab(
  tabs: List(EditorTab),
  current: EditorTab,
) -> Option(EditorTab) {
  case last_tab(tabs) {
    option.None -> option.None
    option.Some(last) -> find_previous(tabs, current, last)
  }
}

fn first_tab(tabs: List(EditorTab)) -> Option(EditorTab) {
  case tabs {
    [] -> option.None
    [first, ..] -> option.Some(first)
  }
}

fn last_tab(tabs: List(EditorTab)) -> Option(EditorTab) {
  case tabs {
    [] -> option.None
    [last] -> option.Some(last)
    [_, ..rest] -> last_tab(rest)
  }
}

fn find_previous(
  tabs: List(EditorTab),
  current: EditorTab,
  previous: EditorTab,
) -> Option(EditorTab) {
  case tabs {
    [] -> option.Some(previous)
    [tab, ..] if tab == current -> option.Some(previous)
    [tab, ..rest] -> find_previous(rest, current, tab)
  }
}
