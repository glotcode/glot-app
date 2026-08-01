import { EditorSelection, Transaction } from "@codemirror/state";

export function initialDocumentValue(attributeValue, fallbackText) {
  return attributeValue ?? fallbackText ?? "";
}

export function shouldApplyDocumentValue({
  localRevision,
  acknowledgedRevision,
  externalRevision,
  renderedRevision,
  renderedExternalRevision
}) {
  const acknowledgesLocalEdit =
    renderedRevision !== acknowledgedRevision &&
    renderedRevision <= localRevision;
  const hasExternalUpdate = renderedExternalRevision !== externalRevision;

  return hasExternalUpdate || !acknowledgesLocalEdit;
}

function selectionForDocument(selection, documentLength) {
  const clamp = (position) => Math.min(position, documentLength);
  const ranges = selection.ranges.map((range) => {
    if (range.empty) {
      return EditorSelection.cursor(
        clamp(range.head),
        range.assoc,
        range.bidiLevel ?? undefined,
        range.goalColumn
      );
    }

    return EditorSelection.range(
      clamp(range.anchor),
      clamp(range.head),
      range.goalColumn,
      range.bidiLevel ?? undefined
    );
  });

  return EditorSelection.create(ranges, selection.mainIndex);
}

// External values replace the controlled document, but the selection remains
// explicit and stable. It must not be inferred from differences between a
// potentially delayed external value and the live editor state.
export function documentUpdate(state, incoming) {
  return {
    changes: { from: 0, to: state.doc.length, insert: incoming },
    selection: selectionForDocument(state.selection, incoming.length),
    annotations: Transaction.addToHistory.of(false)
  };
}
