# AdGuard VPN Plugin for DankMaterialShell

Widget plugin for DankMaterialShell that integrates with `adguardvpn-cli` to monitor connection health, apply configuration, and control VPN sessions directly from DankBar.

## Features

- Live status monitoring (`status`, `license`, `config show`)
- One-click connect/disconnect with strategy support
- Quick-connect by ranked location (`list-locations`)
- Runtime configuration controls:
  - mode (`tun` / `socks`)
  - protocol (`auto` / `http2` / `quic`)
  - update channel (`release` / `beta` / `nightly`)
  - DNS upstream
- Plugin settings for polling cadence and connect defaults
- ANSI-safe parser for CLI output

## Requirements

- DankMaterialShell `>= 1.4.0`
- AdGuard VPN CLI installed and accessible (`adguardvpn-cli`)
- Logged-in AdGuard account for connection/license actions

AdGuard CLI install guide: <https://github.com/AdguardTeam/AdGuardVPNCLI/>

## Install (Local)

1. Clone this repository to your DMS plugins directory:

```bash
git clone https://github.com/<your-user>/dms-adguard-vpn-plugin.git \
  ~/.config/DankMaterialShell/plugins/adguardVPplugin
```

2. Reload plugins:

```bash
dms ipc plugins reload adguardVPplugin
```

3. Enable the plugin if needed:

```bash
dms ipc plugins enable adguardVPplugin
```

4. Add `AdGuard VPN` widget to DankBar in DMS Settings.

## Plugin Settings

| Key | Type | Default | Purpose |
|---|---|---:|---|
| `adguardBinary` | string | `adguardvpn-cli` | CLI binary path/name |
| `refreshIntervalSec` | int | `8` | Status poll interval |
| `locationsCount` | int | `20` | Count passed to `list-locations` |
| `connectStrategy` | enum | `fastest` | Connect action behavior |
| `defaultLocation` | string | `""` | Preferred location text |
| `ipStack` | enum | `auto` | Adds `-4` or `-6` on connect |
| `autoRefreshLocations` | bool | `true` | Background location refresh |
| `showLocationInBar` | bool | `true` | Show text next to icon |

## Architecture

- `plugin.json`: manifest and permissions
- `AdGuardVpnWidget.qml`: bar pill + popout UI
- `AdGuardVpnSettings.qml`: DMS settings screen
- `AdGuardVpnService.qml`: singleton service (polling, parsing, actions)
- `qmldir`: singleton registration
- `docs/ARCHITECTURE.md`: data flow and component responsibilities
- `docs/COMMANDS.md`: command map and parser behavior

## Security and Runtime Notes

- The plugin only executes local commands through DMS process API.
- Required permissions:
  - `settings_read`
  - `settings_write`
  - `process`
- Network traffic is handled by `adguardvpn-cli` itself.
- No secrets are persisted by the plugin besides regular DMS plugin settings.

## Troubleshooting

### `adguardvpn-cli unavailable`

- Verify binary path in plugin settings.
- Validate from terminal:

```bash
adguardvpn-cli --version
```

### Auth/session issues

Use terminal to authenticate interactively:

```bash
adguardvpn-cli login
```

Then refresh in the plugin popout.

### Plugin not loading

```bash
dms ipc plugins status adguardVPplugin
dms ipc plugins reload adguardVPplugin
```

## Development

The implementation follows DMS plugin development guidance:

- <https://danklinux.com/docs/dankmaterialshell/plugin-development>

Recommended loop:

```bash
# edit files
dms ipc plugins reload adguardVPplugin
```

## Publishing

1. Tag release:

```bash
git tag v1.0.0
git push origin main --tags
```

2. Submit to DMS registry:

- <https://github.com/AvengeMedia/dms-plugin-registry>

## License

MIT. See [LICENSE](./LICENSE).
