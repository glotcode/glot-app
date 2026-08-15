import gleam/json
import gleam/list
import gleam/option.{type Option}
import glot_backend/analytics/effect/algebra as analytics_algebra
import glot_backend/app_config/effect/algebra as app_config_algebra
import glot_backend/auth/effect/algebra as auth_algebra
import glot_backend/auth/passkey/effect/algebra as webauthn_algebra
import glot_backend/email/effect/delivery/algebra as email_algebra
import glot_backend/email/effect/template/algebra as email_template_algebra
import glot_backend/job/effect/algebra as job_algebra
import glot_backend/logging/effect/algebra as logging_algebra
import glot_backend/run_code/effect/algebra as run_code_algebra
import glot_backend/snippet/effect/algebra as snippet_algebra
import glot_backend/spam_classifier/effect/algebra as spam_classifier_algebra
import glot_backend/system/cache/cache_outcome.{type CacheOutcome}
import glot_backend/system/effect/basic/basic_algebra
import glot_backend/system/effect/transaction/transaction_algebra
import glot_backend/user_action/effect/algebra as user_action_algebra

pub type EffectName {
  AppConfigEffectName(app_config_algebra.EffectName)
  AnalyticsEffectName(analytics_algebra.EffectName)
  BasicEffectName(basic_algebra.EffectName)
  EmailEffectName(email_algebra.EffectName)
  WebauthnEffectName(webauthn_algebra.EffectName)
  EmailTemplateEffectName(email_template_algebra.EffectName)
  JobEffectName(job_algebra.EffectName)
  LoggingEffectName(logging_algebra.EffectName)
  AuthEffectName(auth_algebra.EffectName)
  SnippetEffectName(snippet_algebra.EffectName)
  RunCodeEffectName(run_code_algebra.EffectName)
  SpamClassifierEffectName(spam_classifier_algebra.EffectName)
  UserActionEffectName(user_action_algebra.EffectName)
  TransactionEffectName(
    transaction_algebra.EffectName,
    List(EffectMeasurement),
    rolled_back: Bool,
  )
}

pub fn effect_name_to_string(effect_name: EffectName) -> String {
  case effect_name {
    AppConfigEffectName(name) -> app_config_algebra.effect_name_to_string(name)
    AnalyticsEffectName(name) -> analytics_algebra.effect_name_to_string(name)
    BasicEffectName(name) -> basic_algebra.effect_name_to_string(name)
    EmailEffectName(name) -> email_algebra.effect_name_to_string(name)
    WebauthnEffectName(name) -> webauthn_algebra.effect_name_to_string(name)
    EmailTemplateEffectName(name) ->
      email_template_algebra.effect_name_to_string(name)
    JobEffectName(name) -> job_algebra.effect_name_to_string(name)
    LoggingEffectName(name) -> logging_algebra.effect_name_to_string(name)
    AuthEffectName(name) -> auth_algebra.effect_name_to_string(name)
    SnippetEffectName(name) -> snippet_algebra.effect_name_to_string(name)
    RunCodeEffectName(name) -> run_code_algebra.effect_name_to_string(name)
    SpamClassifierEffectName(name) ->
      spam_classifier_algebra.effect_name_to_string(name)
    UserActionEffectName(name) ->
      user_action_algebra.effect_name_to_string(name)
    TransactionEffectName(name, _, _) ->
      transaction_algebra.effect_name_to_string(name)
  }
}

pub fn effect_name_to_family(effect_name: EffectName) -> String {
  case effect_name {
    AppConfigEffectName(_) -> "app_config"
    AnalyticsEffectName(_) -> "analytics"
    BasicEffectName(_) -> "basic"
    EmailEffectName(_) -> "email"
    WebauthnEffectName(_) -> "webauthn"
    EmailTemplateEffectName(_) -> "email_template"
    JobEffectName(name) -> job_algebra.effect_name_to_family(name)
    LoggingEffectName(name) -> logging_algebra.effect_name_to_family(name)
    AuthEffectName(_) -> "auth"
    SnippetEffectName(_) -> "snippet"
    RunCodeEffectName(_) -> "run_code"
    SpamClassifierEffectName(_) -> "spam_classifier"
    UserActionEffectName(_) -> "user_action"
    TransactionEffectName(_, _, _) -> "transaction"
  }
}

pub type EffectKind {
  RuntimeEffect
  LogEffect
  DockerCallEffect
  EmailCallEffect
  SpamClassifierCallEffect
  CacheReadEffect(CacheOutcome)
  DatabaseReadEffect
  DatabaseWriteEffect
}

pub type EffectCategory {
  RuntimeCategory
  LogCategory
  ReadCategory
  WriteCategory
  ExternalCategory
}

pub type EffectSource {
  DatabaseEffectSource
  CacheEffectSource(CacheOutcome)
  DockerEffectSource
  EmailEffectSource
  SpamClassifierEffectSource
}

pub fn effect_kind_details(
  kind: EffectKind,
) -> #(EffectCategory, Option(EffectSource)) {
  case kind {
    RuntimeEffect -> #(RuntimeCategory, option.None)
    LogEffect -> #(LogCategory, option.None)
    DockerCallEffect -> #(ExternalCategory, option.Some(DockerEffectSource))
    EmailCallEffect -> #(ExternalCategory, option.Some(EmailEffectSource))
    SpamClassifierCallEffect -> #(
      ExternalCategory,
      option.Some(SpamClassifierEffectSource),
    )
    CacheReadEffect(outcome) -> #(
      ReadCategory,
      option.Some(CacheEffectSource(outcome)),
    )
    DatabaseReadEffect -> #(ReadCategory, option.Some(DatabaseEffectSource))
    DatabaseWriteEffect -> #(WriteCategory, option.Some(DatabaseEffectSource))
  }
}

pub fn effect_category_to_string(category: EffectCategory) -> String {
  case category {
    RuntimeCategory -> "runtime"
    LogCategory -> "log"
    ReadCategory -> "read"
    WriteCategory -> "write"
    ExternalCategory -> "external"
  }
}

pub fn effect_source_to_string(source: EffectSource) -> String {
  case source {
    DatabaseEffectSource -> "database"
    CacheEffectSource(_) -> "cache"
    DockerEffectSource -> "docker"
    EmailEffectSource -> "email"
    SpamClassifierEffectSource -> "spam_classifier"
  }
}

pub type EffectMeasurement {
  EffectMeasurement(
    name: EffectName,
    category: EffectCategory,
    source: Option(EffectSource),
    duration_ns: Int,
  )
}

pub fn encode_effect_measurements(
  effects: List(EffectMeasurement),
) -> json.Json {
  json.object([
    #("effects", json.array(effects, encode_effect_measurement)),
    #(
      "summary",
      json.object([
        #("count", json.int(list.length(effects))),
        #(
          "duration_ns",
          json.int(
            list.fold(effects, 0, fn(acc, effect_measurement) {
              acc + effect_measurement.duration_ns
            }),
          ),
        ),
      ]),
    ),
  ])
}

pub fn encode_effect_measurement(
  effect_measurement: EffectMeasurement,
) -> json.Json {
  let effect_name = effect_measurement.name
  let duration_ns = effect_measurement.duration_ns
  let effect_category = effect_category_to_string(effect_measurement.category)
  let source = option.map(effect_measurement.source, effect_source_to_string)
  let cache_outcome = case effect_measurement.source {
    option.Some(CacheEffectSource(outcome)) ->
      option.Some(cache_outcome.to_string(outcome))
    _ -> option.None
  }
  let common_fields = [
    #("category", json.string(effect_category)),
    #("family", json.string(effect_name_to_family(effect_name))),
    #("name", json.string(effect_name_to_string(effect_name))),
    #("source", json.nullable(source, json.string)),
    #("cache_outcome", json.nullable(cache_outcome, json.string)),
    #("duration_ns", json.int(duration_ns)),
  ]
  case effect_name {
    TransactionEffectName(_, sub_effects, rolled_back:) ->
      json.object(
        list.append(common_fields, [
          #("rolled_back", json.bool(rolled_back)),
          #("effects", json.array(sub_effects, encode_effect_measurement)),
        ]),
      )
    _ -> json.object(common_fields)
  }
}
