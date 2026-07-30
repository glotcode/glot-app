import glot_core/route
import glot_frontend/app/public_page_state.{
  type Model, Account, Contact, Editor, Empty, Home, Login, ManageSnippets,
  Privacy, Snippets,
}
import glot_frontend/public/editor/metadata as editor_metadata
import glot_frontend/public/snippets/view as snippets_view
import glot_web/page/seo

pub fn metadata(model: Model, current_route: route.Route) -> seo.Metadata {
  case model {
    Home(_) -> seo.home()
    Contact(_) -> seo.contact()
    Privacy -> seo.privacy()
    Login(_) -> seo.login()
    Snippets(page_model) ->
      snippets_view.metadata(page_model, route.to_string(current_route))
    Editor(page_model) -> editor_metadata.metadata(page_model)
    Account(_) ->
      private_metadata(
        "Account | glot.io",
        "Secure glot.io account page.",
        "/account",
      )
    ManageSnippets(_) ->
      private_metadata(
        "Your snippets | glot.io",
        "Manage your glot.io code snippets.",
        "/account/snippets",
      )
    Empty ->
      private_metadata(
        "Page not found | glot.io",
        "The requested glot.io page could not be found.",
        "/",
      )
  }
}

fn private_metadata(
  title: String,
  description: String,
  path: String,
) -> seo.Metadata {
  seo.metadata(
    title:,
    description:,
    canonical_path: path,
    index: False,
    open_graph_type: "website",
  )
}
