# Localization

This plugin supports **community-driven translations**. Adding a new language is straightforward — you only need to create one file and register it in two places.

---

## Current Locales

| File | Language | Role |
| --- | --- | --- |
| `en.js` | English (US) | Base / fallback |
| `pt_BR.js` | Português (BR) | Community translation |

Each file exports a `translations` object keyed by **stable message IDs**.

---

## Adding a New Language

### Step 1 — Create the locale file

```bash
cp i18n/en.js i18n/es_ES.js
```

Translate all **values** inside `es_ES.js`. Keys must stay exactly the same.

### Step 2 — Register in I18n singleton

Edit `AdGuardVpnI18n.qml`:

- Add a case in `normalizeLocale()` to map the system locale to your file.
- Add a case in `getBundle()` to load the new `.js` module.

### Step 3 — Add to Settings dropdown

Edit `AdGuardVpnSettings.qml`:

- Add the new locale as an option in the language `SelectionSetting`.

### Step 4 — Validate

```bash
node scripts/check-i18n-keys.mjs
```

This script checks that **every key** in `en.js` exists in all other locale files, and flags any extra/missing keys.

### Step 5 — Open a PR

Include the new locale file plus the two QML edits. Done!

---

## Translation Rules

| Rule | Example |
| --- | --- |
| **Never rename keys** | `"status.connected"` must stay `"status.connected"` |
| **Keep placeholders** | `{location}`, `{mode}`, `{count}` — translate around them |
| **Keep technical strings** | `adguardvpn-cli`, `TUN`, `SOCKS`, `QUIC` stay as-is |
| **Match tone** | Keep translations concise and consistent with the base English tone |
