# Changelog

All notable changes to this project are documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and [Semantic Versioning](https://semver.org/).

---

## [Unreleased]

---

## [1.3.0] - 2026-04-12

### Added

- Full UI refresh for widget popout and settings with hero panels, grouped sections, metric tiles, and improved action controls.
- Runtime preflight before connect to recover stale control socket state and avoid unsafe reconnect attempts.
- New connection safety checks for multi-default-route scenarios in TUN mode.
- Multilingual expansion to 22 locales with new language bundles and locale mappings.
- Expanded language selector with all new locale options in plugin settings.
- i18n checker upgraded to validate all locale files and report fallback coverage per locale.

### Fixed

- Reduced connection failures caused by stale or busy AdGuard VPN runtime socket state.
- Added explicit user-facing errors for runtime busy and multi-default-route conditions.

### Changed

- PT-BR terminology polished for clearer localized labels (for example: Estavel, Noturno, Servidor DNS, Automatico).
- Localization docs now define strict parity for `pt_BR` and controlled fallback for extended locales.
- README now documents full multilang coverage and current locale matrix.

> **Full notes ->** [docs/releases/v1.3.0.md](./docs/releases/v1.3.0.md)

---

## [1.2.0] - 2026-03-03

### Added

- **Favorites system** — star preferred locations; favorites are pinned to the top of the list.
- **Location search & filter** — instant text filter in the popout location list.
- **Auto-connect on startup** — optionally connect when the plugin/session starts.
- **Auto-reconnect on drop** — optionally reconnect when the tunnel drops unexpectedly.
- **Tunnel log viewer** — open `~/.local/share/adguardvpn-cli/tunnel.log` directly from the popout.
- **Command history** — last command, exit code, first output line, and timestamp shown in diagnostics.
- **Contextual error hints** — location-not-found errors now suggest refreshing and using ISO codes.
- **Parsers module** (`AdGuardVpnParsers.js`) — all CLI parsers extracted into a standalone `.pragma library`.
- **`buildArgs()` utility** — centralized connect-flag assembly (`-y`, `--no-progress`, `-4`/`-6`).
- **Polling concurrency control** — timers pause during write actions to prevent overlapping reads.
- **i18n key parity script** (`scripts/check-i18n-keys.mjs`) — automated validation across locale files.
- **CI quality pipeline** — Markdown lint + QML syntax validation via GitHub Actions.
- **Issue & PR templates** — standardized contribution flow with `.github/` templates.

### Fixed

- Favorite star button unresponsive due to `locationMouse` MouseArea z-order overlap.
- Dead code removed: duplicate `normalizeProtocol()`/`normalizeChannel()` in Service (already in Parsers).
- Unreachable `return null` removed from `parseLocationLine()`.
- Architecture doc layer count corrected ("three" → "four").

### Changed

- Location list items now connect using ISO code instead of city/country string.
- Popout sections gain visible borders for better card separation.
- Flickable content area adds left/right margins and a vertical scrollbar.
- ActionButton height is now content-driven instead of a fixed 40 px.

---

## [1.1.0] — 2026-02-26

### Added

- Multilingual UI support with translation bundles (`en_US`, `pt_BR`).
- Translation contribution guide for community localization.
- Plugin screenshot assets for registry publishing.

### Fixed

- DMS plugin enable failure caused by `AdGuardVpnI18n.qml` invalid `Connections` placement.
- Widget focus-handling race for DNS input updates during typing.
- QML warning path caused by unstable `Ref` usage in widget/service wiring.

### Changed

- Updated repository URL examples in installation documentation.
- Refined README visuals and publishing readiness for registry submission.

> **Full notes →** [docs/releases/v1.1.0.md](./docs/releases/v1.1.0.md)

---

## [1.0.0] — 2026-02-26

### Added

- Initial AdGuard VPN widget plugin for DankMaterialShell.
- Live monitoring for status, config, license, and locations.
- Actions: connect, disconnect, fastest, location connect.
- Runtime config controls for mode, protocol, channel, and DNS.
- Settings screen with polling interval and connect-strategy controls.
- Technical docs: architecture overview and command mapping.
