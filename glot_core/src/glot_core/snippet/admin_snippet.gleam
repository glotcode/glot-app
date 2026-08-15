import glot_core/snippet/snippet_model.{type HydratedSnippet}
import glot_core/snippet/spam_classification.{type ClassificationMetadata}

pub type AdminSnippet {
  AdminSnippet(
    snippet: HydratedSnippet,
    spam_classification: ClassificationMetadata,
  )
}
