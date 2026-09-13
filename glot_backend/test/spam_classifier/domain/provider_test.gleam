import gleam/erlang/process
import gleam/option
import glot_backend/spam_classifier/effect/classification
import glot_backend/spam_classifier/model/config
import glot_backend/spam_classifier/ports
import glot_backend/spam_classifier/ports/client
import glot_core/snippet/classifier_provider
import glot_core/snippet/spam_classification
import support/integration/fixture
import support/spam_classifier_storage

pub fn provider_switch_during_attempt_only_affects_next_attempt_test() {
  let fixture = fixture.integration_fixture([], [], option.None)
  let selected = process.new_subject()
  let external_calls = process.new_subject()
  let external =
    config.Config(
      "https://classifier.example",
      "token",
      classifier_provider.External,
    )
  let local = config.Config(..external, provider: classifier_provider.Local)
  let ports =
    ports.Ports(
      external: client.Client(classify: fn(captured, _, _) {
        assert captured == external
        process.send(external_calls, Nil)
        process.send(selected, local)
        Ok(#(
          spam_classification.ServiceResponse(
            spam_classification.Block,
            91,
            spam_classification.Ambiguous,
          ),
          "external-request",
        ))
      }),
      storage: spam_classifier_storage.empty_index(),
    )
  let request = spam_classification.ServiceRequest(fixture.snippet, True)
  let assert Ok(first) =
    classification.run(external, request, ports, fixture.ctx)
  let assert option.Some(explanation) = first.explanation
  assert explanation.provider == classifier_provider.External
  assert first.response.decision == spam_classification.Block
  let assert Ok(next_config) = process.receive(selected, 0)
  let assert Ok(second) =
    classification.run(next_config, request, ports, fixture.ctx)
  let assert option.Some(explanation) = second.explanation
  assert explanation.provider == classifier_provider.Local
  let assert Ok(Nil) = process.receive(external_calls, 0)
  assert process.receive(external_calls, 0) == Error(Nil)
}
