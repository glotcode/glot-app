import gleam/option
import gleam/time/timestamp.{type Timestamp}
import glot_backend/system/effect/error/db_error
import glot_core/pagination_model.{type CursorPagination}
import glot_core/snippet/admin_snippet.{type AdminSnippet}
import glot_core/snippet/snippet_model.{
  type HydratedSnippet, type ListSnippetsFilter, type Snippet,
}
import glot_core/snippet/spam_classification
import youid/uuid.{type Uuid}

pub type SnippetEffect(next) {
  GetSnippetById(
    id: Uuid,
    next: fn(Result(option.Option(HydratedSnippet), db_error.DbQueryError)) ->
      next,
  )
  GetSnippetBySlug(
    slug: String,
    next: fn(Result(option.Option(HydratedSnippet), db_error.DbQueryError)) ->
      next,
  )
  GetSnippetBySlugForUpdate(
    slug: String,
    next: fn(Result(option.Option(HydratedSnippet), db_error.DbQueryError)) ->
      next,
  )
  GetAdminSnippetBySlug(
    slug: String,
    next: fn(Result(option.Option(AdminSnippet), db_error.DbQueryError)) -> next,
  )
  ListSnippets(
    filter: ListSnippetsFilter,
    pagination: CursorPagination,
    next: fn(Result(List(HydratedSnippet), db_error.DbQueryError)) -> next,
  )
  ListAdminSnippets(
    username: option.Option(String),
    spam_classification: option.Option(spam_classification.Filter),
    pagination: CursorPagination,
    next: fn(Result(List(HydratedSnippet), db_error.DbQueryError)) -> next,
  )
  DeleteSnippet(
    id: Uuid,
    next: fn(Result(Nil, db_error.DbCommandError)) -> next,
  )
  DeleteSnippetsByAccountId(
    account_id: Uuid,
    next: fn(Result(Nil, db_error.DbCommandError)) -> next,
  )
  CreateSnippet(
    snippet: Snippet,
    next: fn(Result(Nil, db_error.DbCommandError)) -> next,
  )
  UpdateSnippet(
    snippet: Snippet,
    next: fn(Result(Nil, db_error.DbCommandError)) -> next,
  )
  GetNewestUnclassifiedSnippet(
    next: fn(
      Result(
        option.Option(spam_classification.Candidate),
        db_error.DbQueryError,
      ),
    ) -> next,
  )
  IncrementSpamClassificationAttempts(
    id: Uuid,
    expected_updated_at: Timestamp,
    next: fn(Result(spam_classification.StoreResult, db_error.DbCommandError)) ->
      next,
  )
  StoreSpamClassification(
    id: Uuid,
    expected_updated_at: Timestamp,
    classification: spam_classification.ClassificationResult,
    next: fn(Result(spam_classification.StoreResult, db_error.DbCommandError)) ->
      next,
  )
  StoreSpamClassificationFailure(
    id: Uuid,
    expected_updated_at: Timestamp,
    failure: spam_classification.ClassificationFailure,
    next: fn(Result(spam_classification.StoreResult, db_error.DbCommandError)) ->
      next,
  )
}

pub fn map(effect: SnippetEffect(a), f: fn(a) -> b) -> SnippetEffect(b) {
  case effect {
    GetSnippetById(id, next) ->
      GetSnippetById(id, next: fn(value) { f(next(value)) })
    GetSnippetBySlug(slug, next) ->
      GetSnippetBySlug(slug, next: fn(value) { f(next(value)) })
    GetSnippetBySlugForUpdate(slug, next) ->
      GetSnippetBySlugForUpdate(slug, next: fn(value) { f(next(value)) })
    GetAdminSnippetBySlug(slug, next) ->
      GetAdminSnippetBySlug(slug, next: fn(value) { f(next(value)) })
    ListSnippets(filter:, pagination:, next:) ->
      ListSnippets(filter: filter, pagination: pagination, next: fn(value) {
        f(next(value))
      })
    ListAdminSnippets(username:, spam_classification:, pagination:, next:) ->
      ListAdminSnippets(
        username: username,
        spam_classification: spam_classification,
        pagination: pagination,
        next: fn(value) { f(next(value)) },
      )
    DeleteSnippet(id, next) ->
      DeleteSnippet(id, next: fn(value) { f(next(value)) })
    DeleteSnippetsByAccountId(account_id: account_id, next: next) ->
      DeleteSnippetsByAccountId(account_id: account_id, next: fn(value) {
        f(next(value))
      })
    CreateSnippet(snippet, next) ->
      CreateSnippet(snippet, next: fn(value) { f(next(value)) })
    UpdateSnippet(snippet, next) ->
      UpdateSnippet(snippet, next: fn(value) { f(next(value)) })
    GetNewestUnclassifiedSnippet(next:) ->
      GetNewestUnclassifiedSnippet(next: fn(value) { f(next(value)) })
    IncrementSpamClassificationAttempts(id:, expected_updated_at:, next:) ->
      IncrementSpamClassificationAttempts(
        id:,
        expected_updated_at:,
        next: fn(value) { f(next(value)) },
      )
    StoreSpamClassification(id:, expected_updated_at:, classification:, next:) ->
      StoreSpamClassification(
        id:,
        expected_updated_at:,
        classification:,
        next: fn(value) { f(next(value)) },
      )
    StoreSpamClassificationFailure(id:, expected_updated_at:, failure:, next:) ->
      StoreSpamClassificationFailure(
        id:,
        expected_updated_at:,
        failure:,
        next: fn(value) { f(next(value)) },
      )
  }
}

pub type EffectName {
  GetSnippetByIdEffectName
  GetSnippetBySlugEffectName
  GetSnippetBySlugForUpdateEffectName
  GetAdminSnippetBySlugEffectName
  ListSnippetsEffectName
  ListAdminSnippetsEffectName
  DeleteSnippetEffectName
  DeleteSnippetsByAccountIdEffectName
  CreateSnippetEffectName
  UpdateSnippetEffectName
  GetNewestUnclassifiedSnippetEffectName
  IncrementSpamClassificationAttemptsEffectName
  StoreSpamClassificationEffectName
  StoreSpamClassificationFailureEffectName
}

pub fn effect_name_to_string(name: EffectName) -> String {
  case name {
    GetSnippetByIdEffectName -> "get_snippet_by_id"
    GetSnippetBySlugEffectName -> "get_snippet_by_slug"
    GetSnippetBySlugForUpdateEffectName -> "get_snippet_by_slug_for_update"
    GetAdminSnippetBySlugEffectName -> "get_admin_snippet_by_slug"
    ListSnippetsEffectName -> "list_snippets"
    ListAdminSnippetsEffectName -> "list_admin_snippets"
    DeleteSnippetEffectName -> "delete_snippet"
    DeleteSnippetsByAccountIdEffectName -> "delete_snippets_by_account_id"
    CreateSnippetEffectName -> "create_snippet"
    UpdateSnippetEffectName -> "update_snippet"
    GetNewestUnclassifiedSnippetEffectName -> "get_newest_unclassified_snippet"
    IncrementSpamClassificationAttemptsEffectName ->
      "increment_spam_classification_attempts"
    StoreSpamClassificationEffectName -> "store_spam_classification"
    StoreSpamClassificationFailureEffectName ->
      "store_spam_classification_failure"
  }
}
