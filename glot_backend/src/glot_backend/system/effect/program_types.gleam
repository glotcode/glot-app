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
import glot_backend/system/effect/basic/basic_algebra
import glot_backend/system/effect/error
import glot_backend/user_action/effect/algebra as user_action_algebra

pub type Program(a) {
  Pure(a)
  Fail(error.Error)
  Impure(Effect(Program(a)))
  Attempt(program: Program(a), on_error: fn(error.Error) -> Program(a))
}

pub type TransactionProgram(a) {
  TxPure(a)
  TxFail(error.Error)
  TxImpure(DbEffect(TransactionProgram(a)))
}

pub type Effect(next) {
  AppConfigEffect(app_config_algebra.AppConfigEffect(next))
  BasicEffect(basic_algebra.BasicEffect(next))
  EmailEffect(email_algebra.EmailEffect(next))
  WebauthnEffect(webauthn_algebra.WebauthnEffect(next))
  RunCodeEffect(run_code_algebra.RunCodeEffect(next))
  SpamClassifierEffect(spam_classifier_algebra.Effect(next))
  DbEffect(DbEffect(next))
  TransactionEffect(TransactionEffect(next))
}

pub type DbEffect(next) {
  AnalyticsEffect(analytics_algebra.AnalyticsEffect(next))
  AuthEffect(auth_algebra.AuthEffect(next))
  EmailTemplateEffect(email_template_algebra.EmailTemplateEffect(next))
  JobEffect(job_algebra.Effect(next))
  LoggingEffect(logging_algebra.Effect(next))
  SnippetEffect(snippet_algebra.SnippetEffect(next))
  UserActionEffect(user_action_algebra.UserActionEffect(next))
}

pub type TransactionEffect(next) {
  Run(program: TransactionProgram(next))
}
