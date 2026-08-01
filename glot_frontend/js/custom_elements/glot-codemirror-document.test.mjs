import assert from "node:assert/strict";
import test from "node:test";
import { history, undo, undoDepth } from "@codemirror/commands";
import { EditorState } from "@codemirror/state";
import {
  documentUpdate,
  initialDocumentValue,
  shouldApplyDocumentValue
} from "./glot-codemirror-document.mjs";

test("uses SSR fallback text when no value attribute is present", () => {
  assert.equal(initialDocumentValue(null, "server-rendered source"), "server-rendered source");
});

test("client-rendered value attributes take precedence over fallback text", () => {
  assert.equal(initialDocumentValue("", "stale fallback"), "");
  assert.equal(initialDocumentValue("current source", "stale fallback"), "current source");
});

function synchronize(current, incoming, cursor) {
  const state = EditorState.create({
    doc: current,
    selection: { anchor: cursor }
  });

  return state.update(documentUpdate(state, incoming)).state;
}

test("keeps the cursor stable when external content is inserted", () => {
  const state = synchronize("world", "hello world", 5);

  assert.equal(state.doc.toString(), "hello world");
  assert.equal(state.selection.main.anchor, 5);
});

test("keeps the cursor stable when content changes after it", () => {
  const state = synchronize("one\ntwo", "one\nthree", 3);

  assert.equal(state.doc.toString(), "one\nthree");
  assert.equal(state.selection.main.anchor, 3);
});

test("clamps the cursor when the external document is shorter", () => {
  const state = synchronize("hello world", "world", 11);

  assert.equal(state.doc.toString(), "world");
  assert.equal(state.selection.main.anchor, 5);
});

test("does not add external document updates to undo history", () => {
  const state = EditorState.create({ doc: "old", extensions: history() });
  const updated = state.update(documentUpdate(state, "new")).state;

  assert.equal(updated.doc.toString(), "new");
  assert.equal(undoDepth(updated), 0);
});

test("repeated synchronization cannot duplicate document content", () => {
  let state = EditorState.create({ doc: "foo", selection: { anchor: 3 } });

  for (const incoming of ["f", "fo", "foo", "foo"]) {
    state = state.update(documentUpdate(state, incoming)).state;
  }

  assert.equal(state.doc.toString(), "foo");
  assert.equal(state.selection.main.anchor, 1);
});

test("does not apply an acknowledgement of local edits", () => {
  assert.equal(shouldApplyDocumentValue({
    localRevision: 3,
    acknowledgedRevision: 1,
    externalRevision: 0,
    renderedRevision: 3,
    renderedExternalRevision: 0
  }), false);
});

test("does not apply a stale acknowledgement while newer edits exist", () => {
  assert.equal(shouldApplyDocumentValue({
    localRevision: 3,
    acknowledgedRevision: 1,
    externalRevision: 0,
    renderedRevision: 2,
    renderedExternalRevision: 0
  }), false);
});

test("applies an explicit external document update", () => {
  assert.equal(shouldApplyDocumentValue({
    localRevision: 3,
    acknowledgedRevision: 1,
    externalRevision: 0,
    renderedRevision: 3,
    renderedExternalRevision: 1
  }), true);
});

test("applies a later external value when there is no new acknowledgement", () => {
  assert.equal(shouldApplyDocumentValue({
    localRevision: 3,
    acknowledgedRevision: 3,
    externalRevision: 1,
    renderedRevision: 3,
    renderedExternalRevision: 1
  }), true);
});

test("a local edit remains undoable after its acknowledgement", () => {
  let state = EditorState.create({ doc: "", extensions: history() });
  state = state.update({ changes: { from: 0, insert: "foo" } }).state;

  const shouldApplyAcknowledgement = shouldApplyDocumentValue({
    localRevision: 1,
    acknowledgedRevision: 0,
    externalRevision: 0,
    renderedRevision: 1,
    renderedExternalRevision: 0
  });

  assert.equal(shouldApplyAcknowledgement, false);
  assert.equal(undoDepth(state), 1);
  assert.equal(undo({ state, dispatch: (transaction) => { state = transaction.state; } }), true);
  assert.equal(state.doc.toString(), "");
});
