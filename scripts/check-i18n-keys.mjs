import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const root = resolve(process.cwd());
const enPath = resolve(root, "i18n/en.js");
const ptPath = resolve(root, "i18n/pt_BR.js");

function extractKeys(fileContent) {
  const keyRegex = /^\s*"([^"]+)"\s*:/gm;
  const keys = [];
  let match;
  while ((match = keyRegex.exec(fileContent)) !== null) {
    keys.push(match[1]);
  }
  return new Set(keys);
}

function diff(sourceSet, targetSet) {
  return [...sourceSet].filter((key) => !targetSet.has(key)).sort();
}

const enContent = readFileSync(enPath, "utf8");
const ptContent = readFileSync(ptPath, "utf8");

const enKeys = extractKeys(enContent);
const ptKeys = extractKeys(ptContent);

const missingInPt = diff(enKeys, ptKeys);
const missingInEn = diff(ptKeys, enKeys);

if (missingInPt.length === 0 && missingInEn.length === 0) {
  console.log("✅ i18n key parity OK (en.js ↔ pt_BR.js)");
  process.exit(0);
}

console.error("❌ i18n key parity failed");
if (missingInPt.length > 0) {
  console.error("- Missing in pt_BR.js:");
  for (const key of missingInPt) {
    console.error(`  - ${key}`);
  }
}
if (missingInEn.length > 0) {
  console.error("- Missing in en.js:");
  for (const key of missingInEn) {
    console.error(`  - ${key}`);
  }
}

process.exit(1);
