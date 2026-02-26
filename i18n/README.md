# Localization

This plugin supports community-driven translations.

## Locale files

- `en.js`: fallback/base language
- `pt_BR.js`: Brazilian Portuguese

Each file exports a `translations` object keyed by stable message IDs.

## How to add a new language

1. Copy `en.js` to `<locale>.js` (example: `es_ES.js`).
2. Translate values, keep keys unchanged.
3. Register the locale in [AdGuardVpnI18n.qml](../AdGuardVpnI18n.qml):
   - update `normalizeLocale()`
   - update `getBundle()`
4. Add the locale option to [AdGuardVpnSettings.qml](../AdGuardVpnSettings.qml).
5. Open a PR.

## Rules

- Do not rename existing keys.
- Keep placeholder tokens unchanged: `{location}`, `{mode}`, `{count}`, etc.
- Keep technical strings like command names as-is (`adguardvpn-cli`, `TUN`, `SOCKS`).
