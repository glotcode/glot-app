use serde::{Deserialize, Serialize};

#[derive(Clone, Serialize, Deserialize)]
pub struct UserAgent {
    pub os: OperatingSystem,
}

impl UserAgent {
    pub fn parse(ua: &str) -> UserAgent {
        UserAgent {
            os: OperatingSystem::parse(ua),
        }
    }
}

#[derive(Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum OperatingSystem {
    Windows,
    Mac,
    Linux,
    Android,
    IOS,
    Cloudflare,
    Other,
}

impl OperatingSystem {
    fn parse(ua: &str) -> OperatingSystem {
        if ua.contains("iPad") || ua.contains("iPhone") {
            OperatingSystem::IOS
        } else if ua.contains("Android") {
            OperatingSystem::Android
        } else if ua.contains("Mac") {
            OperatingSystem::Mac
        } else if ua.contains("Linux") {
            OperatingSystem::Linux
        } else if ua.contains("Win") {
            OperatingSystem::Windows
        } else if ua.contains("cloudflare") {
            OperatingSystem::Cloudflare
        } else {
            OperatingSystem::Other
        }
    }
}
