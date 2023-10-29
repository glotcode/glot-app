use std::path::PathBuf;

pub fn filter_by_extension(files: Vec<PathBuf>, extension: &str) -> Vec<PathBuf> {
    files
        .into_iter()
        .filter(|file| file.extension().and_then(|s| s.to_str()) == Some(extension))
        .collect()
}

pub fn join_files(files: Vec<PathBuf>) -> String {
    files
        .iter()
        .map(|file| file.display().to_string())
        .collect::<Vec<String>>()
        .join(" ")
}
