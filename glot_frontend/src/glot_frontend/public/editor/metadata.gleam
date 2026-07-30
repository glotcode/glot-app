import gleam/option
import glot_core/route
import glot_frontend/public/editor/model.{
  type InitTarget, type Model, type RealModel, ExistingEditor, Initializing,
  LoadError, LoadingSnippet, NewEditor, SupportedLanguage, UnsupportedLanguage,
}
import glot_web/page/editor as editor_ssr
import glot_web/page/seo

pub fn changed(before: Model, after: Model) -> Bool {
  metadata(before) != metadata(after)
}

pub fn metadata(model: Model) -> seo.Metadata {
  case model {
    Initializing(target) -> initializing_metadata(target)
    UnsupportedLanguage(language_slug) ->
      editor_ssr.metadata(editor_ssr.UnsupportedLanguage(language_slug))
    LoadingSnippet(slug, _, _) ->
      seo.metadata(
        title: "Loading snippet | glot.io",
        description: "Loading a code snippet on glot.io.",
        canonical_path: route.to_string(route.Public(route.Snippet(slug))),
        index: False,
        open_graph_type: "website",
      )
    LoadError(message) -> editor_ssr.metadata(editor_ssr.LoadError(message))
    SupportedLanguage(model) -> editor_ssr.metadata(to_ssr_view_model(model))
  }
}

fn to_ssr_view_model(model: RealModel) -> editor_ssr.ViewModel {
  let ssr_model =
    editor_ssr.EditorModel(
      slug: model.slug,
      owner_user_id: model.owner_user_id,
      owner_username: model.owner_username,
      title: model.title,
      language: model.language,
      visibility: option.Some(model.visibility),
      created_at: model.created_at,
      updated_at: model.updated_at,
      run_instructions_override: model.run_instructions_override,
      files: model.files,
      stdin: model.stdin,
    )

  case model.slug {
    option.Some(_) -> editor_ssr.ExistingSnippet(ssr_model)
    option.None -> editor_ssr.NewSnippet(ssr_model)
  }
}

fn initializing_metadata(target: InitTarget) -> seo.Metadata {
  let canonical_path = case target {
    NewEditor(language) ->
      route.to_string(route.Public(route.NewSnippet(language)))
    ExistingEditor(slug) -> route.to_string(route.Public(route.Snippet(slug)))
  }
  seo.metadata(
    title: "Loading editor | glot.io",
    description: "Loading the glot.io code editor.",
    canonical_path: canonical_path,
    index: False,
    open_graph_type: "website",
  )
}
