import gleam/option.{type Option}
import glot_core/snippet/classification_explanation.{type Explanation}
import glot_core/snippet/spam_classification.{type ServiceResponse}

/// Internal result; the external HTTP request and response stay unchanged.
pub type Classification {
  Classification(
    response: ServiceResponse,
    request_id: String,
    explanation: Option(Explanation),
  )
}
