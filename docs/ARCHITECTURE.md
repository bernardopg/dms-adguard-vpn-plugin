# Architecture

This document describes the internal design and data flow of the AdGuard VPN plugin.

---

## Layer Overview

The plugin is organized into **four layers**, each with a single responsibility:

```text
┌──────────────────────────────────────────────────────┐
│                    DankBar / DMS                     │
├────────────────────────┬─────────────────────────────┤
│   AdGuardVpnWidget     │   AdGuardVpnSettings        │
│   (bar pill + popout)  │   (DMS settings screen)     │
├────────────────────────┴─────────────────────────────┤
│               AdGuardVpnService  (singleton)          │
│   polling · actions · state · buildArgs · parsers     │
├──────────────────────────────────────────────────────┤
│               AdGuardVpnI18n  (singleton)              │
│              i18n/en.js · i18n/pt_BR.js                │
├──────────────────────────────────────────────────────┤
│       AdGuardVpnParsers.js  (.pragma library)         │
│   parseStatusOutput · parseConfigOutput · …           │
└──────────────────────────────────────────────────────┘
         ↕ Proc.runCommand()
   ┌─────────────┐
   │ adguardvpn- │
   │ cli (local) │
   └─────────────┘
```

| Layer | File(s) | Role |
| --- | --- | --- |
| **UI** | `AdGuardVpnWidget.qml` | Bar pill, popout controls, location list, config cards |
| **Settings** | `AdGuardVpnSettings.qml` | Declarative DMS setting controls |
| **Service** | `AdGuardVpnService.qml` | Singleton: settings lifecycle, CLI execution, polling, state management |
| **Localization** | `AdGuardVpnI18n.qml` + `i18n/*.js` | Translation lookups with fallback chain |
| **Parsers** | `AdGuardVpnParsers.js` | Pure functions: parse CLI output into structured data |

---

## Data Flow

```text
1. Startup
   Component.onCompleted → loadSettings() → checkCliAvailability()
                                          → restartTimers()
                                          → maybeAutoConnectOnStartup()

2. Polling (repeating timers)
   statusTimer ──→ refreshStatus()  ──→ runCli("status")  ──→ parseStatus()
   metadataTimer → refreshConfig()  ──→ runCli("config")  ──→ parseConfig()
                   refreshLicense() ──→ runCli("license") ──→ parseLicense()
   locationsTimer → refreshLocations() → runCli("list-locations") → parseLocations()

3. User actions
   Widget button → Service method (e.g. connectFastest())
                 → suspendPolling() → runCli() → resumePolling()
                 → recordLastCommand() → toast notification → refreshStatus()
```

**Key principle:** the Widget never runs CLI commands directly. It binds to Service properties and calls Service methods. The Service owns all state.

---

## Service Responsibilities

### Settings Lifecycle

- Load and validate all settings from `PluginService.loadPluginData()` on startup.
- Each setting is normalized (type-checked, clamped, default-fallback).
- Saves individual settings with `saveSetting(key, value)`.

### Polling Strategy

| Timer | Cadence | What it refreshes |
| --- | --- | --- |
| `statusTimer` | `refreshIntervalSec` (default 8 s) | VPN connection state |
| `metadataTimer` | `refreshIntervalSec × 3` (min 15 s) | Config + license info |
| `locationsTimer` | `refreshIntervalSec × 6` (min 30 s) | Ranked server locations |

During write actions (`runAction`), all timers are **suspended** to avoid conflicting reads, and **resumed** after completion.

### Action Dispatcher

- **Connect:** `connectFastest()`, `connectToLocation(text)`, `connectWithStrategy()`
- **Disconnect:** `disconnect()` (sets `suppressReconnectOnce` to avoid auto-reconnect loop)
- **Config writes:** `setMode()`, `setProtocol()`, `setUpdateChannel()`, `setDns()`
- **Utilities:** `openTunnelLog()`, `toggleFavoriteLocation()`

All actions use `buildArgs()` to append `-y`, `--no-progress`, and IP stack flags consistently.

### Reconnect Logic

- `maybeScheduleReconnect(wasConnected, nowConnected)` triggers a 5 s timer when the tunnel drops.
- Suppressed after explicit `disconnect()` to prevent unwanted reconnects.

---

## Parsers (`AdGuardVpnParsers.js`)

All parsers are **pure functions** in a `.pragma library` module — no QML/state dependencies.

| Function | Input | Output |
| --- | --- | --- |
| `parseStatusOutput(clean)` | CLI `status` text | `{ connected, disconnected, empty, connectedLocation, … }` |
| `parseLicenseOutput(clean)` | CLI `license` text | `{ accountEmail, accountTier, maxDevices, subscriptionRenewDate }` |
| `parseConfigOutput(clean, fallback)` | CLI `config show` text | `{ currentMode, currentProtocol, dnsUpstream, … }` |
| `parseLocationsOutput(clean)` | CLI `list-locations` text | `{ locations: [...], parseFailed: bool }` |
| `parseLocationLine(line)` | Single location line | `{ iso, country, city, ping, label }` or `null` |

The location parser tries **five column-splitting strategies** in order: multi-space, tab, pipe, CSV, and dashed format — making it resilient to CLI output changes.

---

## Widget Responsibilities

- **Bar pill:** icon (shield states) + optional location text.
- **Popout sections:**
  - Status card (connection state, account, last sync, diagnostics)
  - Quick actions (connect/disconnect, fastest, refresh, open log)
  - Locations (search filter, favorites, quick-connect by ISO)
  - Configuration (mode, protocol, update channel, DNS)
- All labels go through `AdGuardVpnI18n.tr(key, fallback, params)`.

---

## Settings Screen

- Declarative DMS settings (`SelectionSetting`, `SliderSetting`, `ToggleSetting`, `StringSetting`).
- Persists values that `AdGuardVpnService.loadSettings()` picks up on change.
- No direct CLI interaction.

---

## Error Handling

| Scenario | What happens |
| --- | --- |
| Non-zero exit code | `lastError` updated, error toast emitted, status refresh triggered |
| Location not found | Contextual hint appended: *"Try refreshing locations and using the ISO code"* |
| CLI unavailable | All actions disabled, bar shows warning icon, status shows unavailable message |
| Empty/unparseable output | Graceful fallback to "Unknown" / "No output" with no crash |

---

## Permissions Model

| Permission | Why |
| --- | --- |
| `settings_read` | Load plugin settings from DMS storage |
| `settings_write` | Persist plugin settings (polling interval, strategy, favorites, etc.) |
| `process` | Execute local `adguardvpn-cli` commands via `Proc.runCommand` |
