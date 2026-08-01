import gleam/list
import gleam/option
import gleam/result
import gleam/string
import gleam/time/timestamp.{type Timestamp}
import glot_backend/auth/error as auth_error
import glot_backend/auth/passkey/base64url
import glot_backend/system/effect/error
import glot_backend/system/effect/error/infra_error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_core/auth/passkey_challenge_model.{
  type PasskeyChallenge, type PasskeyChallengeFlow,
}
import glot_core/auth/passkey_credential_model.{type PasskeyCredential}
import glot_core/validation_error
import youid/uuid.{type Uuid}

pub fn require_not_expired(
  challenge: PasskeyChallenge,
  now: Timestamp,
) -> Program(PasskeyChallenge) {
  case timestamp_is_on_or_before(now, challenge.expires_at) {
    True -> program.succeed(challenge)
    False -> program.fail(error.auth(auth_error.PasskeyChallengeExpired))
  }
}

pub fn require_flow(
  challenge: PasskeyChallenge,
  expected_flow: PasskeyChallengeFlow,
) -> Program(PasskeyChallenge) {
  case challenge.flow == expected_flow {
    True -> program.succeed(challenge)
    False -> program.fail(error.auth(auth_error.InvalidPasskeyAssertion))
  }
}

pub fn require_challenge_user(
  challenge: PasskeyChallenge,
  user_id: Uuid,
) -> Program(PasskeyChallenge) {
  case challenge.user_id {
    option.Some(challenge_user_id) if challenge_user_id == user_id ->
      program.succeed(challenge)
    _ -> program.fail(error.auth(auth_error.InvalidPasskeyAssertion))
  }
}

pub fn decode_base64url(field: String, value: String) -> Program(BitArray) {
  case string.trim(value) == "" {
    True -> program.fail(error.validation(validation_error.EmptyField(field)))
    False ->
      base64url.decode(value)
      |> result.map_error(fn(message) {
        error.infra(infra_error.RunRequestClientError(
          "Invalid base64url value for " <> field <> ": " <> message,
        ))
      })
      |> program.from_result
  }
}

pub fn challenge_state(challenge: PasskeyChallenge) -> BitArray {
  challenge.challenge_state
}

pub fn credential_entries(
  credentials: List(PasskeyCredential),
) -> List(#(BitArray, BitArray)) {
  list.map(credentials, fn(credential) {
    #(credential.credential_id, credential.cose_key)
  })
}

fn timestamp_is_on_or_before(left: Timestamp, right: Timestamp) -> Bool {
  let #(left_seconds, left_nanos) =
    timestamp.to_unix_seconds_and_nanoseconds(left)
  let #(right_seconds, right_nanos) =
    timestamp.to_unix_seconds_and_nanoseconds(right)

  left_seconds < right_seconds
  || { left_seconds == right_seconds && left_nanos <= right_nanos }
}
