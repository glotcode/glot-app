import glot_backend/spam_classifier/model/config.{type Config}
import glot_backend/system/effect/error
import glot_core/snippet/spam_classification

pub type Client {
  Client(
    classify: fn(Config, spam_classification.ServiceRequest, Int) ->
      Result(#(spam_classification.ServiceResponse, String), error.Error),
  )
}
