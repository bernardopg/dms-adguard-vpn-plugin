# TODO — AdGuard VPN Plugin

Technical backlog — last updated **2026-03-03**.

---

## Priority Legend

| Tag | Meaning |
| --- | --- |
| **P0** | Critical — blocks functionality or quality |
| **P1** | High — improves robustness in the short term |
| **P2** | Medium — good UX/architecture ROI |
| **P3** | Low — incremental improvement or optional expansion |

---

## Open Backlog

| # | Priority | Task | Notes |
| --- | --- | --- | --- |
| 1 | P3 | Add unit tests for `AdGuardVpnParsers.js` | Pure functions, easy to test with Node |
| 2 | P3 | Add new locale (`es_ES`) | See [i18n/README.md](./i18n/README.md) |
| 3 | P3 | Simplify `refreshStatus()` guard | Binary always has default value |

**Suggested order:** 1 → 2 → 3 (tests first for regression safety).

---

<details>
<summary><strong>Completed — Code Review (2026-03-03)</strong></summary>

- [x] **P0** Fix favorite star z-order — `locationMouse` MouseArea overlapped the star toggle.
- [x] **P1** Remove dead `normalizeProtocol()` / `normalizeChannel()` in Service.
- [x] **P1** Remove unreachable `return null` in `parseLocationLine()`.
- [x] **P1** Fix ARCHITECTURE.md — "three layers" → "four layers".

</details>

<details>
<summary><strong>Completed — Bug Fixes (earlier)</strong></summary>

- [x] **P0** Fix duplicate `### Added` heading in CHANGELOG.md.
- [x] **P0** Fix releases/v1.1.0.md lint (H1 heading + bare URL).
- [x] **P1** Remove duplicate `checkCliAvailability()` call on startup.
- [x] **P1** Support alternate `status` output formats in parser.
- [x] **P1** Add defensive fallback for unexpected `list-locations` column spacing.
- [x] **P2** Normalize pt_BR placeholder for `settings.default_location.placeholder`.

</details>

<details>
<summary><strong>Completed — Improvements</strong></summary>

- [x] **P1** Central `buildArgs()` utility for CLI flag assembly.
- [x] **P1** Polling concurrency control (pause/resume timers during actions).
- [x] **P1** Last command history for popout diagnostics.
- [x] **P2** Extract parsers into standalone `AdGuardVpnParsers.js` module.
- [x] **P2** Contextual recovery hint on location-not-found errors.
- [x] **P2** Automated i18n key parity validation script.

</details>

<details>
<summary><strong>Completed — Features</strong></summary>

- [x] **P2** Favorite locations (pinned to top).
- [x] **P2** Location search/filter in popout.
- [x] **P2** "Open tunnel log" action.
- [x] **P3** Auto-connect on session start.
- [x] **P3** Auto-reconnect on tunnel drop.

</details>

<details>
<summary><strong>Completed — Process & Quality</strong></summary>

- [x] **P1** CI quality pipeline (Markdown lint + QML validation).
- [x] **P1** Release checklist with version consistency checks.
- [x] **P2** Updated ARCHITECTURE.md and COMMANDS.md for location normalization.
- [x] **P2** Advanced troubleshooting section in README.md.
- [x] **P3** Issue/PR templates for standardized contributions.

</details>
