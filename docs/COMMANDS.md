# Command Map

Complete mapping between Service methods and the CLI commands they invoke.

> **Language / Idioma:** English is primary. Portuguese (Brazil) translation follows the English command map.

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
| `connectToLocation(x)` | `connect -l "x" -y --no-progress [-4\|-6]` | `x` = city, country, country name, or ISO code |
| `disconnect()` | `disconnect` | Sets `suppressReconnectOnce` |
| `setMode(mode)` | `config set-mode <tun\|socks>` | — |
| `setProtocol(proto)` | `config set-protocol <auto\|http2\|quic>` | — |
| `setUpdateChannel(ch)` | `config set-update-channel <release\|beta\|nightly>` | — |
| `setDns(dns)` | `config set-dns <upstream>` | — |

### Connect Preflight

Before any connect action, `prepareDisconnectedRuntime()` runs a small local shell preflight:

1. If the current mode is TUN and the advanced bypass is disabled, `ip -o route show to default` is inspected. Only non-virtual default routes sharing the minimum metric are counted as conflicts.
2. The configured `adguardBinary` is asked to `disconnect` so cleanup targets the same CLI binary used by the eventual connect command.
3. If the AdGuard control socket exists, `lsof` and then `fuser` are used to detect whether another process still owns it.
4. If the socket is not busy, the stale socket file is removed before connecting.

The preflight returns explicit statuses used by the UI: `clean`, `cleaned`, `multi-default`, `busy`, or `stale`.

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

---

## Português (Brasil)

Mapeamento dos métodos do Service para comandos do `adguardvpn-cli`.

### Como os comandos executam

```text
AdGuardVpnService.runCli(args)
  → buildArgs(baseArgs, includeConnectFlags)
  → Proc.runCommand([adguardBinary, ...finalArgs])
  → remove ANSI → parser → atualiza propriedades
```

- **Binário:** `adguardvpn-cli` por padrão, configurável por `adguardBinary`.
- **`buildArgs()`:** adiciona `-y`, `--no-progress` e flags `-4`/`-6` quando aplicável.

### Operações de leitura

| Método | Comando CLI | Parser | Timer |
| --- | --- | --- | --- |
| `checkCliAvailability()` | `--version` | checagem de versão | startup |
| `refreshStatus()` | `status` | `parseStatusOutput()` | `statusTimer` |
| `refreshConfig()` | `config show` | `parseConfigOutput()` | `metadataTimer` |
| `refreshLicense()` | `license` | `parseLicenseOutput()` | `metadataTimer` |
| `refreshLocations()` | `list-locations <count>` | `parseLocationsOutput()` | `locationsTimer` |

### Operações de escrita

| Método | Comando CLI | Observação |
| --- | --- | --- |
| `connectFastest()` | `connect -f -y --no-progress [-4\|-6]` | Usa `buildArgs` |
| `connectToLocation(x)` | `connect -l "x" -y --no-progress [-4\|-6]` | `x` = cidade, país, nome do país ou ISO |
| `disconnect()` | `disconnect` | Seta `suppressReconnectOnce` |
| `setMode(mode)` | `config set-mode <tun\|socks>` | — |
| `setProtocol(proto)` | `config set-protocol <auto\|http2\|quic>` | — |
| `setUpdateChannel(ch)` | `config set-update-channel <release\|beta\|nightly>` | — |
| `setDns(dns)` | `config set-dns <upstream>` | — |

### Preflight de conexão

Antes de conectar, `prepareDisconnectedRuntime()` executa um shell local:

1. Em modo TUN, verifica rotas default com mesma menor métrica, ignorando interfaces virtuais.
2. Chama `disconnect` pelo `adguardBinary` configurado.
3. Verifica se o socket de controle está ocupado com `lsof` e `fuser`.
4. Remove socket obsoleto quando não está ocupado.

Status possíveis: `clean`, `cleaned`, `multi-default`, `busy` ou `stale`.

### Estratégia de parsing

Toda saída passa por remoção de ANSI, parser específico e fallback seguro. Saídas vazias ou não interpretáveis não devem quebrar a UI.

### Falhas

| Cenário | Resposta |
| --- | --- |
| Exit code não zero | Atualiza `lastError`, mostra toast e atualiza status |
| Localização não encontrada | Exibe dica para atualizar localizações e usar ISO quando necessário |
| Saída não interpretável | Fallback para “Unknown” / “No output” |
| CLI indisponível | Ações desabilitadas e ícone de aviso na barra |
