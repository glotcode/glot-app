import gleam/json
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import gleam/time/calendar
import gleam/time/timestamp
import glot_backend/snippet/adapter/postgres/classification_row
import glot_backend/spam_classifier/domain/similarity
import glot_backend/spam_classifier/model/fingerprint.{type StoredFingerprint}
import glot_backend/spam_classifier/ports/storage
import glot_backend/sql
import glot_backend/system/database
import glot_backend/system/effect/error
import glot_backend/system/effect/error/db_error
import glot_core/helpers/uuid_helpers
import youid/uuid

pub fn new(db: database.Db) -> storage.Storage {
  storage.Storage(
    store: fn(value) {
      use rows <- result.try(database.query(
        db,
        sql.store_classifier_fingerprint(
          snippet_id: uuid.to_bit_array(value.snippet_id),
          content_revision: value.revision,
          algorithm_version: value.version,
          token_count: value.fingerprint.token_count,
          trigram_hashes: value.fingerprint.trigram_hashes,
          signature: value.fingerprint.signature,
          independently_suspicious: value.independently_suspicious,
          urls: json.array(value.urls, json.string) |> json.to_string,
          bands: value.fingerprint.bands,
        ),
        query_error,
      ))
      case rows.rows {
        [row] -> Ok(row.stored)
        _ -> Error(query_error("Expected fingerprint write result"))
      }
    },
    candidates: fn(version, bands, id) {
      use rows <- result.try(database.query(
        db,
        sql.find_classifier_neighbors(version, bands, uuid.to_bit_array(id)),
        query_error,
      ))
      Ok(
        list.map(rows.rows, fn(row) {
          fingerprint.Candidate(
            snippet_id: uuid_helpers.from_bit_array(row.snippet_id),
            revision: row.content_revision,
            slug: row.slug,
            fingerprint: similarity.Fingerprint(
              row.token_count,
              row.trigram_hashes,
              row.signature,
              [],
            ),
            independently_suspicious: row.independently_suspicious,
            matching_bands: row.matching_bands,
          )
        }),
      )
    },
    index_batch: fn(version) {
      use cursor_rows <- result.try(database.query(
        db,
        sql.get_classifier_index_cursor(version),
        query_error,
      ))
      use cursor <- result.try(case cursor_rows.rows {
        [cursor] -> Ok(cursor)
        _ -> Error(query_error("Expected fingerprint cursor"))
      })
      use rows <- result.try(database.query(
        db,
        sql.list_classifier_index_batch(cursor.after_snippet_id, version),
        query_error,
      ))
      list.try_map(rows.rows, classification_row.from_index_batch)
      |> result.map_error(error.database_query_error)
      |> result.map(fn(snippets) {
        fingerprint.IndexBatch(cursor.generation, snippets)
      })
    },
    commit_index_batch: fn(version, generation, after_id, fingerprints) {
      use rows <- result.try(database.query(
        db,
        sql.commit_classifier_index_batch(
          algorithm_version: version,
          expected_generation: generation,
          fingerprints: json.array(fingerprints, encode_fingerprint)
            |> json.to_string,
          after_snippet_id: option.map(after_id, uuid.to_bit_array),
        ),
        query_error,
      ))
      case rows.rows {
        [row] ->
          Ok(case row.applied {
            True -> option.Some(row.stored_count)
            False -> option.None
          })
        _ -> Error(query_error("Expected fingerprint batch result"))
      }
    },
  )
}

fn query_error(value) -> error.Error {
  error.database_query_error(db_error.DbQueryError(string.inspect(value)))
}

fn encode_fingerprint(value: StoredFingerprint) -> json.Json {
  json.object([
    #("snippet_id", json.string(uuid.to_string(value.snippet_id))),
    #(
      "content_revision",
      json.string(timestamp.to_rfc3339(value.revision, calendar.utc_offset)),
    ),
    #("token_count", json.int(value.fingerprint.token_count)),
    #("trigram_hashes", json.array(value.fingerprint.trigram_hashes, json.int)),
    #("signature", json.array(value.fingerprint.signature, json.int)),
    #("independently_suspicious", json.bool(value.independently_suspicious)),
    #("urls", json.array(value.urls, json.string)),
    #("bands", json.array(value.fingerprint.bands, json.string)),
  ])
}
