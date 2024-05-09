use serde::Deserialize;
use serde::Serialize;

#[derive(Clone, PartialEq, Serialize, Deserialize)]
pub enum RouteName {
    Home,
    Login,
    NewSnippet,
    EditSnippet,
}

#[derive(Clone, PartialEq, Serialize, Deserialize)]
pub enum Route {
    Home,
    Login,
    NewSnippet(String),
    EditSnippet(String),
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
            ["new", language] => Some(Route::NewSnippet(language.to_string())),
            ["snippets", id] => Some(Route::EditSnippet(id.to_string())),
            _ => None,
        }
    }

    pub fn to_path(&self) -> String {
        match self {
            Route::Home => format!("/"),
            Route::Login => format!("/account/login"),
            Route::NewSnippet(language) => format!("/new/{}", language),
            Route::EditSnippet(id) => format!("/snippets/{}", id),
        }
    }

    pub fn name(&self) -> RouteName {
        match self {
            Route::Home => RouteName::Home,
            Route::Login => RouteName::Login,
            Route::NewSnippet(_) => RouteName::NewSnippet,
            Route::EditSnippet(_) => RouteName::EditSnippet,
        }
    }
}
