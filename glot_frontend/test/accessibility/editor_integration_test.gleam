import gleam/list
import gleam/option
import gleam/string
import gleam/time/timestamp
import glot_core/language
import glot_core/run
import glot_core/snippet/snippet_model
import glot_frontend/public/editor/execution
import glot_frontend/public/editor/lifecycle
import glot_frontend/public/editor/model
import glot_frontend/public/editor/settings
import glot_frontend/public/editor/view
import glot_frontend/ui/delayed_loading
import lustre/element
import support/accessibility
import support/editor_fixture
import support/editor_scenario

pub fn editor_lifecycle_states_satisfy_the_markup_accessibility_contract_test() {
  let supported = editor_scenario_model()
  let assert model.Ready(editor) = supported
  let #(loading, generation) = delayed_loading.begin(delayed_loading.idle())
  let visible_loading = delayed_loading.reveal(loading, generation)
  let completed =
    model.Ready(
      model.Editor(
        ..editor,
        operations: model.Operations(
          ..editor.operations,
          run_state: execution.Completed(
            Ok(run.SuccessfulRun(
              duration: 1,
              stdout: "output",
              stderr: "warning",
              error: "",
            )),
          ),
        ),
      ),
    )
  let saving =
    model.Ready(
      model.Editor(
        ..editor,
        operations: model.Operations(
          ..editor.operations,
          save_state: execution.Saving,
        ),
      ),
    )
  let save_error =
    model.Ready(
      model.Editor(
        ..editor,
        operations: model.Operations(
          ..editor.operations,
          save_state: execution.SaveError("Save failed."),
        ),
      ),
    )

  [
    model.Lifecycle(lifecycle.Initializing(lifecycle.NewEditor("javascript"))),
    model.Lifecycle(lifecycle.LoadingSnippet(
      "fixture",
      settings.defaults(),
      visible_loading,
    )),
    model.Lifecycle(lifecycle.LoadError("Could not load snippet.")),
    model.Lifecycle(lifecycle.UnsupportedLanguage("fixture")),
    supported,
    model.Ready(
      model.Editor(
        ..editor,
        operations: model.Operations(
          ..editor.operations,
          run_state: execution.Running,
        ),
      ),
    ),
    completed,
    model.Ready(
      model.Editor(
        ..editor,
        operations: model.Operations(
          ..editor.operations,
          run_state: execution.Completed(Error(run.FailedRun("Run failed."))),
        ),
      ),
    ),
    model.Ready(
      model.Editor(
        ..editor,
        operations: model.Operations(
          ..editor.operations,
          run_state: execution.RequestError("Request failed."),
        ),
      ),
    ),
    saving,
    save_error,
  ]
  |> list.each(assert_accessible)
}

pub fn populated_editor_dialogs_satisfy_the_markup_accessibility_contract_test() {
  let assert model.Ready(base) = editor_scenario_model()
  let stored =
    editor_fixture.stored_draft(
      saved_at_ms: 300_000,
      title: "Recovered",
      files: [snippet_model.File("main.js", "recovered")],
      stdin: option.Some("input"),
      run_instructions: option.Some(language.RunInstructions([], "node main.js")),
    )
  let populated =
    model.Ready(
      model.Editor(
        ..base,
        snippet: model.Snippet(
          ..base.snippet,
          slug: option.Some("accessible-editor"),
          owner_user_id: option.Some(editor_fixture.owner_id()),
          owner_username: option.Some("fixture-owner"),
          created_at: option.Some(timestamp.from_unix_seconds(100)),
          updated_at: option.Some(timestamp.from_unix_seconds(200)),
          stdin: option.Some("input"),
        ),
        workspace: model.Workspace(
          ..base.workspace,
          selected_tab: model.StdinTab,
        ),
        entry_drafts: model.EntryDrafts(
          ..base.entry_drafts,
          add: model.AddEntryDraft(
            kind: model.AddFileEntry,
            filename: "extra.js",
          ),
        ),
        restore_draft: model.RestoreDraftPending(stored),
        settings_draft: model.SettingsDraft(
          ..base.settings_draft,
          run_instructions_mode: model.CustomRunInstructions,
          run_instructions: model.RunInstructionsDraft(
            "npm run build",
            "node main.js",
          ),
        ),
      ),
    )
  assert_accessible(populated)
}

pub fn editor_states_keep_landmarks_and_expose_a_complete_tab_pattern_test() {
  let error_document =
    model.Lifecycle(lifecycle.LoadError("Could not load snippet."))
    |> render
  assert string.contains(error_document, "<main ")
  assert string.contains(error_document, "id=\"main-content\"")
  assert string.contains(error_document, "<h1>Snippet unavailable</h1>")

  let unsupported_document =
    model.Lifecycle(lifecycle.UnsupportedLanguage("fixture"))
    |> render
  assert string.contains(unsupported_document, "<main ")
  assert string.contains(unsupported_document, "id=\"main-content\"")
  assert string.contains(unsupported_document, "<h1>Unsupported language</h1>")

  let editor_document = editor_scenario_model() |> render
  assert string.contains(editor_document, "role=\"tablist\"")
  assert string.contains(editor_document, "role=\"tab\"")
  assert string.contains(editor_document, "aria-selected=\"true\"")
  assert string.contains(
    editor_document,
    "aria-controls=\"editor-source-panel\"",
  )
  assert string.contains(editor_document, "role=\"tabpanel\"")
  assert string.contains(
    editor_document,
    "aria-labelledby=\"editor-file-tab-0\"",
  )
}

fn editor_scenario_model() -> model.Model {
  editor_scenario.new_editor(language.JavaScript)
}

fn assert_accessible(editor_model: model.Model) {
  let document = render(editor_model)
  assert accessibility.audit_fragment(document) == []
}

fn render(editor_model: model.Model) -> String {
  view.view(
    editor_model,
    option.Some(editor_fixture.owner_id()),
    timestamp.from_unix_seconds(300),
  )
  |> element.to_document_string
}
