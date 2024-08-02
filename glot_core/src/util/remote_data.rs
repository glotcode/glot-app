use serde::Deserialize;
use serde::Serialize;

#[derive(Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub enum RemoteData<E, A> {
    #[default]
    NotAsked,
    Loading,
    Failure(E),
    Success(A),
}
