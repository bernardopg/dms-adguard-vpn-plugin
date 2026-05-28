# Localization

This plugin supports **community-driven translations**. Adding a new language is straightforward — you only need to create one file and register it in two places.

> **Language / Idioma:** English is primary. Portuguese (Brazil) translation follows the English localization guide.

---

## Current Locales

| File | Language | Role |
| --- | --- | --- |
| `en.js` | English (US) | Base / fallback |
| `pt_BR.js` | Português (BR) | Full translation |
| `es_ES.js` | Español | Partial translation + fallback |
| `zh_CN.js` | 中文 (简体) | Partial translation + fallback |
| `hi_IN.js` | हिन्दी | Partial translation + fallback |
| `ar.js` | العربية | Partial translation + fallback |
| `bn_BD.js` | বাংলা | Partial translation + fallback |
| `fr_FR.js` | Français | Partial translation + fallback |
| `de_DE.js` | Deutsch | Partial translation + fallback |
| `ja_JP.js` | 日本語 | Partial translation + fallback |
| `ru_RU.js` | Русский | Partial translation + fallback |
| `ko_KR.js` | 한국어 | Partial translation + fallback |
| `id_ID.js` | Indonesia | Partial translation + fallback |
| `tr_TR.js` | Türkçe | Partial translation + fallback |
| `vi_VN.js` | Tiếng Việt | Partial translation + fallback |
| `it_IT.js` | Italiano | Partial translation + fallback |
| `pl_PL.js` | Polski | Partial translation + fallback |
| `nl_NL.js` | Nederlands | Partial translation + fallback |
| `fa_IR.js` | فارسی | Partial translation + fallback |
| `th_TH.js` | ไทย | Partial translation + fallback |
| `ur_PK.js` | اردو | Partial translation + fallback |
| `ms_MY.js` | Bahasa Melayu | Partial translation + fallback |

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

This script validates:

- **strict parity** for `pt_BR.js` (all keys from `en.js` must exist)
- **schema safety** for all other locales (no unknown keys)
- optional locale fallback summary (missing keys use `en.js` automatically)

### Step 5 — Open a PR

Include the new locale file plus the two QML edits. Done!

---

## Translation Rules

| Rule                       | Example                                                             |
| -------------------------- | ------------------------------------------------------------------- |
| **Never rename keys**      | `"status.connected"` must stay `"status.connected"`                 |
| **Keep placeholders**      | `{location}`, `{mode}`, `{count}` — translate around them           |
| **Keep technical strings** | `adguardvpn-cli`, `TUN`, `SOCKS`, `QUIC` stay as-is                 |
| **Match tone**             | Keep translations concise and consistent with the base English tone |

---

## Português (Brasil)

Este plugin aceita traduções mantidas pela comunidade. Para adicionar um idioma, crie um arquivo e registre o locale em dois pontos.

### Locales atuais

| Arquivo | Idioma | Papel |
| --- | --- | --- |
| `en.js` | Inglês (US) | Base / fallback |
| `pt_BR.js` | Português (BR) | Tradução completa |
| `es_ES.js`, `zh_CN.js`, `hi_IN.js`, `ar.js`, `bn_BD.js`, `fr_FR.js`, `de_DE.js`, `ja_JP.js`, `ru_RU.js`, `ko_KR.js`, `id_ID.js`, `tr_TR.js`, `vi_VN.js`, `it_IT.js`, `pl_PL.js`, `nl_NL.js`, `fa_IR.js`, `th_TH.js`, `ur_PK.js`, `ms_MY.js` | Idiomas adicionais | Tradução parcial com fallback para inglês |

Cada arquivo exporta um objeto `translations` com IDs de mensagem estáveis.

### Adicionar um novo idioma

1. Copie `i18n/en.js` para `i18n/<locale>.js`.
2. Traduza apenas os valores; mantenha as chaves intactas.
3. Registre o locale em `AdGuardVpnI18n.qml`.
4. Adicione o locale ao dropdown em `AdGuardVpnSettings.qml`.
5. Rode `node scripts/check-i18n-keys.mjs`.

### Regras de tradução

| Regra | Exemplo |
| --- | --- |
| **Nunca renomeie chaves** | `"status.connected"` deve permanecer igual |
| **Mantenha placeholders** | `{location}`, `{mode}`, `{count}` não devem mudar |
| **Preserve termos técnicos** | `adguardvpn-cli`, `TUN`, `SOCKS`, `QUIC` ficam como estão |
| **Mantenha o tom** | Traduções devem ser concisas e consistentes com o inglês base |
