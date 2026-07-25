import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn view() -> Element(msg) {
  html.main(
    [
      attribute.id("main-content"),
      attribute.attribute("tabindex", "-1"),
      attribute.class("privacy-page"),
    ],
    [
      html.article([attribute.class("privacy-policy")], [
        html.header([attribute.class("privacy-policy__header")], [
          html.p([attribute.class("privacy-policy__eyebrow")], [
            html.text("Your data"),
          ]),
          html.h1([], [html.text("Privacy policy")]),
          html.p([attribute.class("privacy-policy__summary")], [
            html.text(
              "glot.io collects only what it needs to run the service and uses Carbon Ads to help fund it.",
            ),
          ]),
          html.p([attribute.class("privacy-policy__updated")], [
            html.text("Last updated: 18 July 2026"),
          ]),
        ]),
        section("Information glot.io handles", [
          paragraph(
            "When you use the site, glot.io processes requests and records limited operational data such as your IP address, browser user agent, referrer, requested page, timestamps, and diagnostic information. This is used to deliver the service, prevent abuse, investigate faults, and understand aggregate usage.",
          ),
          paragraph(
            "If you create an account, glot.io stores your email address, username, authentication credentials such as passkey public-key data, and session records. If you create or run a snippet, the service processes the code, input, metadata, visibility choice, and execution result needed to provide that feature. Public snippets and usernames are visible to everyone; unlisted snippets are available to anyone with their link; secret snippets are available only to their creator and service administrators.",
          ),
        ]),
        section("Why it is used", [
          paragraph(
            "Account, snippet, and execution data is processed to provide the features you request. Security and operational records are processed for the legitimate interests of keeping glot.io reliable, secure, and resistant to misuse. Carbon advertising data is processed for the legitimate interest of funding the service with a single relevant ad.",
          ),
        ]),
        section("Cookies and browser storage", [
          paragraph(
            "glot.io uses a necessary session cookie when you sign in. A theme preference cookie may be stored when you choose light or dark mode. The editor may use local browser storage for settings and draft recovery. These first-party features do not track you across websites.",
          ),
          paragraph(
            "Dismissal of the cookie notice is saved in local browser storage so it does not keep reappearing. This is only a display preference: Carbon Ads loads automatically on pages with an ad placement.",
          ),
          html.button(
            [
              attribute.type_("button"),
              attribute.class("privacy-policy__settings-button"),
              attribute.data("cookie-notice-settings", ""),
            ],
            [html.text("Show cookie notice")],
          ),
        ]),
        section("Carbon Ads", [
          paragraph_with_link(
            "On pages with an ad placement, your browser connects to Carbon Ads, operated by BuySellAds, to load and measure an advertisement. Carbon may receive technical data including your IP address, device and browser information, the page viewed, the time, and approximate location, and its formal policy says some services may use third-party cookies. Carbon may process data in the United States and other countries. Read ",
            "Carbon Ads’ privacy policy",
            "https://www.carbonads.net/privacy",
            ".",
          ),
          paragraph(
            "Cookies placed by Carbon are controlled by your browser and can be blocked or removed in its privacy settings.",
          ),
        ]),
        section("Retention and deletion", [
          paragraph(
            "Operational records are kept only for the configured security and troubleshooting periods, then removed. Account and snippet data is kept while needed to provide the service. You can schedule deletion of your account and its associated private data from the account page. Some minimal records may be retained where required for security, legal obligations, or resolving disputes.",
          ),
        ]),
        section("Your choices and rights", [
          paragraph(
            "Depending on where you live, you may have rights to access, correct, export, restrict, object to, or delete your personal data, and to withdraw consent. You may also complain to your local data protection authority. Withdrawing consent does not affect processing that already occurred lawfully.",
          ),
        ]),
        section("Contact", [
          paragraph_with_link(
            "Use the ",
            "contact page",
            "/contact",
            " for privacy questions or requests. Your contact address, message, request metadata, and delivery record are processed only to handle your enquiry and are removed under the operational retention schedule.",
          ),
        ]),
        section("Changes to this policy", [
          paragraph(
            "This policy may be updated when the service or its legal obligations change. The date above will be revised when that happens.",
          ),
        ]),
      ]),
    ],
  )
}

fn section(title: String, children: List(Element(msg))) -> Element(msg) {
  html.section([], [html.h2([], [html.text(title)]), ..children])
}

fn paragraph(copy: String) -> Element(msg) {
  html.p([], [html.text(copy)])
}

fn paragraph_with_link(
  before: String,
  label: String,
  href: String,
  after: String,
) -> Element(msg) {
  html.p([], [
    html.text(before),
    html.a(
      [
        attribute.href(href),
        attribute.attribute("rel", "noreferrer"),
      ],
      [html.text(label)],
    ),
    html.text(after),
  ])
}
