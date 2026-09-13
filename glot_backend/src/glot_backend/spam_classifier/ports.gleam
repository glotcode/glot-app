import glot_backend/spam_classifier/ports/client.{type Client}
import glot_backend/spam_classifier/ports/storage.{type Storage}

pub type Ports {
  Ports(external: Client, storage: Storage)
}
