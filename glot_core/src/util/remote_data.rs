use serde::Deserialize;
use serde::Serialize;

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum RemoteData<E, A> {
    NotAsked,
    Loading,
    Failure(E),
    Success(A),
}
