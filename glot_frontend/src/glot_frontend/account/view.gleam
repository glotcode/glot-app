import gleam/option
import gleam/time/calendar
import gleam/time/timestamp.{type Timestamp}
import glot_core/auth/account_dto
import glot_core/email/email_address_model
import glot_core/loadable
import glot_core/route
import glot_frontend/account/deletion
import glot_frontend/account/email_change_view
import glot_frontend/account/message.{type Msg}
import glot_web/route as web_route

import glot_frontend/account/model.{type Model, type Status}

import glot_frontend/account/passkeys_view as passkeys
import glot_frontend/account/profile
import glot_frontend/account/sessions_view as sessions
import glot_frontend/ui/delayed_loading
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn view(model: Model, now: Timestamp) -> Element(Msg) {
  html.div([attribute.class("app-page")], [
    html.div([attribute.class("app-page__screen-glow")], []),
    html.main(
      [
        attribute.id("main-content"),
        attribute.attribute("tabindex", "-1"),
        attribute.class("app-shell app-shell--narrow"),
      ],
      [
        html.section([attribute.class("account-page")], [
          html.h1([attribute.class("account-page__title")], [
            html.text("Account"),
          ]),
          content(model, now),
        ]),
      ],
    ),
  ])
}

fn content(model: Model, now: Timestamp) -> Element(Msg) {
  case
    model.account,
    delayed_loading.is_visible(model.account_loading_indicator)
  {
    loadable.Loading, True ->
      html.p(
        [
          attribute.class("account-page__status"),
          attribute.attribute("role", "status"),
        ],
        [html.text("Loading account...")],
      )

    loadable.LoadError(message), _ ->
      html.div([attribute.class("account-page__empty")], [
        html.p(
          [attribute.class("account-page__status account-page__status--error")],
          [
            html.text(message),
          ],
        ),
        html.a(
          [
            web_route.href(route.Public(route.Login)),
            attribute.class("account-page__link"),
          ],
          [
            html.text("Go to login"),
          ],
        ),
      ])

    loadable.NotLoaded, _ | loadable.Loading, False -> html.text("")

    loadable.Loaded(account), _ -> account_form(model, account, now)
  }
}

fn account_form(
  model: Model,
  account: account_dto.AccountResponse,
  now: Timestamp,
) -> Element(Msg) {
  html.div([attribute.class("account-page__panels")], [
    html.section([attribute.class("app-panel")], [
      html.h2([attribute.class("account-page__section-title")], [
        html.text("Account Info"),
      ]),
      account_row("Email", email_address_model.to_string(account.email)),
      account_row(
        "Joined",
        timestamp.to_rfc3339(account.joined_at, calendar.utc_offset),
      ),
    ]),
    html.section([attribute.class("app-panel")], [
      html.h2([attribute.class("account-page__section-title")], [
        html.text("Account Settings"),
      ]),
      account_settings_form(model),
    ]),
    html.section([attribute.class("app-panel")], [
      html.h2([attribute.class("account-page__section-title")], [
        html.text("Change Email"),
      ]),
      email_change_view.view(model),
    ]),
    html.section([attribute.class("app-panel")], [
      html.h2([attribute.class("account-page__section-title")], [
        html.text("Appearance"),
      ]),
      html.div([attribute.class("account-page__appearance")], [
        html.p([attribute.class("account-page__status")], [
          html.text("Choose a color theme, or follow your system setting."),
        ]),
        element.element(
          "glot-theme-picker",
          [attribute.class("account-page__theme-picker")],
          [],
        ),
      ]),
    ]),
    case should_show_passkey_section(model.passkey_supported) {
      True ->
        html.section([attribute.class("app-panel")], [
          html.h2([attribute.class("account-page__section-title")], [
            html.text("Passkeys"),
          ]),
          passkey_section(model, now),
        ])
      False -> html.text("")
    },
    html.section([attribute.class("app-panel")], [
      html.h2([attribute.class("account-page__section-title")], [
        html.text("Snippets"),
      ]),
      snippets_section(),
    ]),
    html.section([attribute.class("app-panel")], [
      html.h2([attribute.class("account-page__section-title")], [
        html.text("Sessions"),
      ]),
      sessions_section(model, now),
    ]),
    html.section([attribute.class("app-panel")], [
      html.h2([attribute.class("account-page__section-title")], [
        html.text("Danger Zone"),
      ]),
      delete_account_section(
        account,
        model.status,
        model.danger_zone_expanded,
        now,
      ),
    ]),
  ])
}

pub fn should_show_passkey_section(passkey_supported: Bool) -> Bool {
  passkey_supported
}

fn account_settings_form(model: Model) -> Element(Msg) {
  profile.view(model)
}

fn passkey_section(model: Model, now: Timestamp) -> Element(Msg) {
  passkeys.view(model, now)
}

fn snippets_section() -> Element(Msg) {
  html.div([attribute.class("account-page__empty")], [
    html.p([attribute.class("account-page__status")], [
      html.text("Browse, edit, and delete snippets created with your account."),
    ]),
    html.a(
      [
        web_route.href(
          route.Account(route.AccountSnippets(
            after: option.None,
            before: option.None,
          )),
        ),
        attribute.class("account-page__link"),
      ],
      [
        html.text("Manage snippets"),
      ],
    ),
  ])
}

fn sessions_section(model: Model, now: Timestamp) -> Element(Msg) {
  sessions.view(model, now)
}

fn account_row(label: String, value: String) -> Element(Msg) {
  html.div([attribute.class("account-page__row")], [
    html.span([attribute.class("account-page__row-label")], [html.text(label)]),
    html.span([attribute.class("account-page__row-value")], [html.text(value)]),
  ])
}

fn delete_account_section(
  account: account_dto.AccountResponse,
  status: Status,
  is_expanded: Bool,
  now: Timestamp,
) -> Element(Msg) {
  deletion.view(account, status, is_expanded, now)
}
