import gleam/erlang/process
import gleam/option
import glot_backend/app_config/model/config as dynamic_config
import glot_backend/snippet/ports/store as snippet_store
import glot_backend/spam_classifier/domain/classify_next
import glot_backend/spam_classifier/model/config as classifier_config
import glot_backend/spam_classifier/ports/client as classifier_client
import glot_backend/system/effect/database_ports
import glot_backend/system/effect/error
import glot_backend/system/effect/error/infra_error
import glot_backend/system/effect/service_ports
import glot_backend/system/effect/system_ports
import glot_backend/system/effect/transaction/transaction_port
import glot_core/snippet/spam_classification
import support/integration/adapter/service_ports as test_service_ports
import support/integration/adapter/snippet as test_snippet_adapter
import support/integration/fixture
import support/integration/model
import support/integration/runner

pub fn invalid_snippet_is_quarantined_and_processing_continues_test() {
  let test_fixture =
    fixture.integration_fixture(
      next_uuids: [],
      jobs: [],
      account_delete_job_id: option.None,
    )
  let initial_state = with_classifier_config(test_fixture.state)
  let failures = process.new_subject()
  let classifier_error =
    error.infra(
      infra_error.SpamClassifierError(infra_error.SpamClassifierRequestFailed(
        "status=400:request_id=must-not-be-stored",
        infra_error.PermanentFailure,
        infra_error.SnippetFailure,
      )),
    )

  let #(result, _) =
    runner.run_test_program_with(
      classify_next.classify_next(fixture.test_context()),
      fixture.test_context(),
      initial_state,
      fn(test_state) {
        services(
          test_state,
          test_fixture.snippet,
          failures,
          Error(classifier_error),
        )
      },
    )

  assert result == Ok(True)
  let assert Ok(#(_, _, failure)) = process.receive(failures, 0)
  assert failure.error_code == "invalid_payload"
  assert failure.failed_at == fixture.test_system_time()
}

pub fn missing_config_is_visible_and_keeps_circuit_job_active_test() {
  let test_fixture =
    fixture.integration_fixture(
      next_uuids: [],
      jobs: [],
      account_delete_job_id: option.None,
    )

  let #(result, _) =
    runner.run_test_program_with(
      classify_next.classify_next(fixture.test_context()),
      fixture.test_context(),
      test_fixture.state,
      fn(test_state) {
        test_service_ports.defaults(test_state)
        |> test_service_ports.with_app_config(test_state)
      },
    )

  let assert Error(err) = result
  assert error.to_string(err) == "not_found:spam_classifier_config_not_found"
  assert error.failure_disposition(err)
    == infra_error.RetryIndefinitelyAfter(60)
}

fn with_classifier_config(state: model.TestState) -> model.TestState {
  let config =
    dynamic_config.DynamicConfig(
      ..state.dynamic_config,
      spam_classifier: option.Some(classifier_config.Config(
        base_url: "http://classifier:8081",
        auth_token: "secret",
      )),
    )
  model.TestState(..state, dynamic_config: config)
}

fn services(test_state, snippet, failures, classifier_result) {
  let base_services =
    test_service_ports.defaults(test_state)
    |> test_service_ports.with_app_config(test_state)
  let base_snippet_store = test_snippet_adapter.defaults()
  let candidate = spam_classification.Candidate(snippet, snippet.updated_at)
  let snippets =
    snippet_store.Store(
      ..base_snippet_store,
      get_newest_unclassified_snippet: fn() { Ok(option.Some(candidate)) },
      store_spam_classification_failure: fn(id, expected_updated_at, failure) {
        process.send(failures, #(id, expected_updated_at, failure))
        Ok(Nil)
      },
    )
  let database = database_ports.with_snippet(base_services.database, snippets)
  let system =
    system_ports.SystemPorts(
      ..base_services.system,
      spam_classifier: classifier_client.Client(classify: fn(_, _, _) {
        classifier_result
      }),
    )
  service_ports.ServicePorts(
    ..base_services,
    database: database,
    system: system,
    transaction: transaction_port.none(),
  )
}
