import { readRepo } from "./reader.mjs";

const roots = process.argv.slice(2);
for (const root of roots) {
  const model = readRepo(root);
  console.log("ROOT:", root);
  console.log("  top-level model keys:", Object.keys(model));
  console.log("  read meta:", JSON.stringify(model.read));
  for (const w of model.works) {
    console.log("   work:", w.id, "lifecycle:", w.lifecycle, "phase:", w.phase, "parse_warnings:", JSON.stringify(w.parse_warnings));
  }
}
