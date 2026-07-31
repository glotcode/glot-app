import { readFileSync } from "node:fs";
import { relative, resolve } from "node:path";

const root = resolve(import.meta.dirname, "..");
const config = JSON.parse(
  readFileSync(resolve(import.meta.dirname, "managed-boundaries.json"), "utf8"),
);
const forbiddenImports = config.forbiddenImports;

const violations = new Set();

function inspect(modulePath, chain, visited, featureForbiddenImports) {
  if (visited.has(modulePath)) return;
  visited.add(modulePath);
  const absolutePath = resolve(root, modulePath);
  const lines = readFileSync(absolutePath, "utf8").split("\n");
  lines.forEach((line, index) => {
    if (line.startsWith("@external(")) {
      violations.add(
        `${modulePath}:${index + 1} declares FFI through ${chain.join(" -> ")}`,
      );
      return;
    }
    const match = line.match(/^import\s+([^\s.{]+)/);
    if (!match) return;
    const importedModule = match[1];
    const forbidden = [...forbiddenImports, ...featureForbiddenImports].find(
      (value) => line.includes(value),
    );
    if (forbidden) {
      violations.add(
        `${relative(root, absolutePath)}:${index + 1} imports forbidden runtime dependency ${forbidden} through ${chain.join(" -> ")}`,
      );
    }
    if (importedModule.startsWith("glot_frontend/")) {
      inspect(
        `src/${importedModule}.gleam`,
        [...chain, importedModule],
        visited,
        featureForbiddenImports,
      );
    }
  });
}

for (const feature of config.features) {
  const featureForbiddenImports = feature.forbiddenImports ?? [];
  for (const modulePath of feature.modules) {
    inspect(
      modulePath,
      [`${feature.name}:${modulePath}`],
      new Set(),
      featureForbiddenImports,
    );
  }
}

if (violations.size > 0) {
  console.error(
    "Managed-effect boundary violations:\n" + [...violations].join("\n"),
  );
  process.exitCode = 1;
} else {
  console.log("Managed-effect boundaries are valid.");
}
