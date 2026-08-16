import gleam/option
import gleam/string
import gleam/time/timestamp
import glot_core/admin/snippet_dto
import glot_core/auth/user_dto
import glot_core/language
import glot_core/loadable
import glot_core/pagination_model
import glot_core/snippet/snippet_model
import glot_frontend/admin/list_query
import glot_frontend/admin/snippets/list_model
import glot_frontend/admin/snippets/list_view
import lustre/element
import youid/uuid

pub fn owner_links_filter_the_snippet_list_by_exact_username_test() {
  let assert Ok(id) = uuid.from_string("00000000-0000-4000-8000-000000000001")
  let username = "fixture-owner"
  let snippet =
    snippet_dto.SnippetSummaryResponse(
      id: id,
      slug: "fixture-snippet",
      user: user_dto.UserResponse(id: id, username: username),
      title: "Fixture snippet",
      language: language.JavaScript,
      visibility: snippet_model.Public,
      file_count: 1,
      created_at: timestamp.from_unix_seconds(100),
      updated_at: timestamp.from_unix_seconds(200),
    )
  let model =
    list_model.Model(
      page: loadable.Loaded(pagination_model.InitialCursorPage(
        items: [snippet],
        next_cursor: option.None,
      )),
      username_filter: "",
      spam_classification_filter: "",
      query: list_query.empty(),
    )

  let rendered =
    list_view.view(model, timestamp.from_unix_seconds(300))
    |> element.to_document_string

  assert string.contains(
    rendered,
    "href=\"/admin/snippets?username=fixture-owner\"",
  )
  assert string.contains(rendered, ">fixture-owner</a>")
  assert string.contains(rendered, ">All classifications</option>")
  assert string.contains(rendered, ">Block</option>")
  assert string.contains(rendered, ">Review</option>")
  assert string.contains(rendered, ">Pass</option>")
  assert string.contains(rendered, ">Unclassified</option>")
}
