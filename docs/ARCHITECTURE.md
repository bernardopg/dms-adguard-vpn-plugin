# Architecture

## Overview

The plugin is split into three layers:

1. UI layer (`AdGuardVpnWidget.qml`)
2. Settings layer (`AdGuardVpnSettings.qml`)
3. Service layer (`AdGuardVpnService.qml`, singleton)
4. Localization layer (`AdGuardVpnI18n.qml` + `i18n/*.js`)

`PluginComponent` renders bar pills and popout controls, while the singleton centralizes command execution and parser logic.

## Data Flow

1. `AdGuardVpnService` loads persisted plugin settings from `PluginService.loadPluginData`.
2. Service starts timers for status, metadata, and location refresh.
3. Service executes CLI calls through `Proc.runCommand`.
4. CLI output is normalized (ANSI stripped) and parsed into strongly-typed properties.
5. Widget binds directly to service properties for live state updates.
6. User actions in popout invoke service methods, which execute CLI commands and refresh state.

## Service Responsibilities

- Settings lifecycle
  - read and validate settings
  - persist runtime selections
- Polling strategy
  - status timer (fast cadence)
  - metadata timer (`license`, `config show`)
  - optional locations timer
- Action dispatcher
  - connect/disconnect
  - fastest/location connect
  - mode/protocol/channel/dns writes
- Parsing
  - status line extraction
  - tabular location parsing
  - config key/value mapping
  - account/license fields

## Widget Responsibilities

- Bar representation
  - icon state
  - optional location text
- Popout interaction
  - quick actions
  - location quick-connect list
  - config controls
  - diagnostics summary
- localized labels via `AdGuardVpnI18n.tr(...)`

## Settings Responsibilities

- Expose declarative DMS setting controls
- Persist operational defaults consumed by singleton
- Keep plugin behavior predictable without manual file edits

## Error Handling

- Non-zero command exits are captured and surfaced in:
  - `AdGuardVpnService.lastError`
  - DMS toast notifications
- UI always renders fallback text to avoid blank/undefined displays.

## Permissions Model

- `settings_read`: read plugin settings
- `settings_write`: persist plugin settings
- `process`: execute local `adguardvpn-cli` commands
