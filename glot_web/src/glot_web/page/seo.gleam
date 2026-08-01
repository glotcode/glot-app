import gleam/json
import gleam/list
import gleam/option
import glot_web/page/embedded_json
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub const site_url = "https://glot.io"

pub type Metadata {
  Metadata(
    title: String,
    description: String,
    canonical_url: String,
    robots: String,
    open_graph_type: String,
  )
}

pub fn metadata(
  title title: String,
  description description: String,
  canonical_path canonical_path: String,
  index index: Bool,
  open_graph_type open_graph_type: String,
) -> Metadata {
  Metadata(
    title: title,
    description: description,
    canonical_url: site_url <> canonical_path,
    robots: case index {
      True ->
        "index, follow, max-image-preview:large, max-snippet:-1, max-video-preview:-1"
      False -> "noindex, nofollow"
    },
    open_graph_type: open_graph_type,
  )
}

pub fn title(metadata: Metadata) -> String {
  metadata.title
}

pub fn description(metadata: Metadata) -> String {
  metadata.description
}

pub fn canonical_url(metadata: Metadata) -> String {
  metadata.canonical_url
}

pub fn robots(metadata: Metadata) -> String {
  metadata.robots
}

pub fn open_graph_type(metadata: Metadata) -> String {
  metadata.open_graph_type
}

pub fn home() -> Metadata {
  metadata(
    title: "Online Code Playground – Run & Share Code | glot.io",
    description: "Run code online in dozens of programming languages. Create, execute, save, and share snippets in glot.io's fast, open-source code playground.",
    canonical_path: "/",
    index: True,
    open_graph_type: "website",
  )
}

pub fn login() -> Metadata {
  metadata(
    title: "Log in | glot.io",
    description: "Log in to glot.io to save, manage, and share your code snippets.",
    canonical_path: "/login",
    index: False,
    open_graph_type: "website",
  )
}

pub fn privacy() -> Metadata {
  metadata(
    title: "Privacy policy | glot.io",
    description: "How glot.io handles personal data, cookies, local storage, and Carbon Ads.",
    canonical_path: "/privacy",
    index: True,
    open_graph_type: "website",
  )
}

pub fn contact() -> Metadata {
  metadata(
    title: "Contact | glot.io",
    description: "Contact glot.io about privacy, security vulnerabilities, or general questions.",
    canonical_path: "/contact",
    index: True,
    open_graph_type: "website",
  )
}

pub fn snippets(
  username: option.Option(String),
  canonical_path: String,
) -> Metadata {
  let #(title, description) = case username {
    option.Some(username) -> #(
      "Code snippets by @" <> username <> " | glot.io",
      "Browse public code snippets shared by @" <> username <> " on glot.io.",
    )
    option.None -> #(
      "Public Code Snippets – Browse & Run Code | glot.io",
      "Browse public code snippets in dozens of programming languages. Open, run, edit, and share code with the glot.io online playground.",
    )
  }

  metadata(
    title: title,
    description: description,
    canonical_path: canonical_path,
    index: True,
    open_graph_type: "website",
  )
}

pub fn head_children(
  metadata: Metadata,
  social_image_url: option.Option(String),
) -> List(Element(Nil)) {
  let image_children = case social_image_url {
    option.Some(url) -> [
      meta_property("og:image", url),
      meta_property("og:image:secure_url", url),
      meta_property("og:image:type", "image/jpeg"),
      meta_property("og:image:width", "2000"),
      meta_property("og:image:height", "1000"),
      meta_property("og:image:alt", "glot.io online code playground"),
      meta_name("twitter:image", url),
      meta_name("twitter:image:alt", "glot.io online code playground"),
    ]
    option.None -> []
  }

  [
    meta_name("description", metadata.description),
    meta_name("robots", metadata.robots),
    canonical_link(metadata.canonical_url),
    meta_property("og:site_name", "glot.io"),
    meta_property("og:locale", "en_US"),
    meta_property("og:title", metadata.title),
    meta_property("og:description", metadata.description),
    meta_property("og:type", metadata.open_graph_type),
    meta_property("og:url", metadata.canonical_url),
    meta_name("twitter:card", "summary_large_image"),
    meta_name("twitter:title", metadata.title),
    meta_name("twitter:description", metadata.description),
    ..image_children
  ]
}

pub fn home_structured_data() -> Element(Nil) {
  let data =
    json.object([
      #("@context", json.string("https://schema.org")),
      #("@type", json.string("WebApplication")),
      #("name", json.string("glot.io")),
      #("url", json.string(site_url <> "/")),
      #(
        "description",
        json.string(
          "Run code online in dozens of programming languages, then save and share your snippets.",
        ),
      ),
      #("applicationCategory", json.string("DeveloperApplication")),
      #("operatingSystem", json.string("Any")),
      #("isAccessibleForFree", json.bool(True)),
      #(
        "offers",
        json.object([
          #("@type", json.string("Offer")),
          #("price", json.string("0")),
          #("priceCurrency", json.string("USD")),
        ]),
      ),
      #(
        "sameAs",
        json.array(["https://github.com/prasmussen/glot"], json.string),
      ),
    ])

  json_ld(data)
}

pub fn json_ld(data: json.Json) -> Element(Nil) {
  html.script(
    [attribute.type_("application/ld+json")],
    data |> json.to_string |> embedded_json.escape_for_html,
  )
}

pub fn append(
  base: List(Element(Nil)),
  extra: List(Element(Nil)),
) -> List(Element(Nil)) {
  list.append(base, extra)
}

pub fn meta_name(name: String, content: String) -> Element(Nil) {
  html.meta([attribute.name(name), attribute.content(content)])
}

pub fn meta_property(name: String, content: String) -> Element(Nil) {
  html.meta([
    attribute.attribute("property", name),
    attribute.content(content),
  ])
}

fn canonical_link(url: String) -> Element(Nil) {
  html.link([attribute.rel("canonical"), attribute.href(url)])
}
