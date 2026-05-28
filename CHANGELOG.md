# Changelog

All notable changes to this project are documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and [Semantic Versioning](https://semver.org/).

> **Language / Idioma:** English is primary. Portuguese (Brazil) translations are provided after the English changelog.

---

## [Unreleased]

---

## [1.3.4] - 2026-05-28

### Fixed

- Auto-connect on startup now waits for the initial status and config reads before connecting, preventing SOCKS setups from being blocked by TUN-only route preflight checks.
- Enabling Auto Connect after startup no longer triggers an immediate connection outside the startup window.
- Runtime preflight now disconnects through the configured `adguardBinary` instead of a hardcoded `adguardvpn-cli` command.
- Location list quick-connect and favorites now target the specific city/country row instead of collapsing every location to its country ISO code.
- Boolean settings loaded from string storage now handle `"false"`, `"0"`, `"off"`, and `"no"` correctly.

### Changed

- Documented the connect preflight behavior and added the i18n key check to CI.

> **Full notes ->** [docs/releases/v1.3.4.md](./docs/releases/v1.3.4.md)

---

## [1.3.3] - 2026-04-22

### Fixed

- Multi-default-route preflight check now only counts routes sharing the minimum metric. Physical interfaces with different metrics (e.g. Ethernet metric 100 + Wi-Fi metric 600) are no longer treated as a routing conflict, eliminating false-positive TUN-connect blocks on startup and after every disconnect.
- Virtual interfaces (`lo`, `docker*`, `veth*`, `br-*`, `virbr*`, `dummy*`) are excluded from the route count to prevent false positives from container runtimes.

### Added

- **Bypass Multi-Route Check** toggle in Settings → Advanced to explicitly skip the preflight route check on setups where it still produces false positives.

> **Full notes ->** [docs/releases/v1.3.3.md](./docs/releases/v1.3.3.md)

---

## [1.3.2] - 2026-04-12

### Changed

- Updated README screenshots to the latest plugin UI captures for registry listing.
- Adjusted README features table formatting for cleaner Markdown/registry rendering.
- Removed obsolete screenshot assets from docs package.

> **Full notes ->** [docs/releases/v1.3.2.md](./docs/releases/v1.3.2.md)

---

## [1.3.1] - 2026-04-12

### Fixed

- Restored account detection when `adguardvpn-cli license` is slow by adding a longer command timeout and an in-flight refresh watchdog.
- Improved license parsing compatibility for alternate output formats (email/plan/devices/renewal variants).
- Avoided clearing valid account metadata when license output is partial or transiently empty.
- Recorded last-command diagnostics even when connect preflight fails.
- Fixed popup load regression caused by unsupported `selectByMouse` on `DankTextField`.
- Updated PT-BR wording for the multiple default route warning: "rotas padrão".

### Changed

- Normalized Markdown table formatting in docs for cleaner lint output.

> **Full notes ->** [docs/releases/v1.3.1.md](./docs/releases/v1.3.1.md)

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

---

## Português (Brasil)

Todas as mudanças relevantes deste projeto são documentadas aqui. O inglês acima é a fonte primária; esta seção fornece a tradução PT-BR.

### [Não lançado]

### [1.3.4] - 2026-05-28

#### Corrigido

- Auto-connect no startup agora espera leituras iniciais de status e configuração antes de conectar, evitando que setups SOCKS sejam bloqueados pelo preflight TUN.
- Ativar Auto Connect depois do startup não dispara conexão imediata fora da janela de inicialização.
- O preflight de runtime agora desconecta usando o `adguardBinary` configurado.
- Quick-connect e favoritos por localização agora miram a linha específica cidade/país em vez de reduzir tudo ao ISO do país.
- Settings booleanas vindas como string agora tratam `"false"`, `"0"`, `"off"` e `"no"` corretamente.

#### Alterado

- Documentado o comportamento do preflight de conexão e adicionado check de i18n ao CI.

### [1.3.3] - 2026-04-22

#### Corrigido

- A checagem de múltiplas rotas default agora conta apenas rotas com a menor métrica.
- Interfaces virtuais são ignoradas para evitar falsos positivos com containers.

#### Adicionado

- Toggle **Bypass Multi-Route Check** em Settings → Advanced.

### [1.3.2] - 2026-04-12

#### Alterado

- Atualizados screenshots do README.
- Ajustada formatação da tabela de recursos.
- Removidos assets obsoletos.

### [1.3.1] - 2026-04-12

#### Corrigido

- Restaurada detecção de conta quando `adguardvpn-cli license` é lento.
- Melhorado parsing de licença para formatos alternativos.
- Evitado limpar metadados válidos em saídas parciais.
- Diagnóstico registra comando mesmo em falha de preflight.
- Corrigida regressão no popout causada por `selectByMouse` em `DankTextField`.
- Wording PT-BR atualizado para “rotas padrão”.

#### Alterado

- Normalizada formatação de tabelas Markdown.

### [1.3.0] - 2026-04-12

#### Adicionado

- Refresh completo da UI do popout e settings.
- Preflight de runtime antes de conectar.
- Checagem para múltiplas rotas default em modo TUN.
- Expansão multilíngue para 22 locales.
- Validador i18n ampliado para todos os locale files.

#### Corrigido

- Reduzidas falhas de conexão causadas por socket obsoleto ou runtime ocupado.
- Adicionados erros explícitos para runtime ocupado e múltiplas rotas default.

#### Alterado

- Terminologia PT-BR refinada.
- Documentação de localização define paridade estrita para `pt_BR` e fallback controlado nos demais locales.
- README documenta cobertura multilíngue.

### [1.2.0] - 2026-03-03

#### Adicionado

- Sistema de favoritos, busca/filtro de localizações, auto-connect, auto-reconnect, visualizador de log, histórico de comando, dicas contextuais, parsers dedicados, `buildArgs()`, controle de concorrência de polling, check i18n, CI e templates.

#### Corrigido

- Botão de favorito sem resposta por sobreposição de `MouseArea`.
- Removido código morto e retorno inalcançável.
- Corrigida contagem de camadas no documento de arquitetura.

#### Alterado

- Lista de localizações passou a conectar por ISO nesta versão histórica.
- Popout recebeu bordas, margens, scrollbar e altura de botão baseada em conteúdo.

### [1.1.0] — 2026-02-26

#### Adicionado

- Suporte multilíngue inicial (`en_US`, `pt_BR`), guia de tradução e screenshots.

#### Corrigido

- Falha ao habilitar plugin por wiring inválido do singleton i18n.
- Corrida de foco no campo DNS.
- Warning QML relacionado a `Ref` instável.

#### Alterado

- URLs de repositório e documentação de publicação refinadas.

### [1.0.0] — 2026-02-26

#### Adicionado

- Versão inicial do widget AdGuard VPN para DankMaterialShell.
- Monitoramento de status, config, licença e localizações.
- Ações de conectar, desconectar, mais rápida e localização.
- Controles de runtime para modo, protocolo, canal e DNS.
- Settings com polling e estratégia de conexão.
- Docs técnicas de arquitetura e comandos.
