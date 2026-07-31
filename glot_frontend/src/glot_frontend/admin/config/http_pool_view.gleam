import gleam/option
import glot_frontend/admin/config/section
import glot_frontend/admin/config/section_view
import glot_frontend/admin/ui/form as admin_form
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

import glot_frontend/admin/config/http_pool.{
  type Model, type Msg, FieldChanged, ResetClicked, SaveClicked,
}
import glot_frontend/admin/config/http_pool_policy.{
  type Field, CloudflareEmailMaxSessions, DockerRunMaxSessions, KeepAliveTimeout,
}

pub fn view(model: Model) -> Element(Msg) {
  let dirty = section.is_dirty(model)
  section_view.card(
    title: "HTTP pools",
    subtitle: "Controls independent outbound connection pools for Docker-run and Cloudflare email.",
    state: model.mutation_state,
    dirty:,
    idle_badge: option.None,
    fields: html.div([attribute.class("admin-page__field-grid")], [
      input(
        "Docker-run max sessions",
        "Maximum persistent connections to the Docker-run service.",
        model.draft.docker_run_max_sessions,
        DockerRunMaxSessions,
      ),
      input(
        "Cloudflare email max sessions",
        "Maximum persistent connections to the Cloudflare email API.",
        model.draft.cloudflare_email_max_sessions,
        CloudflareEmailMaxSessions,
      ),
      input(
        "Keep-alive timeout",
        "Milliseconds an idle connection remains available for reuse.",
        model.draft.keep_alive_timeout_ms,
        KeepAliveTimeout,
      ),
    ]),
    footer: section_view.footer(
      load_state: model.load_state,
      mutation_state: model.mutation_state,
      dirty:,
      idle_message: option.None,
      reset_msg: ResetClicked,
      save_msg: SaveClicked,
    ),
  )
}

fn input(
  label: String,
  help: String,
  value: String,
  field: Field,
) -> Element(Msg) {
  admin_form.text_input(
    label:,
    help:,
    value:,
    placeholder: "",
    on_input: fn(value) { FieldChanged(field, value) },
  )
}
