import glot_core/snippet/classifier_provider.{type Provider}

pub type Config {
  Config(base_url: String, auth_token: String, provider: Provider)
}
