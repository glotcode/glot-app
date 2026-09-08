// Editor benchmark.
//
// Drives the real reducer with the real messages against a representative
// snippet and a 100,000 character document, and reports the distribution of
// per-operation times. The plan's absolute requirements are that no ordinary
// edit takes longer than 50 ms and that no input is lost.
//
//   node scripts/benchmark-editor.mjs
//
// Requires `gleam build` to have run.

const base = "../build/dev/javascript";

const model = await import(
  `${base}/glot_frontend/glot_frontend/public/editor/code_editor/model.mjs`
);
const update = await import(
  `${base}/glot_frontend/glot_frontend/public/editor/code_editor/update.mjs`
);
const message = await import(
  `${base}/glot_frontend/glot_frontend/public/editor/code_editor/message.mjs`
);
const keys = await import(
  `${base}/glot_frontend/glot_frontend/public/editor/code_editor/keys.mjs`
);
const session = await import(
  `${base}/glot_frontend/glot_frontend/public/editor/code_editor/session.mjs`
);
const bridge = await import(
  `${base}/glot_frontend/glot_frontend/public/editor/code_editor/settings_bridge.mjs`
);
const language = await import(`${base}/glot_core/glot_core/language.mjs`);

const SNIPPET = `// A representative snippet
function fizzbuzz(limit) {
  const lines = [];
  for (let n = 1; n <= limit; n += 1) {
    const label =
      n % 15 === 0 ? "FizzBuzz" : n % 3 === 0 ? "Fizz" : n % 5 === 0 ? "Buzz" : n;
    lines.push(String(label));
  }
  return lines.join("\\n");
}

console.log(fizzbuzz(100));
`;

function largeDocument(characters) {
  const unit = SNIPPET;
  let out = "";
  while (out.length < characters) out += unit;
  return out.slice(0, characters);
}

function editor(content) {
  return model.new$(
    session.file_key(0),
    content,
    new language.JavaScript(),
    false,
    bridge.BindingMode$Plain(),
    false,
  );
}

function inputMessage(current, value, caret) {
  const active = model.active_session(current);
  return new message.InputReceived(
    new message.NativeInput(
      session.key_to_string(active.key),
      active.generation,
      value,
      caret,
      caret,
    ),
  );
}

function measure(label, iterations, step) {
  const samples = [];
  for (let i = 0; i < iterations; i += 1) {
    const started = performance.now();
    step(i);
    samples.push(performance.now() - started);
  }
  samples.sort((a, b) => a - b);
  const at = (q) => samples[Math.min(samples.length - 1, Math.floor(samples.length * q))];
  return {
    label,
    iterations,
    p50: at(0.5),
    p95: at(0.95),
    max: samples[samples.length - 1],
  };
}

function typingRun(content, characters) {
  let current = editor(content);
  let value = content;
  let lost = 0;

  const result = measure(`typing into a ${content.length} character document`, characters, (i) => {
    const typed = `x${i % 10}`.slice(0, 1);
    value = typed + value;
    const [next] = update.update(current, inputMessage(current, value, 1));
    current = next;
  });

  if (model.text(current) !== value) lost += 1;
  return { ...result, lost };
}

function movementRun(content, presses) {
  let current = editor(content);
  return measure(`caret movement in a ${content.length} character document`, presses, () => {
    const [next] = update.update(current, new message.KeyPressed(keys.plain("ArrowDown")));
    current = next;
  });
}

function scrollRun(content, steps) {
  let current = editor(content);
  let top = 0;
  const active = model.active_session(current);
  return measure(`scrolling a ${content.length} character document`, steps, () => {
    top += 260;
    const [next] = update.update(
      current,
      new message.Scrolled(
        new message.ScrollSnapshot(session.key_to_string(active.key), top, 0),
      ),
    );
    current = next;
  });
}

function loadRun(content, times) {
  return measure(`opening a ${content.length} character document`, times, () => {
    editor(content);
  });
}

const documents = [
  ["representative snippet", SNIPPET],
  ["100,000 characters", largeDocument(100_000)],
];

const rows = [];
for (const [name, content] of documents) {
  rows.push([name, loadRun(content, 20)]);
  rows.push([name, typingRun(content, 200)]);
  rows.push([name, movementRun(content, 200)]);
  rows.push([name, scrollRun(content, 50)]);
}

let failed = false;
console.log("operation                                            p50      p95      max");
for (const [, row] of rows) {
  const over = row.max > 50;
  const lost = row.lost ?? 0;
  if (over || lost > 0) failed = true;
  console.log(
    `${row.label.padEnd(50)} ${row.p50.toFixed(2).padStart(7)} ${row.p95
      .toFixed(2)
      .padStart(7)} ${row.max.toFixed(2).padStart(7)}${over ? "  OVER 50ms" : ""}${
      lost > 0 ? `  LOST ${lost}` : ""
    }`,
  );
}

if (failed) {
  console.error("\nBudget exceeded: an ordinary edit took longer than 50 ms, or input was lost.");
  process.exitCode = 1;
} else {
  console.log("\nAll operations stayed inside the 50 ms budget with no lost input.");
}
