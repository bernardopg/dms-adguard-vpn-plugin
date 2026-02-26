# Command Map

All commands are executed by `AdGuardVpnService.runCli()` using:

```text
[adguardBinary, ...args]
```

Default binary is `adguardvpn-cli`, configurable via settings.

## Read Operations

| Service method | CLI command |
|---|---|
| `checkCliAvailability()` | `adguardvpn-cli --version` |
| `refreshStatus()` | `adguardvpn-cli status` |
| `refreshConfig()` | `adguardvpn-cli config show` |
| `refreshLicense()` | `adguardvpn-cli license` |
| `refreshLocations()` | `adguardvpn-cli list-locations <count>` |

## Write/Action Operations

| Service method | CLI command |
|---|---|
| `connectFastest()` | `adguardvpn-cli connect -f -y --no-progress [-4|-6]` |
| `connectToLocation(x)` | `adguardvpn-cli connect -l "x" -y --no-progress [-4|-6]` |
| `disconnect()` | `adguardvpn-cli disconnect` |
| `setMode(mode)` | `adguardvpn-cli config set-mode <tun|socks>` |
| `setProtocol(protocol)` | `adguardvpn-cli config set-protocol <auto|http2|quic>` |
| `setUpdateChannel(channel)` | `adguardvpn-cli config set-update-channel <release|beta|nightly>` |
| `setDns(dns)` | `adguardvpn-cli config set-dns <upstream>` |

## Parsing Notes

- ANSI escape sequences are removed before parsing.
- `status` parser expects the connected format:
  - `Connected to <location> in <mode> mode, running on <iface>`
- `list-locations` parser splits by 2+ spaces to keep city/country names intact.
- `config show` parser maps `Key: Value` lines into normalized runtime properties.
- `license` parser extracts account, tier, devices, and renewal date when available.

## Failure Behavior

- Non-zero exit code:
  - `lastError` is updated
  - error toast is emitted
  - status refresh is attempted for reconciliation

