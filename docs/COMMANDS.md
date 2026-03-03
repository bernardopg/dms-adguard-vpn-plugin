# Command Map

Complete mapping between Service methods and the CLI commands they invoke.

---

## How Commands Run

```text
AdGuardVpnService.runCli(args)
  → buildArgs(baseArgs, includeConnectFlags)
  → Proc.runCommand([adguardBinary, ...finalArgs])
  → strip ANSI → parse output → update properties
```

- **Binary:** `adguardvpn-cli` (default, configurable via `adguardBinary` setting).
- **`buildArgs()`** appends `-y`, `--no-progress`, and `-4`/`-6` flags when `includeConnectFlags` is true.

---

## Read Operations

These run on recurring timers and never modify VPN state.

| Method | CLI Command | Parser | Timer |
| --- | --- | --- | --- |
| `checkCliAvailability()` | `--version` | version string check | startup only |
| `refreshStatus()` | `status` | `parseStatusOutput()` | `statusTimer` |
| `refreshConfig()` | `config show` | `parseConfigOutput()` | `metadataTimer` |
| `refreshLicense()` | `license` | `parseLicenseOutput()` | `metadataTimer` |
| `refreshLocations()` | `list-locations <count>` | `parseLocationsOutput()` | `locationsTimer` |

---

## Write / Action Operations

These are triggered by user interaction. All timers are **suspended** during execution.

| Method | CLI Command | Notes |
| --- | --- | --- |
| `connectFastest()` | `connect -f -y --no-progress [-4\|-6]` | Uses `buildArgs` for flags |
| `connectToLocation(x)` | `connect -l "x" -y --no-progress [-4\|-6]` | `x` = ISO code or label |
| `disconnect()` | `disconnect` | Sets `suppressReconnectOnce` |
| `setMode(mode)` | `config set-mode <tun\|socks>` | — |
| `setProtocol(proto)` | `config set-protocol <auto\|http2\|quic>` | — |
| `setUpdateChannel(ch)` | `config set-update-channel <release\|beta\|nightly>` | — |
| `setDns(dns)` | `config set-dns <upstream>` | — |

---

## Parsing Strategy

All CLI output goes through a pipeline:

1. **ANSI strip** — escape sequences removed before any parsing.
2. **Format-specific parser** — pure functions in `AdGuardVpnParsers.js`.
3. **Fallback** — on parse failure, properties receive safe defaults ("Unknown", empty, `false`).

### Parser Highlights

| Parser | Strategy |
| --- | --- |
| `parseStatusOutput` | Regex match on connected/disconnected variants, key-value extraction |
| `parseConfigOutput` | `Key: Value` line mapping with current-config fallback for partial output |
| `parseLicenseOutput` | Line-by-line field extraction (email, tier, devices, renewal date) |
| `parseLocationsOutput` | Tries 5 column-splitting strategies in order: multi-space, tab, pipe, CSV, dashed |

---

## Failure Behavior

| Scenario | Response |
| --- | --- |
| Non-zero exit code | `lastError` updated, error toast emitted, status refresh triggered |
| Location not found | Contextual hint: *"Try refreshing locations and using the ISO code"* |
| Unparseable output | Graceful fallback with "Unknown" / "No output" — no crash |
| CLI unavailable | All actions disabled, warning icon shown in bar |
