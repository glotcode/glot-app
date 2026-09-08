import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/result
import glot_backend/system/file_system

const manifest_path = "/manifest.json"

const frontend_entry = "js/public.ts"

const admin_entry = "js/admin.ts"

const styles_entry = "js/styles.ts"

const social_image_entry = "assets/home-banner.jpg"

pub type Assets {
  Assets(
    frontend_src: String,
    frontend_preloads: List(String),
    admin_frontend_src: String,
    admin_frontend_preloads: List(String),
    stylesheet_href: String,
    social_image_href: String,
    admin_stylesheet_hrefs: List(String),
  )
}

pub fn load(static_base_path: String) -> Result(Assets, String) {
  use manifest <- result.try(read_manifest(static_base_path))
  use frontend <- result.try(find_entry(manifest, frontend_entry))
  use admin <- result.try(find_entry(manifest, admin_entry))
  use styles <- result.try(find_entry(manifest, styles_entry))
  use social_image <- result.try(find_entry(manifest, social_image_entry))
  use stylesheet <- result.try(
    styles.css
    |> list.first
    |> result.map_error(fn(_) {
      "Vite manifest entry " <> styles_entry <> " has no CSS asset."
    }),
  )
  let frontend_preloads = imported_files(manifest, frontend)

  Ok(Assets(
    frontend_src: static_url(frontend.file),
    frontend_preloads: frontend_preloads,
    admin_frontend_src: static_url(admin.file),
    admin_frontend_preloads: imported_files(manifest, admin),
    stylesheet_href: static_url(stylesheet),
    social_image_href: static_url(social_image.file),
    admin_stylesheet_hrefs: list.map(admin.css, static_url),
  ))
}

type ManifestEntry {
  ManifestEntry(file: String, css: List(String), imports: List(String))
}

fn read_manifest(
  static_base_path: String,
) -> Result(Dict(String, ManifestEntry), String) {
  use content <- result.try(
    file_system.read_file(static_base_path <> manifest_path)
    |> result.map_error(fn(message) {
      "Could not read Vite manifest at "
      <> static_base_path
      <> manifest_path
      <> ": "
      <> message
    }),
  )

  json.parse(content, manifest_decoder())
  |> result.map_error(fn(_) {
    "Could not decode Vite manifest at " <> static_base_path <> manifest_path
  })
}

fn find_entry(
  manifest: Dict(String, ManifestEntry),
  name: String,
) -> Result(ManifestEntry, String) {
  case dict.get(manifest, name) {
    Ok(entry) -> Ok(entry)
    Error(_) -> Error("Vite manifest has no entry named " <> name <> ".")
  }
}

fn imported_files(
  manifest: Dict(String, ManifestEntry),
  entry: ManifestEntry,
) -> List(String) {
  collect_imports(manifest, entry.imports, [])
  |> list.filter_map(fn(name) { dict.get(manifest, name) })
  |> list.map(fn(entry) { static_url(entry.file) })
}

fn collect_imports(
  manifest: Dict(String, ManifestEntry),
  names: List(String),
  collected: List(String),
) -> List(String) {
  case names {
    [] -> list.reverse(collected)
    [name, ..remaining] ->
      case list.contains(collected, name) {
        True -> collect_imports(manifest, remaining, collected)
        False ->
          case dict.get(manifest, name) {
            Ok(entry) ->
              collect_imports(manifest, list.append(remaining, entry.imports), [
                name,
                ..collected
              ])
            Error(_) -> collect_imports(manifest, remaining, collected)
          }
      }
  }
}

fn static_url(file: String) -> String {
  "/static/" <> file
}

fn manifest_decoder() -> decode.Decoder(Dict(String, ManifestEntry)) {
  decode.dict(decode.string, manifest_entry_decoder())
}

fn manifest_entry_decoder() -> decode.Decoder(ManifestEntry) {
  use file <- decode.field("file", decode.string)
  use css <- decode.optional_field("css", [], decode.list(decode.string))
  use imports <- decode.optional_field(
    "imports",
    [],
    decode.list(decode.string),
  )
  decode.success(ManifestEntry(file:, css:, imports:))
}
