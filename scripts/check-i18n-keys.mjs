import { readFileSync, readdirSync } from "node:fs";
import { resolve } from "node:path";

const root = resolve(process.cwd());
const i18nDir = resolve(root, "i18n");
const baseLocaleFile = "en.js";
const fullParityLocales = new Set(["pt_BR.js"]);

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

const allLocaleFiles = readdirSync(i18nDir)
  .filter((name) => name.endsWith(".js"))
  .sort();

if (!allLocaleFiles.includes(baseLocaleFile)) {
  console.error(`❌ Missing base locale: ${baseLocaleFile}`);
  process.exit(1);
}

const baseContent = readFileSync(resolve(i18nDir, baseLocaleFile), "utf8");
const baseKeys = extractKeys(baseContent);

const optionalLocaleWarnings = [];
let hasErrors = false;

for (const localeFile of allLocaleFiles) {
  if (localeFile === baseLocaleFile) {
    continue;
  }

  const localeContent = readFileSync(resolve(i18nDir, localeFile), "utf8");
  const localeKeys = extractKeys(localeContent);

  const missingInLocale = diff(baseKeys, localeKeys);
  const extraInLocale = diff(localeKeys, baseKeys);

  if (extraInLocale.length > 0) {
    hasErrors = true;
    console.error(`- Unknown keys in ${localeFile}:`);
    for (const key of extraInLocale) {
      console.error(`  - ${key}`);
    }
  }

  if (fullParityLocales.has(localeFile) && missingInLocale.length > 0) {
    hasErrors = true;
    console.error(`- Missing keys in ${localeFile}:`);
    for (const key of missingInLocale) {
      console.error(`  - ${key}`);
    }
  } else if (missingInLocale.length > 0) {
    optionalLocaleWarnings.push(
      `${localeFile}: ${missingInLocale.length} key(s) missing (fallback to en.js)`,
    );
  }
}

if (hasErrors) {
  console.error("❌ i18n key parity failed");
  process.exit(1);
}

console.log(
  `✅ i18n checks OK (base: ${baseLocaleFile}, locales: ${allLocaleFiles.length})`,
);
if (optionalLocaleWarnings.length > 0) {
  console.log("ℹ️ Optional locale fallback summary:");
  for (const warning of optionalLocaleWarnings) {
    console.log(`  - ${warning}`);
  }
}
