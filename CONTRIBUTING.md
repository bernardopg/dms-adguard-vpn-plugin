# Contributing

Thanks for your interest in improving the AdGuard VPN plugin! Whether you're fixing a bug, adding a feature, or translating the UI — all contributions are welcome.

---

## Quick Start

```bash
# 1. Clone the repo into DMS plugins directory
git clone https://github.com/bernardopg/dms-adguard-vpn-plugin.git \
  ~/.config/DankMaterialShell/plugins/adguardVPplugin

# 2. Make your changes, then reload
dms ipc plugins reload adguardVPplugin
dms ipc plugins status adguardVPplugin

# 3. Run quality checks before committing
node scripts/check-i18n-keys.mjs   # i18n key parity
bash scripts/lint-markdown.sh       # Markdown lint
bash scripts/validate-qml.sh        # QML syntax validation
```

---

## Development Workflow

1. **Create a branch** from `main` with a descriptive name (e.g., `fix/star-button-zorder`).
2. **Edit & test** — the fastest feedback loop is `dms ipc plugins reload adguardVPplugin`.
3. **Run all checks** (see above) — they mirror what CI will enforce.
4. **Commit** with a clear message following [Conventional Commits](https://www.conventionalcommits.org/) style:
   - `fix:` for bug fixes
   - `feat:` for new features
   - `docs:` for documentation-only changes
   - `chore:` for tooling/build changes
5. **Open a Pull Request** against `main`.

---

## Translations

Localization is community-driven. See [i18n/README.md](./i18n/README.md) for the full guide.

TL;DR:

1. Copy `i18n/en.js` → `i18n/<locale>.js`.
2. Translate values; **keep keys and `{placeholder}` tokens unchanged**.
3. Register the locale in `AdGuardVpnI18n.qml` and `AdGuardVpnSettings.qml`.
4. Run `node scripts/check-i18n-keys.mjs` to verify parity.
5. Open a PR.

---

## Issues & Bug Reports

- Use the GitHub issue templates (Bug Report / Feature Request).
- Include **reproduction steps**, **expected vs. actual behavior**, and relevant logs.
- **Never include** credentials, tokens, or personal data in logs.

---

## Release Process

Follow the [Release Checklist](./docs/RELEASE_CHECKLIST.md) before tagging.

---

## Code of Conduct

Be respectful and constructive. We follow common open-source etiquette — treat others as you'd like to be treated.
