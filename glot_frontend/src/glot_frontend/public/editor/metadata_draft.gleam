import glot_core/snippet/snippet_model
import glot_frontend/public/editor/model.{
  type Editor, type MetadataDraft, MetadataDraft,
}

pub fn new(
  title: String,
  visibility: snippet_model.Visibility,
) -> MetadataDraft {
  MetadataDraft(title: title, visibility: visibility)
}

pub fn from_editor(editor: Editor) -> MetadataDraft {
  new(editor.snippet.title, editor.snippet.visibility)
}
