use base_62::base62;
use brotli::enc::BrotliEncoderParams;
use brotli::BrotliCompress;
use brotli::BrotliDecompress;
use serde::Deserialize;
use serde::Serialize;

#[derive(Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Snippet {
    pub language: String,
    pub title: String,
    pub stdin: String,
    pub files: Vec<File>,
}

impl Snippet {
    pub fn to_encoded_string(&self) -> Result<String, String> {
        let json =
            serde_json::to_vec(self).map_err(|err| format!("Failed to serialize: {}", err))?;

        let mut compressed = vec![];
        BrotliCompress(
            &mut &*json,
            &mut compressed,
            &BrotliEncoderParams::default(),
        )
        .map_err(|err| format!("Failed to compress: {}", err))?;

        Ok(base62::encode(&compressed))
    }

    pub fn from_encoded_string(encoded: &str) -> Result<Snippet, String> {
        let compressed =
            base62::decode(encoded).map_err(|err| format!("Failed to decode: {}", err))?;

        let mut json = vec![];
        BrotliDecompress(&mut &*compressed, &mut json)
            .map_err(|err| format!("Failed to decompress: {}", err))?;

        serde_json::from_slice(&json).map_err(|err| format!("Failed to deserialize: {}", err))
    }
}

#[derive(Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct File {
    pub name: String,
    pub content: String,
}
