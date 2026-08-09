import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/option
import gleam/order
import gleam/string
import glot_core/language
import glot_core/route
import glot_web/route as web_route
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub const quick_actions_dialog_id = "app-quick-actions-dialog"

pub type Action(msg) {
  Action(
    label: String,
    description: String,
    shortcut: List(String),
    target_route: option.Option(route.Route),
    msg: msg,
  )
}

pub type Section(msg) {
  Section(title: String, actions: List(Action(msg)))
}

pub type ViewModel(msg) {
  ViewModel(
    current_user_label: String,
    account_route: route.Route,
    search_query: String,
    selected_index: Int,
    open_msg: msg,
    close_msg: msg,
    search_changed: fn(String) -> msg,
    keydown: fn(String) -> msg,
    submit_msg: msg,
    sections: List(Section(msg)),
  )
}

pub type NavigationState {
  CanManageAccount
  CanManageAdmin
  NeedsLogin
}

const initial_language_actions = [
  language.Python,
  language.TypeScript,
  language.C,
  language.Rust,
  language.Java,
]

pub fn map_action(action: Action(a), mapper: fn(a) -> b) -> Action(b) {
  case action {
    Action(label:, description:, shortcut:, target_route:, msg:) ->
      Action(label:, description:, shortcut:, target_route:, msg: mapper(msg))
  }
}

pub fn filter_and_rank_sections(
  sections: List(#(Int, Section(msg))),
  query: String,
) -> List(Section(msg)) {
  let normalized_query = query |> string.trim |> string.lowercase
  let sections =
    sections
    |> list.map(fn(section) {
      #(section.0, filter_section_actions(section.1, normalized_query))
    })
    |> list.filter(fn(section) { section_has_actions(section.1) })

  case normalized_query == "" {
    True ->
      sections
      |> list.map(fn(section) { cap_section_actions(section.1, 5) })
    False ->
      sections
      |> list.sort(by: compare_sections(normalized_query))
      |> list.map(fn(section) {
        sort_section_actions(section.1, normalized_query)
        |> cap_section_actions(5)
      })
  }
}

pub fn flattened_actions(sections: List(Section(msg))) -> List(Action(msg)) {
  case sections {
    [] -> []
    [Section(actions:, ..), ..rest] ->
      list.append(actions, flattened_actions(rest))
  }
}

pub fn normalized_selected_index(
  sections: List(Section(msg)),
  selected_index: Int,
) -> Int {
  let count = sections |> flattened_actions |> list.length

  case count <= 0 {
    True -> 0
    False -> int.clamp(selected_index, 0, count - 1)
  }
}

pub fn wrapped_selected_index(
  sections: List(Section(msg)),
  selected_index: Int,
  delta: Int,
) -> Int {
  let count = sections |> flattened_actions |> list.length

  case count <= 0 {
    True -> 0
    False -> {
      let current = normalized_selected_index(sections, selected_index)
      let next = current + delta
      case next < 0 {
        True -> count - 1
        False ->
          case next >= count {
            True -> 0
            False -> next
          }
      }
    }
  }
}

pub fn action_at(
  actions: List(Action(msg)),
  index: Int,
) -> option.Option(Action(msg)) {
  case actions, index {
    [first, ..], 0 -> option.Some(first)
    [_, ..rest], _ if index > 0 -> action_at(rest, index - 1)
    _, _ -> option.None
  }
}

pub fn default_quick_action_sections(
  on_navigate: fn(route.Route) -> msg,
) -> List(Section(msg)) {
  [
    Section(
      title: "Navigation",
      actions: navigation_actions(
        navigation_state: CanManageAccount,
        current_route: route.Public(route.Home),
        query: "",
        on_navigate:,
      ),
    ),
    Section(
      title: "Languages",
      actions: language_actions(query: "", on_navigate:),
    ),
  ]
}

pub fn empty_model() -> ViewModel(Nil) {
  ViewModel(
    current_user_label: "Account",
    account_route: route.Account(route.AccountHome),
    search_query: "",
    selected_index: 0,
    open_msg: Nil,
    close_msg: Nil,
    search_changed: fn(_) { Nil },
    keydown: fn(_) { Nil },
    submit_msg: Nil,
    sections: default_quick_action_sections(fn(_) { Nil }),
  )
}

pub fn navigation_actions(
  navigation_state navigation_state: NavigationState,
  current_route current_route: route.Route,
  query query: String,
  on_navigate on_navigate: fn(route.Route) -> msg,
) -> List(Action(msg)) {
  let shared = [
    Action(
      label: "Home",
      description: "Go to the front page.",
      shortcut: [],
      target_route: option.Some(route.Public(route.Home)),
      msg: on_navigate(route.Public(route.Home)),
    ),
    Action(
      label: "Public snippets",
      description: "Browse public code snippets.",
      shortcut: [],
      target_route: option.Some(
        route.Public(route.Snippets(
          option.None,
          option.None,
          option.None,
          option.None,
        )),
      ),
      msg: on_navigate(
        route.Public(route.Snippets(
          option.None,
          option.None,
          option.None,
          option.None,
        )),
      ),
    ),
    Action(
      label: "Contact",
      description: "Contact us about glot.io.",
      shortcut: [],
      target_route: option.Some(route.Public(route.Contact)),
      msg: on_navigate(route.Public(route.Contact)),
    ),
    Action(
      label: "Privacy",
      description: "Read the privacy policy.",
      shortcut: [],
      target_route: option.Some(route.Public(route.Privacy)),
      msg: on_navigate(route.Public(route.Privacy)),
    ),
  ]

  case navigation_state {
    CanManageAccount ->
      list.append(shared, [
        Action(
          label: "My snippets",
          description: "Manage snippets in your account.",
          shortcut: [],
          target_route: option.Some(
            route.Account(route.AccountSnippets(
              option.None,
              option.None,
              option.None,
            )),
          ),
          msg: on_navigate(
            route.Account(route.AccountSnippets(
              option.None,
              option.None,
              option.None,
            )),
          ),
        ),
        Action(
          label: "Account",
          description: "Open your account settings.",
          shortcut: [],
          target_route: option.Some(route.Account(route.AccountHome)),
          msg: on_navigate(route.Account(route.AccountHome)),
        ),
      ])

    CanManageAdmin ->
      list.append(shared, [
        Action(
          label: "My snippets",
          description: "Manage snippets in your account.",
          shortcut: [],
          target_route: option.Some(
            route.Account(route.AccountSnippets(
              option.None,
              option.None,
              option.None,
            )),
          ),
          msg: on_navigate(
            route.Account(route.AccountSnippets(
              option.None,
              option.None,
              option.None,
            )),
          ),
        ),
        Action(
          label: "Account",
          description: "Open your account settings.",
          shortcut: [],
          target_route: option.Some(route.Account(route.AccountHome)),
          msg: on_navigate(route.Account(route.AccountHome)),
        ),
        Action(
          label: "Admin",
          description: "Open admin tools and configuration.",
          shortcut: [],
          target_route: option.Some(route.Admin(route.AdminHome)),
          msg: on_navigate(route.Admin(route.AdminHome)),
        ),
      ])

    NeedsLogin ->
      case string.trim(query) == "" {
        True ->
          list.append(shared, [
            Action(
              label: "Login",
              description: "Sign in to save and manage snippets.",
              shortcut: [],
              target_route: option.Some(route.Public(route.Login)),
              msg: on_navigate(route.Public(route.Login)),
            ),
          ])
        False ->
          list.append(shared, [
            Action(
              label: "Login",
              description: "Sign in to save and manage snippets.",
              shortcut: [],
              target_route: option.Some(route.Public(route.Login)),
              msg: on_navigate(route.Public(route.Login)),
            ),
            Action(
              label: "Register",
              description: "Create an account or sign in with email.",
              shortcut: [],
              target_route: option.Some(route.Public(route.Login)),
              msg: on_navigate(route.Public(route.Login)),
            ),
          ])
      }
  }
  |> list.filter(fn(action) {
    !is_current_navigation_action(action, current_route)
  })
}

pub fn language_actions(
  query query: String,
  on_navigate on_navigate: fn(route.Route) -> msg,
) -> List(Action(msg)) {
  let normalized_query = query |> string.trim |> string.lowercase

  let languages = case normalized_query == "" {
    True -> initial_language_actions
    False ->
      language.list()
      |> list.filter(fn(lang) {
        let name = language.name(lang) |> string.lowercase
        let slug = language.to_string(lang) |> string.lowercase
        string.contains(name, normalized_query)
        || string.contains(slug, normalized_query)
      })
  }

  list.map(languages, fn(lang) {
    let name = language.name(lang)
    Action(
      label: name,
      description: "Create a new " <> name <> " snippet.",
      shortcut: [],
      target_route: option.Some(
        route.Public(route.NewSnippet(language.to_string(lang))),
      ),
      msg: on_navigate(route.Public(route.NewSnippet(language.to_string(lang)))),
    )
  })
}

pub fn view(model: ViewModel(msg)) -> Element(msg) {
  html.div([], [
    html.nav(
      [
        attribute.class("app-topbar"),
        attribute.attribute("aria-label", "Primary"),
      ],
      [
        html.div([attribute.class("app-topbar__title-group")], [
          html.button(
            [
              attribute.type_("button"),
              attribute.class(
                "app-topbar__icon-button app-topbar__icon-button--menu",
              ),
              attribute.attribute("aria-label", "Open quick actions"),
              event.on_click(model.open_msg),
            ],
            [html.span([attribute.class("app-topbar__menu-icon")], [])],
          ),
          html.a(
            [
              attribute.class("app-topbar__brand"),
              attribute.href("/"),
            ],
            [html.text("glot.io")],
          ),
        ]),
        html.div([attribute.class("app-topbar__account")], [
          html.a(
            [
              attribute.class("app-topbar__account-label"),
              attribute.attribute("aria-label", "Account"),
              web_route.href(model.account_route),
            ],
            [html.text(model.current_user_label)],
          ),
        ]),
      ],
    ),
    quick_actions_dialog(model),
  ])
}

fn quick_actions_dialog(model: ViewModel(msg)) -> Element(msg) {
  html.dialog(
    [
      attribute.id(quick_actions_dialog_id),
      attribute.class("app-dialog app-quick-actions"),
      attribute.attribute("aria-labelledby", "app-quick-actions-title"),
      event.on("close", decode.success(model.close_msg)),
    ],
    [
      html.form(
        [
          attribute.class("app-dialog__form app-quick-actions__form"),
          event.on_submit(fn(_) { model.submit_msg }),
        ],
        [
          html.div([attribute.class("app-dialog__section")], [
            html.div([attribute.class("app-quick-actions__header")], [
              html.h2(
                [
                  attribute.id("app-quick-actions-title"),
                  attribute.class("app-dialog__label"),
                ],
                [html.text("Quick actions")],
              ),
              html.p([attribute.class("app-quick-actions__hint")], [
                html.code([], [html.text("cmd+k")]),
                html.text("|"),
                html.code([], [html.text("ctrl+k")]),
              ]),
              html.button(
                [
                  attribute.type_("button"),
                  attribute.class("app-quick-actions__close"),
                  attribute.attribute("aria-label", "Close quick actions"),
                  event.on_click(model.close_msg),
                ],
                [html.text("Close")],
              ),
            ]),
            html.label(
              [
                attribute.for("app-quick-actions-search"),
                attribute.class("visually-hidden"),
              ],
              [html.text("Search actions and languages")],
            ),
            html.input([
              attribute.id("app-quick-actions-search"),
              attribute.type_("search"),
              attribute.name("quick-actions-search"),
              attribute.class("app-quick-actions__search"),
              attribute.placeholder("Search actions and languages"),
              attribute.autofocus(True),
              attribute.value(model.search_query),
              event.on_input(model.search_changed),
              event.advanced("keydown", {
                use key <- decode.field("key", decode.string)

                let prevent_default = case key {
                  "ArrowDown" | "ArrowUp" | "Enter" -> True
                  _ -> False
                }

                decode.success(event.handler(
                  model.keydown(key),
                  prevent_default: prevent_default,
                  stop_propagation: False,
                ))
              }),
            ]),
          ]),
          case has_any_actions(model) {
            True ->
              html.div(
                [attribute.class("app-quick-actions__sections")],
                render_sections(model.sections, model.selected_index, 0),
              )
            False ->
              html.p(
                [
                  attribute.class("app-quick-actions__empty"),
                  attribute.attribute("role", "status"),
                ],
                [html.text("No matching actions.")],
              )
          },
        ],
      ),
    ],
  )
}

fn render_sections(
  sections: List(Section(msg)),
  selected_index: Int,
  offset: Int,
) -> List(Element(msg)) {
  case sections {
    [] -> []
    [section, ..rest] -> {
      let #(element, next_offset) =
        action_section(section, selected_index, offset)
      [element, ..render_sections(rest, selected_index, next_offset)]
    }
  }
}

fn action_section(
  section: Section(msg),
  selected_index: Int,
  offset: Int,
) -> #(Element(msg), Int) {
  case section {
    Section(title:, actions:) -> #(
      html.div([attribute.class("app-dialog__section")], [
        html.p([attribute.class("app-dialog__label")], [html.text(title)]),
        html.div(
          [attribute.class("app-quick-actions__list")],
          render_action_buttons(actions, selected_index, offset),
        ),
      ]),
      offset + list.length(actions),
    )
  }
}

fn render_action_buttons(
  actions: List(Action(msg)),
  selected_index: Int,
  offset: Int,
) -> List(Element(msg)) {
  case actions {
    [] -> []
    [action, ..rest] -> [
      action_button(action, offset, offset == selected_index),
      ..render_action_buttons(rest, selected_index, offset + 1)
    ]
  }
}

fn action_button(
  action: Action(msg),
  index: Int,
  selected: Bool,
) -> Element(msg) {
  case action {
    Action(label:, description:, shortcut:, msg:, ..) -> {
      let class_name = case selected {
        True -> "app-quick-actions__item app-quick-actions__item--selected"
        False -> "app-quick-actions__item"
      }

      html.button(
        [
          attribute.type_("button"),
          attribute.class(class_name),
          attribute.attribute("data-quick-action-index", int.to_string(index)),
          event.on_click(msg),
        ],
        [
          html.div([attribute.class("app-quick-actions__item-copy")], [
            html.span([attribute.class("app-quick-actions__item-label")], [
              html.text(label),
            ]),
            html.p([attribute.class("app-quick-actions__item-description")], [
              html.text(description),
            ]),
          ]),
          html.div(
            [attribute.class("app-quick-actions__item-shortcut")],
            render_shortcut(shortcut),
          ),
        ],
      )
    }
  }
}

fn has_any_actions(model: ViewModel(msg)) -> Bool {
  case model.sections {
    [] -> False
    _ -> True
  }
}

fn filter_section_actions(
  section: Section(msg),
  query: String,
) -> Section(msg) {
  case section {
    Section(title:, actions:) ->
      Section(
        title:,
        actions: list.filter(actions, fn(action) {
          action_matches(action, query)
        }),
      )
  }
}

fn is_current_navigation_action(
  action: Action(msg),
  current_route: route.Route,
) -> Bool {
  case action {
    Action(target_route:, ..) ->
      case target_route {
        option.Some(target_route) ->
          route.path_and_query(target_route)
          == route.path_and_query(current_route)
        option.None -> False
      }
  }
}

fn action_matches(action: Action(msg), query: String) -> Bool {
  case query == "" {
    True -> True
    False ->
      case action {
        Action(label:, description:, ..) -> {
          let label = label |> string.lowercase
          let description = description |> string.lowercase
          string.contains(label, query) || string.contains(description, query)
        }
      }
  }
}

fn compare_sections(
  query: String,
) -> fn(#(Int, Section(msg)), #(Int, Section(msg))) -> order.Order {
  fn(left: #(Int, Section(msg)), right: #(Int, Section(msg))) {
    let left_score = section_score(left.1, query)
    let right_score = section_score(right.1, query)

    order.break_tie(
      in: int.compare(right_score, left_score),
      with: int.compare(left.0, right.0),
    )
  }
}

fn section_score(section: Section(msg), query: String) -> Int {
  case section {
    Section(actions:, ..) ->
      actions
      |> list.map(fn(action) { action_score(action, query) })
      |> list.fold(0, fn(best, score) {
        case score > best {
          True -> score
          False -> best
        }
      })
  }
}

fn action_score(action: Action(msg), query: String) -> Int {
  case action {
    Action(label:, description:, ..) -> {
      let normalized_label = string.lowercase(label)
      let normalized_description = string.lowercase(description)

      case normalized_label == query {
        True -> 100
        False ->
          case string.starts_with(normalized_label, query) {
            True -> 80
            False ->
              case string.contains(normalized_label, query) {
                True -> 60
                False ->
                  case string.starts_with(normalized_description, query) {
                    True -> 40
                    False ->
                      case string.contains(normalized_description, query) {
                        True -> 20
                        False -> 0
                      }
                  }
              }
          }
      }
    }
  }
}

fn section_has_actions(section: Section(msg)) -> Bool {
  case section {
    Section(actions: [], ..) -> False
    Section(actions: _, ..) -> True
  }
}

fn cap_section_actions(
  section: Section(msg),
  max_actions: Int,
) -> Section(msg) {
  case section {
    Section(title:, actions:) ->
      Section(title:, actions: list.take(actions, max_actions))
  }
}

fn sort_section_actions(section: Section(msg), query: String) -> Section(msg) {
  case section {
    Section(title:, actions:) ->
      Section(title:, actions: list.sort(actions, by: compare_actions(query)))
  }
}

fn compare_actions(
  query: String,
) -> fn(Action(msg), Action(msg)) -> order.Order {
  fn(left: Action(msg), right: Action(msg)) {
    let left_score = action_score(left, query)
    let right_score = action_score(right, query)

    let tie_break = case left, right {
      Action(label: left_label, ..), Action(label: right_label, ..) ->
        string.compare(left_label, right_label)
    }

    order.break_tie(in: int.compare(right_score, left_score), with: tie_break)
  }
}

fn render_shortcut(shortcut: List(String)) -> List(Element(msg)) {
  case shortcut {
    [] -> []
    [combo] -> [html.code([], [html.text(combo)])]
    [combo, ..rest] -> [
      html.code([], [html.text(combo)]),
      html.text("|"),
      ..render_shortcut(rest)
    ]
  }
}
