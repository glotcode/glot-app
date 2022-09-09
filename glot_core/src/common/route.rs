use serde::Deserialize;
use serde::Serialize;

#[derive(Debug, PartialEq, Serialize, Deserialize)]
pub enum RouteName {
    Home,
    NewSnippet,
    NewSnippetEditor,
}

#[derive(Debug, PartialEq, Serialize, Deserialize)]
pub enum Route {
    Home,
    NewSnippet,
    NewSnippetEditor(String),
}

impl Default for Route {
    fn default() -> Self {
        Self::Home
    }
}

impl Route {
    pub fn from_path(path: &str) -> Option<Route> {
        let parts = path
            .trim_start_matches("/")
            .trim_end_matches("/")
            .split("/")
            .collect::<Vec<&str>>();

        match parts.as_slice() {
            [] => Some(Route::Home),
            ["new"] => Some(Route::NewSnippet),
            ["new", id] => Some(Route::NewSnippetEditor(id.to_string())),
            _ => None,
        }
    }

    pub fn to_path(&self) -> String {
        match self {
            Route::Home => format!("/"),
            Route::NewSnippet => format!("/new"),
            Route::NewSnippetEditor(language) => format!("/new/{}", language),
        }
    }

    pub fn name(&self) -> RouteName {
        match self {
            Route::Home => RouteName::Home,
            Route::NewSnippet => RouteName::NewSnippet,
            Route::NewSnippetEditor(_) => RouteName::NewSnippetEditor,
        }
    }
}
