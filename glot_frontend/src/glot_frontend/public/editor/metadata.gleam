import gleam/option
import glot_core/route
import glot_frontend/public/editor/lifecycle
import glot_frontend/public/editor/model.{
  type Editor, type Model, Lifecycle, Ready,
}
import glot_web/page/editor as editor_ssr
import glot_web/page/seo

pub fn changed(before: Model, after: Model) -> Bool {
  metadata(before) != metadata(after)
}

pub fn metadata(model: Model) -> seo.Metadata {
  case model {
    Lifecycle(model) -> lifecycle_metadata(model)
    Ready(model) -> editor_ssr.metadata(to_ssr_view_model(model))
  }
}

fn lifecycle_metadata(model: lifecycle.Model) -> seo.Metadata {
  case model {
    lifecycle.Initializing(target) -> initializing_metadata(target)
    lifecycle.UnsupportedLanguage(language_slug) ->
      editor_ssr.metadata(editor_ssr.UnsupportedLanguage(language_slug))
    lifecycle.LoadingSnippet(slug, _, _) ->
      seo.metadata(
        title: "Loading snippet | glot.io",
        description: "Loading a code snippet on glot.io.",
        canonical_path: route.to_string(route.Public(route.Snippet(slug))),
        index: False,
        open_graph_type: "website",
      )
    lifecycle.LoadError(message) ->
      editor_ssr.metadata(editor_ssr.LoadError(message))
  }
}

fn to_ssr_view_model(model: Editor) -> editor_ssr.ViewModel {
  let ssr_model =
    editor_ssr.EditorModel(
      slug: model.snippet.slug,
      owner_user_id: model.snippet.owner_user_id,
      owner_username: model.snippet.owner_username,
      title: model.snippet.title,
      language: model.snippet.language,
      visibility: option.Some(model.snippet.visibility),
      created_at: model.snippet.created_at,
      updated_at: model.snippet.updated_at,
      is_runnable: model.snippet.is_runnable,
      run_instructions_override: model.snippet.run_instructions_override,
      files: model.snippet.files,
      stdin: model.snippet.stdin,
    )

  case model.snippet.slug {
    option.Some(_) -> editor_ssr.ExistingSnippet(ssr_model)
    option.None -> editor_ssr.NewSnippet(ssr_model)
  }
}

fn initializing_metadata(target: lifecycle.Target) -> seo.Metadata {
  let canonical_path = case target {
    lifecycle.NewEditor(language) ->
      route.to_string(route.Public(route.NewSnippet(language)))
    lifecycle.ExistingEditor(slug) ->
      route.to_string(route.Public(route.Snippet(slug)))
  }
  seo.metadata(
    title: "Loading editor | glot.io",
    description: "Loading the glot.io code editor.",
    canonical_path: canonical_path,
    index: False,
    open_graph_type: "website",
  )
}
