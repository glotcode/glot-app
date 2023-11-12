use serde::Deserialize;
use serde::Serialize;

#[derive(Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Snippet {
    pub id: String,
    pub language: String,
    pub title: String,
    pub visibility: Visibility,
    pub stdin: String,
    pub run_command: String,
    pub spam_classification: SpamClassification,
    pub files: Vec<File>,
    pub created_at: String,
    pub updated_at: String,
}

#[derive(Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct File {
    pub id: String,
    pub snippet_id: String,
    pub name: String,
    pub content: String,
    pub created_at: String,
    pub updated_at: String,
}

#[derive(Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct UnsavedSnippet {
    pub language: String,
    pub title: String,
    pub visibility: Visibility,
    pub stdin: String,
    pub run_command: String,
    pub files: Vec<UnsavedFile>,
}

#[derive(Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct UnsavedFile {
    pub name: String,
    pub content: String,
}

#[derive(Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum Visibility {
    Public,
    NeedLink,
}

#[derive(Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum SpamClassification {
    NotSpam,
    Suspected,
    Spam,
}
