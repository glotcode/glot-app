use crate::snippet::File;
use glot_languages::language::RunInstructions;

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

#[derive(Clone, serde::Deserialize)]
#[serde(untagged)]
pub enum RunOutcome {
    Success(RunResult),
    Failure(FailedRunResult),
}

#[derive(Clone, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RunRequestPayload {
    pub run_instructions: RunInstructions,
    pub files: Vec<File>,
    pub stdin: Option<String>,
}
