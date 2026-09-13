import gleam/float
import gleam/int
import gleam/list
import gleam/option
import gleam/string
import glot_core/admin/spam_review_dto.{type ReviewSnippet}
import glot_core/language
import glot_core/loadable
import glot_core/pagination_model
import glot_core/snippet/classification_explanation.{type Explanation}
import glot_core/snippet/classifier_provider
import glot_core/snippet/manual_review
import glot_core/snippet/spam_classification
import glot_frontend/admin/spam_review/managed
import glot_frontend/admin/spam_review/message.{type Msg}
import glot_frontend/admin/spam_review/model.{type Model}
import glot_frontend/admin/spam_review/query
import glot_frontend/admin/ui/cursor_page
import glot_frontend/admin/ui/filter
import glot_frontend/admin/ui/form
import glot_frontend/admin/ui/format
import glot_frontend/admin/ui/layout
import glot_frontend/admin/ui/status
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import youid/uuid

pub fn view(model: Model) -> Element(Msg) {
  layout.page_with_panel_class(
    "admin-spam-review",
    "Spam review",
    "Review one snippet at a time.",
    [],
    [
      filters(model),
      html.div(
        [attribute.class("admin-spam-review__controls")],
        controls(model),
      ),
      case model.error {
        option.None -> html.text("")
        option.Some(error) -> status.error_status(error)
      },
      case model.saving {
        True -> status.status("Saving review…")
        False -> html.text("")
      },
      case model.page {
        loadable.NotLoaded | loadable.Loading ->
          status.status("Loading review queue…")
        loadable.LoadError(error) ->
          html.div([], [
            status.error_status(error),
            button("Retry loading", message.Reload, False),
          ])
        loadable.Loaded(page) ->
          case pagination_model.items(page) {
            [] ->
              status.empty_state(
                "Queue complete. No more matching snippets in this direction.",
              )
            [item, ..] -> snippet(item)
          }
      },
    ],
  )
}

fn controls(model: Model) -> List(Element(Msg)) {
  let item = managed.current(model)
  let no_item = item == option.None
  let no_verdict = case item {
    option.Some(item) -> item.manual_review.verdict == option.None
    option.None -> True
  }
  let page = cursor_page.current_page(model.page)
  [
    button(
      "Spam",
      message.Save(option.Some(manual_review.Spam)),
      model.saving || no_item,
    ),
    button(
      "Not spam",
      message.Save(option.Some(manual_review.NotSpam)),
      model.saving || no_item,
    ),
    button(
      "Clear manual verdict",
      message.Save(option.None),
      model.saving || no_verdict,
    ),
    button(
      "Undo last review",
      message.Undo,
      model.saving || model.undo == option.None,
    ),
    button(
      "Previous",
      message.Previous,
      model.saving || pagination_model.previous_cursor(page) == option.None,
    ),
    button(
      "Next",
      message.Next,
      model.saving || pagination_model.next_cursor(page) == option.None,
    ),
    button("Reload", message.Reload, model.saving),
  ]
}

fn button(label: String, msg: Msg, disabled: Bool) -> Element(Msg) {
  html.button(
    [
      attribute.type_("button"),
      attribute.class(case msg {
        message.Save(option.Some(_)) | message.Apply -> "admin-page__button"
        _ -> layout.secondary_button_class()
      }),
      attribute.disabled(disabled),
      event.on_click(msg),
    ],
    [html.text(label)],
  )
}

fn filters(model: Model) -> Element(Msg) {
  let draft = model.draft
  filter.filter_section(
    "Combine filters to choose the review queue.",
    filter.filter_surface([], [
      html.fieldset([attribute.disabled(model.saving)], [
        html.legend([], [html.text("Review filters")]),
        filter.filter_field_grid([], [
          form.select_input(
            "Automated decision",
            draft.decision,
            message.FieldChanged(query.Decision, _),
            [
              #("all", "All"),
              #("flagged", "Flagged (Review or Block)"),
              #("allow", "Allow"),
              #("review", "Review"),
              #("block", "Block"),
              #("unclassified", "Unclassified"),
            ],
            "",
          ),
          form.select_input(
            "Reason code",
            draft.reason,
            message.FieldChanged(query.Reason, _),
            list.map(
              [
                "",
                "none",
                "promotional_content",
                "contact_solicitation",
                "link_spam",
                "seo_spam",
                "scam_or_phishing",
                "obfuscated_spam",
                "keyword_stuffing",
                "ambiguous",
              ],
              fn(value) {
                #(value, case value {
                  "" -> "All"
                  _ -> value
                })
              },
            ),
            "",
          ),
          form.text_input(
            "Confidence minimum",
            "Inclusive, 0–100",
            draft.minimum,
            "0",
            message.FieldChanged(query.Minimum, _),
          ),
          form.text_input(
            "Confidence maximum",
            "Inclusive, 0–100",
            draft.maximum,
            "100",
            message.FieldChanged(query.Maximum, _),
          ),
          form.select_input(
            "Manual status",
            draft.manual,
            message.FieldChanged(query.Manual, _),
            [
              #("all", "All"),
              #("unreviewed", "Unreviewed"),
              #("spam", "Spam"),
              #("not_spam", "Not spam"),
            ],
            "",
          ),
          form.text_input(
            "Username",
            "Exact username",
            draft.username,
            "username",
            message.FieldChanged(query.Username, _),
          ),
          form.select_input(
            "Language",
            draft.language,
            message.FieldChanged(query.Language, _),
            [
              #("", "All"),
              ..list.map(language.list(), fn(value) {
                #(language.to_string(value), language.name(value))
              })
            ],
            "",
          ),
        ]),
        filter.filter_actions([], [
          button("Apply", message.Apply, model.saving),
          button("Clear", message.Clear, model.saving),
        ]),
      ]),
    ]),
  )
}

fn snippet(item: ReviewSnippet) -> Element(Msg) {
  let snippet = item.snippet
  let classification = snippet.spam_classification
  html.div([attribute.class("admin-spam-review__body")], [
    html.div([], [
      html.h2([], [html.text(snippet.title)]),
      html.p([], [
        html.text(
          "Owner: "
          <> snippet.user.username
          <> " · Language: "
          <> language.name(snippet.language),
        ),
      ]),
      ..list.append(
        list.map(snippet.files, fn(file) {
          text_section(file.name, file.content)
        }),
        [
          text_section("stdin", snippet.stdin),
          text_section("Run instructions", case snippet.run_instructions {
            option.None -> "No custom run instructions"
            option.Some(instructions) ->
              string.join(
                list.append(instructions.build_commands, [
                  instructions.run_command,
                ]),
                "\n",
              )
          }),
        ],
      )
    ]),
    html.aside([], [
      html.h2([], [html.text("Classification")]),
      layout.detail_item(
        "Automated decision",
        option.map(
          classification.decision,
          spam_classification.decision_to_string,
        )
          |> option.unwrap("Unclassified"),
      ),
      layout.detail_item(
        "Confidence",
        option.map(classification.confidence, int.to_string)
          |> option.unwrap("Unavailable"),
      ),
      layout.detail_item(
        "Reason",
        option.map(
          classification.reason_code,
          spam_classification.reason_code_to_string,
        )
          |> option.unwrap("Unavailable"),
      ),
      layout.detail_item(
        "Classified at",
        format.optional_timestamp(classification.classified_at),
      ),
      layout.detail_item("Attempts", int.to_string(classification.attempts)),
      layout.detail_item(
        "Last error",
        option.unwrap(classification.last_error, "None"),
      ),
      layout.detail_item(
        "Failed at",
        format.optional_timestamp(classification.failed_at),
      ),
      explanation(classification.explanation),
      html.h2([], [html.text("Execution check")]),
      layout.detail_item("Runnable", case snippet.runnability.is_runnable {
        option.None -> "Unchecked"
        option.Some(True) -> "Yes"
        option.Some(False) -> "No"
      }),
      layout.detail_item(
        "Checked at",
        format.optional_timestamp(snippet.runnability.checked_at),
      ),
      layout.detail_item(
        "Check attempts",
        int.to_string(snippet.runnability.attempts),
      ),
      layout.detail_item(
        "Check error",
        option.unwrap(snippet.runnability.last_error, "None"),
      ),
      layout.detail_item(
        "Check failed at",
        format.optional_timestamp(snippet.runnability.failed_at),
      ),
      layout.detail_item(
        "Content revision",
        format.format_timestamp(snippet.updated_at),
      ),
      html.h2([], [html.text("Manual review")]),
      layout.detail_item(
        "Verdict",
        option.map(item.manual_review.verdict, fn(verdict) {
          case verdict {
            manual_review.Spam -> "Spam"
            manual_review.NotSpam -> "Not spam"
          }
        })
          |> option.unwrap("Unreviewed"),
      ),
      layout.detail_item(
        "Reviewer ID",
        option.map(item.manual_review.reviewer_id, uuid.to_string)
          |> option.unwrap("None"),
      ),
      layout.detail_item(
        "Reviewed at",
        format.optional_timestamp(item.manual_review.reviewed_at),
      ),
      layout.detail_item(
        "Review version",
        int.to_string(item.manual_review.version),
      ),
    ]),
  ])
}

fn text_section(title: String, value: String) -> Element(Msg) {
  html.section([], [
    html.h3([], [html.text(title)]),
    html.pre(
      [
        attribute.class("admin-page__code-block admin-spam-review__text"),
        attribute.tabindex(0),
        attribute.attribute("aria-label", title),
      ],
      [html.text(value)],
    ),
  ])
}

fn explanation(value: option.Option(Explanation)) -> Element(Msg) {
  case value {
    option.None -> html.p([], [html.text("Explanation unavailable")])
    option.Some(value) ->
      html.div([], [
        layout.detail_item(
          "Provider",
          classifier_provider.to_string(value.provider),
        ),
        layout.detail_item(
          "Classifier version",
          option.unwrap(value.version, "Unavailable"),
        ),
        layout.detail_item(
          "Risk score",
          option.map(value.score, int.to_string) |> option.unwrap("Unavailable"),
        ),
        text_section("Signals", string.join(value.signals, "\n")),
        text_section(
          "Similar snippets",
          string.join(
            list.map(value.neighbors, fn(neighbor) {
              neighbor.slug
              <> " · Similarity: "
              <> float.to_string(neighbor.similarity)
              <> " · Revision: "
              <> format.format_timestamp(neighbor.revision)
            }),
            "\n",
          ),
        ),
      ])
  }
}
