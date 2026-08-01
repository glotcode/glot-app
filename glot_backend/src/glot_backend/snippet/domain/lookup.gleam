import glot_backend/snippet/effect/effect as snippet_effect
import glot_backend/system/effect/error
import glot_backend/system/effect/error/resource_error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{
  type Program, type TransactionProgram,
}
import glot_backend/system/effect/transaction/transaction_program
import glot_core/snippet/snippet_model.{type HydratedSnippet}

pub fn require_by_slug(slug: String) -> Program(HydratedSnippet) {
  snippet_effect.get_by_slug(slug)
  |> program.require(error.resource(resource_error.SnippetNotFound))
}

pub fn require_by_slug_for_update(
  slug: String,
) -> TransactionProgram(HydratedSnippet) {
  snippet_effect.get_by_slug_for_update_tx(slug)
  |> transaction_program.require(error.resource(resource_error.SnippetNotFound))
}
