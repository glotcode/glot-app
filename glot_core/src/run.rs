use crate::language::Language;
use crate::snippet::File;

#[derive(Clone, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RunRequest {
    pub image: String,
    pub payload: RunRequestPayload,
}

#[derive(Clone, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RunResult {
    pub stdout: String,
    pub stderr: String,
    pub error: String,
}

impl RunResult {
    pub fn is_empty(&self) -> bool {
        self.stdout.is_empty() && self.stderr.is_empty() && self.error.is_empty()
    }
}

#[derive(Clone, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct FailedRunResult {
    pub message: String,
}

pub enum RunOutcome {
    Success(RunResult),
    Failure(FailedRunResult),
}

impl RunOutcome {
    pub fn from_value(value: serde_json::Value) -> Result<Self, serde_json::error::Error> {
        serde_json::from_value(value.clone())
            .map(Self::Success)
            .or_else(|_| serde_json::from_value(value).map(Self::Failure))
    }
}

#[derive(Clone, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RunRequestPayload {
    pub language: Language,
    pub files: Vec<File>,
    pub stdin: String,
    pub command: Option<String>,
}
