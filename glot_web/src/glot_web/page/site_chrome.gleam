import glot_core/route
import glot_web/build_info
import glot_web/page/footer
import glot_web/page/top_bar
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn view(
  top_bar_model top_bar_model: top_bar.ViewModel(msg),
  footer_account_route footer_account_route: route.Route,
  content content: Element(msg),
) -> Element(msg) {
  html.div([], [
    html.a([attribute.class("skip-link"), attribute.href("#main-content")], [
      html.text("Skip to main content"),
    ]),
    top_bar.view(top_bar_model),
    content,
    footer.view(
      account_route: footer_account_route,
      build_info: build_info.current(),
    ),
    element.element("glot-cookie-notice", [], []),
  ])
}
