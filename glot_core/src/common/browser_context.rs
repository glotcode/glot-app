use crate::common::route::Route;
use crate::util::user_agent::UserAgent;
use poly::browser::WindowSize;
use serde::{Deserialize, Serialize};
use url::Url;

#[derive(Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct BrowserContext {
    pub window_size: Option<WindowSize>,
    pub user_agent: UserAgent,
    pub current_url: Url,
}

impl BrowserContext {
    pub fn current_route(&self) -> Route {
        Route::from_path(self.current_url.path())
    }
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct JsBrowserContext {
    pub window_size: Option<WindowSize>,
    pub user_agent: String,
    pub current_url: Url,
}

impl JsBrowserContext {
    pub fn into_browser_context(self) -> BrowserContext {
        BrowserContext {
            window_size: self.window_size,
            user_agent: UserAgent::parse(&self.user_agent),
            current_url: self.current_url,
        }
    }
}
