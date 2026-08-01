import gleam/result
import glot_backend/system/effect/error
import glot_backend/system/effect/program
import glot_backend/system/effect/program_types.{type Program}
import glot_core/pagination_model.{type CursorPage, type CursorPagination}
import glot_core/snippet/snippet_model.{type HydratedSnippet}

const max_page_size = 100

pub fn require_valid_pagination(
  pagination: CursorPagination,
) -> Program(CursorPagination) {
  use _ <- program.and_then(
    pagination_model.validate(pagination, max_page_size)
    |> result.map_error(error.validation)
    |> program.from_result,
  )
  program.succeed(pagination)
}

pub fn paginate(
  snippets: List(HydratedSnippet),
  pagination: CursorPagination,
) -> CursorPage(HydratedSnippet) {
  pagination_model.paginate(snippets, pagination, fn(snippet) {
    pagination_model.from_string(snippet.identity.slug)
  })
}

pub fn fetch_pagination(pagination: CursorPagination) -> CursorPagination {
  pagination_model.increment_limit(pagination)
}
