import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_core/language
import glot_core/snippet/snippet_dto
import glot_core/snippet/snippet_model
import glot_frontend/public/editor/command
import glot_frontend/public/editor/draft_persistence
import glot_frontend/public/editor/message.{
  type Msg, Editor, Execution, ExistingDraftLoaded, RestoreDraft,
}
import glot_frontend/public/editor/model.{type Model, Ready}
import glot_frontend/public/editor/ready
import glot_frontend/public/editor/run_instructions
import glot_frontend/public/editor/settings as editor_settings
import glot_web/page/editor as editor_ssr
import youid/uuid.{type Uuid}

pub fn from_ssr(
  model: editor_ssr.EditorModel,
  settings: editor_settings.EditorSettings,
) -> Result(#(Model, command.Command(Msg)), String) {
  let editor_ssr.EditorModel(
    slug: slug,
    owner_user_id: owner_user_id,
    owner_username: owner_username,
    title: title,
    language: language,
    visibility: visibility,
    created_at: created_at,
    updated_at: updated_at,
    run_instructions_override: run_instructions_override,
    files: files,
    stdin: stdin,
  ) = model

  case slug, visibility, updated_at {
    option.Some(slug), option.Some(visibility), option.Some(updated_at) ->
      Ok(from_data(
        slug: slug,
        owner_user_id: owner_user_id,
        owner_username: owner_username,
        title: title,
        language: language,
        visibility: visibility,
        created_at: created_at,
        updated_at: updated_at,
        run_instructions_override: run_instructions_override,
        files: files,
        stdin: stdin,
        settings: settings,
      ))
    _, _, _ -> Error("Could not load snippet.")
  }
}

pub fn from_response(
  response: snippet_dto.SnippetResponse,
  settings: editor_settings.EditorSettings,
) -> #(Model, command.Command(Msg)) {
  from_data(
    slug: response.slug,
    owner_user_id: option.Some(response.user.id),
    owner_username: option.Some(response.user.username),
    title: title_or_default(response.data.title),
    language: response.data.language,
    visibility: response.data.visibility,
    created_at: option.Some(response.created_at),
    updated_at: response.updated_at,
    run_instructions_override: response.data.run_instructions,
    files: response.data.files,
    stdin: stdin_option(response.data.stdin),
    settings: settings,
  )
}

pub fn from_data(
  slug slug: String,
  owner_user_id owner_user_id: option.Option(Uuid),
  owner_username owner_username: option.Option(String),
  title title: String,
  language language: language.Language,
  visibility visibility: snippet_model.Visibility,
  created_at created_at: option.Option(Timestamp),
  updated_at updated_at: Timestamp,
  run_instructions_override run_instructions_override: option.Option(
    language.RunInstructions,
  ),
  files files: List(snippet_model.File),
  stdin stdin: option.Option(String),
  settings settings: editor_settings.EditorSettings,
) -> #(Model, command.Command(Msg)) {
  let next_model =
    Ready(ready.existing(
      slug: slug,
      owner_user_id: owner_user_id,
      owner_username: owner_username,
      title: title,
      language: language,
      visibility: visibility,
      created_at: created_at,
      updated_at: updated_at,
      files: files,
      stdin: stdin,
      run_instructions_override: run_instructions_override,
      editor_settings: settings,
    ))

  #(
    next_model,
    command.batch([
      run_instructions.version_run_command(language)
        |> command.map(fn(msg) { Editor(Execution(msg)) }),
      command.LoadDraft(draft_persistence.ExistingSnippet(slug), fn(stored) {
        Editor(RestoreDraft(ExistingDraftLoaded(slug, updated_at, stored)))
      }),
    ]),
  )
}

fn title_or_default(title: String) -> String {
  case title == "" {
    True -> "Hello World"
    False -> title
  }
}

fn stdin_option(stdin: String) -> option.Option(String) {
  case stdin == "" {
    True -> option.None
    False -> option.Some(stdin)
  }
}
