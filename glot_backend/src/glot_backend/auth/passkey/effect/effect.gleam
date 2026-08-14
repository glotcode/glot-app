import glot_backend/auth/passkey/effect/algebra as webauthn_algebra
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types

pub fn new_registration_challenge(
  origin: String,
  rp_id: String,
  user_verification: String,
) -> program_types.Program(Result(#(String, BitArray), String)) {
  program.perform(
    program_types.WebauthnEffect(webauthn_algebra.NewRegistrationChallenge(
      origin,
      rp_id,
      user_verification,
      program.succeed,
    )),
  )
}

pub fn register(
  attestation_object: BitArray,
  client_data_json: String,
  challenge_state: BitArray,
) -> program_types.Program(Result(#(BitArray, BitArray, Int, BitArray), String)) {
  program.perform(
    program_types.WebauthnEffect(webauthn_algebra.Register(
      attestation_object,
      client_data_json,
      challenge_state,
      program.succeed,
    )),
  )
}

pub fn new_authentication_challenge(
  origin: String,
  rp_id: String,
  user_verification: String,
  credentials: List(#(BitArray, BitArray)),
) -> program_types.Program(Result(#(String, List(String), BitArray), String)) {
  program.perform(
    program_types.WebauthnEffect(webauthn_algebra.NewAuthenticationChallenge(
      origin,
      rp_id,
      user_verification,
      credentials,
      program.succeed,
    )),
  )
}

pub fn authenticate(
  credential_id: BitArray,
  authenticator_data: BitArray,
  signature: BitArray,
  client_data_json: String,
  challenge_state: BitArray,
  credentials: List(#(BitArray, BitArray)),
) -> program_types.Program(Result(#(Int, BitArray), String)) {
  program.perform(
    program_types.WebauthnEffect(webauthn_algebra.Authenticate(
      credential_id,
      authenticator_data,
      signature,
      client_data_json,
      challenge_state,
      credentials,
      program.succeed,
    )),
  )
}
