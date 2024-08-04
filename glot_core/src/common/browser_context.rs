use crate::util::user_agent::UserAgent;
use poly::browser::WindowSize;
use serde::{Deserialize, Deserializer, Serialize};
use url::Url;

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct BrowserContext {
    pub window_size: Option<WindowSize>,
    #[serde(deserialize_with = "user_agent_from_string")]
    pub user_agent: UserAgent,
    pub current_url: Url,
}

fn user_agent_from_string<'de, D>(deserializer: D) -> Result<UserAgent, D::Error>
where
    D: Deserializer<'de>,
{
    let str: String = Deserialize::deserialize(deserializer)?;
    Ok(UserAgent::parse(&str))
}
