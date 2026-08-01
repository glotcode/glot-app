import gleam/regexp.{type Regexp}
import gleam/result
import gleam/string
import glot_backend/system/effect/error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_core/contact_dto.{type ContactRequest, type ValidatedContact}

pub fn is_honeypot_submission(request: ContactRequest) -> Bool {
  string.trim(request.website) != ""
}

pub fn require_valid_contact(
  request: ContactRequest,
  is_email: Regexp,
) -> Program(ValidatedContact) {
  contact_dto.validate(request, is_email)
  |> result.map_error(error.validation)
  |> program.from_result
}
