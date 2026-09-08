import glot_frontend/public/editor/environment
import glot_frontend/ui/delayed_loading

/// State owned by the editor page before a loaded editor is ready.
pub type Model {
  Initializing(Target)
  UnsupportedLanguage(String)
  LoadingSnippet(String, environment.Environment, delayed_loading.State)
  LoadError(String)
}

/// The editor route that lifecycle initialization is preparing.
pub type Target {
  NewEditor(String)
  ExistingEditor(String)
}
