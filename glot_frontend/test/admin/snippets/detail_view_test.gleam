import gleam/list
import gleam/option
import gleam/string
import gleam/time/timestamp
import glot_core/admin/snippet_dto
import glot_core/auth/user_dto
import glot_core/language
import glot_core/loadable
import glot_core/snippet/snippet_model
import glot_core/snippet/spam_classification
import glot_frontend/admin/snippets/detail_model
import glot_frontend/admin/snippets/detail_view
import glot_frontend/request_generation
import lustre/element
import youid/uuid

pub fn owner_name_and_id_link_to_the_admin_user_detail_page_test() {
  let assert Ok(snippet_id) =
    uuid.from_string("00000000-0000-4000-8000-000000000001")
  let assert Ok(owner_id) =
    uuid.from_string("00000000-0000-4000-8000-000000000002")
  let snippet =
    snippet_dto.SnippetDetailResponse(
      id: snippet_id,
      slug: "fixture-snippet",
      user: user_dto.UserResponse(id: owner_id, username: "fixture-owner"),
      title: "Fixture snippet",
      language: language.JavaScript,
      visibility: snippet_model.Public,
      stdin: "",
      run_instructions: option.None,
      files: [],
      spam_classification: spam_classification.ClassificationMetadata(
        decision: option.None,
        confidence: option.None,
        reason_code: option.None,
        classified_at: option.None,
        attempts: 0,
        last_error: option.None,
        failed_at: option.None,
      ),
      created_at: timestamp.from_unix_seconds(100),
      updated_at: timestamp.from_unix_seconds(200),
    )
  let model =
    detail_model.Model(
      slug: snippet.slug,
      snippet: loadable.Loaded(snippet),
      pending_delete: option.None,
      classification_state: detail_model.ClassificationIdle,
      classification_error: option.None,
      classification_generation: request_generation.initial(),
      delete_state: detail_model.DeleteIdle,
      delete_generation: request_generation.initial(),
    )

  let rendered = detail_view.view(model) |> element.to_document_string
  let owner_href = "href=\"/admin/users/00000000-0000-4000-8000-000000000002\""

  assert rendered |> string.split(owner_href) |> list.length == 4
  assert string.contains(rendered, ">fixture-owner</a>")
  assert string.contains(rendered, ">00000000-0000-4000-8000-000000000002</a>")
  assert string.contains(rendered, ">Run spam classification</button>")
}
