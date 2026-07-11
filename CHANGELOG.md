# Changelog

All notable changes to this project are documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and [Semantic Versioning](https://semver.org/).

> **Language / Idioma:** English is primary. Portuguese (Brazil) translations are provided after the English changelog.

---

## [Unreleased]

## [1.5.1] - 2026-07-10

### Fixed

- Location-row quick connect now converts the internal `city, country` display/favorite key to the city accepted by `adguardvpn-cli`, fixing failed connections to every listed location.
- A systemd-managed tunnel reported as `VPN active, but status unavailable` with CLI exit code 10 is now treated as definitively connected instead of producing a false disconnected state.
- Connected status without location metadata now uses the CLI status line instead of rendering an empty `Connected ()` summary.

> **Full notes ->** [docs/releases/v1.5.1.md](./docs/releases/v1.5.1.md)

---

## [1.5.0] - 2026-07-10

### Added

- Ping badges in the location list are now color-coded (green/amber/red tiers) so latency is readable at a glance, not just as a number.
- DNS leak warning banner: when `adguardvpn-cli` reports "System DNS could not be configured" on connect/status, the popout now shows a persistent warning in the hero instead of staying silent about queries potentially bypassing the tunnel.
- Optional systemd-managed lifecycle mode can now be enabled directly in Settings → Advanced after installing the external control helper.

### Fixed

- Status parser no longer misreads a connected session as disconnected because of an auxiliary output line containing "disconnected"/"stopped" — the disconnect signal is now matched against the first line only, where every supported CLI status format already places it.
- `openTunnelLog` now guards against concurrent double-invocation (rapid double-click) with a dedicated `tunnelLogOpening` flag instead of being able to spawn duplicate terminals.
- Popout height is no longer a fixed `760`; it now clamps to the screen height (via `parentScreen`/`Screen`, same fallback the DMS `PluginComponent` uses internally) so it no longer overflows short displays (e.g. 768p with a bar).
- Connected location name display (`SãO PAULO`, an upstream `adguardvpn-cli` capitalization quirk) is now normalized to title case (`São Paulo`) in the bar pill and hero title.
- Popout height now honors the actual available screen space even when it is below the previous 420 px minimum.
- DNS leak warnings are translated in all 22 shipped locales.

### Security

- GitHub Actions are pinned to immutable commit SHAs and Markdown lint dependencies are locked with `npm ci --ignore-scripts`.
- Markdown lint now checks only tracked documentation, avoiding false failures from local operational files.

---

## [1.4.0] - 2026-06-12

### Added

- "Show more" button in the locations list: the previous hard cap of 8 visible entries now expands progressively (+12 per click) and the "Showing X/Y" counter reports what is actually rendered.
- Auto-reconnect now retries up to 3 times with 5 s / 15 s / 45 s backoff and reports when it gives up, instead of a single silent attempt.
- "Not logged in" banner in the popout with the exact `adguardvpn-cli login` command and a copy-to-clipboard button (`wl-copy`/`xclip`).
- Keyboard accessibility: action buttons, location cards, and favorite stars are now Tab-focusable, respond to Enter/Space, expose `Accessible` roles/names, and show a focus border.
- Hero chips for the active tunnel interface (TUN) and the SOCKS proxy endpoint (`host:port`) when in SOCKS mode.
- Pressing Enter in the "Direct destination" field connects to the typed location; Enter in the DNS field applies the upstream.
- Parser unit tests (`scripts/test-parsers.mjs`, 26 cases, zero dependencies) covering status/license/config/locations formats and ISO-code regressions, wired into CI.
- Popout scrolling now uses the shell's `DankFlickable` (smooth touchpad momentum, auto-hiding overlay scrollbar) with a reserved right-hand channel so the scrollbar never covers content.

### Changed

- README refreshed for registry listing: new cover banner (`docs/cover.png`), CI/version/i18n/tests badges, updated feature matrix, documented `bypassMultiRouteCheck`, and a new `docs/screenshot.png` composed from real captures of the current popout.
- Status polling backs off to at least 30 s while the CLI is unavailable, instead of spawning a failing process on every tick; the configured interval is restored as soon as the CLI responds again.
- Switching the plugin language now refreshes imperative state strings (status summary) immediately instead of waiting for the next poll.
- Legacy `favoriteLocationIsos` favorites are persisted to the new `favoriteLocationTargets` key on first load.

### Fixed

- Location input no longer gets wiped while typing: unrelated plugin-data saves (e.g. toggling a favorite) used to reset the "Direct destination" field to the saved default location.
- Saving any setting no longer restarts timers and re-runs the full CLI refresh cascade; timers restart only when `refreshIntervalSec`/`autoRefreshLocations` change and CLI availability is rechecked only when `adguardBinary` changes.
- Command timeouts now work as intended: the value previously passed to `Proc.runCommand` was the debounce delay, not the timeout, so every command was capped at the 10 s default. Connects now get 60 s, `disconnect`/`license` 30 s, reads 15 s, and timeouts (exit 124) surface a dedicated error message.
- Opening the tunnel log no longer reports a false failure after 10 s: blocking terminal emulators are launched in the background and considered successful when still alive shortly after spawn.
- Location parser fallback no longer treats lowercase two-letter words ("to", "in", "of") as ISO country codes.
- Removed the duplicate full refresh burst on startup (Service and Widget both triggered `refreshAll`).
- Locations search and direct-destination fields rendered collapsed/invisible because of `Layout.fillWidth` attached properties inside plain `Column` positioners; both now use full-width stacked `DankTextField`s (verified via screenshots).
- The direct-destination field no longer starts empty when a default location is saved: it now seeds from a reactive `pluginData` binding on every popout open instead of a one-shot copy that raced plugin-data loading.
- "Auto" protocol button no longer truncates ("Autom...") in pt-BR.
- Timestamps now follow the plugin language override instead of the system locale.
- Debug lines (`DBG:`) from the tunnel-log opener no longer leak into the hero error text (kept separately in `lastErrorDebug`).
- Bar text no longer reserves a fixed 140 px when showing short status like "Off".

> **Full notes ->** [docs/releases/v1.4.0.md](./docs/releases/v1.4.0.md)

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

### [1.5.1] - 2026-07-10

#### Corrigido

- A conexão rápida pelos cards agora converte a chave interna de exibição/favorito `cidade, país` para a cidade aceita pelo `adguardvpn-cli`, corrigindo a falha ao conectar em qualquer localização listada.
- Um túnel gerenciado pelo systemd reportado como `VPN active, but status unavailable` com código de saída 10 agora é reconhecido como conectado em vez de gerar um falso estado desconectado.
- O estado conectado sem metadados de localização agora usa a linha de status do CLI em vez de renderizar o resumo vazio `Conectado ()`.

> **Notas completas ->** [docs/releases/v1.5.1.md](./docs/releases/v1.5.1.md)

---

### [1.5.0] - 2026-07-10

#### Adicionado

- Badges de ping na lista de localizações agora têm cor por faixa (verde/âmbar/vermelho), permitindo avaliar a latência num relance, não só pelo número.
- Banner de vazamento de DNS: quando o `adguardvpn-cli` reporta "System DNS could not be configured" no connect/status, o popout agora mostra um aviso persistente no hero em vez de ficar em silêncio sobre consultas DNS que podem vazar para fora do túnel.
- O modo opcional de ciclo de vida gerenciado pelo systemd agora pode ser ativado diretamente em Configurações → Avançado após instalar o helper externo de controle.

#### Corrigido

- O parser de status não confunde mais uma sessão conectada com desconectada por causa de uma linha auxiliar contendo "disconnected"/"stopped" — o sinal de desconexão agora é testado só na primeira linha, onde todos os formatos suportados do CLI já colocam essa informação.
- `openTunnelLog` agora tem guard contra dupla invocação concorrente (clique duplo rápido) via flag dedicada `tunnelLogOpening`, em vez de poder lançar terminais duplicados.
- Altura do popout deixou de ser fixa em `760`; agora é clampada pela altura da tela (via `parentScreen`/`Screen`, mesmo fallback usado internamente pelo `PluginComponent` do DMS), eliminando o estouro em telas baixas (ex.: 768p com barra).
- Exibição do nome da localização conectada (`SãO PAULO`, quirk de capitalização do próprio `adguardvpn-cli`) agora é normalizada para title case (`São Paulo`) no pill da barra e no título do hero.
- A altura do popout agora respeita o espaço real disponível mesmo quando ele fica abaixo do mínimo anterior de 420 px.
- Os avisos de vazamento de DNS estão traduzidos nos 22 locales distribuídos.

#### Segurança

- As GitHub Actions estão fixadas em SHAs imutáveis e as dependências do lint Markdown estão travadas com `npm ci --ignore-scripts`.
- O lint Markdown agora verifica apenas documentação versionada, evitando falhas falsas causadas por arquivos operacionais locais.

### [1.4.0] - 2026-06-12

#### Adicionado

- Botão "Mostrar mais" na lista de localizações: o limite fixo de 8 entradas agora expande progressivamente (+12 por clique) e o contador "Mostrando X/Y" reflete o que está renderizado de fato.
- Reconexão automática agora tenta até 3 vezes com backoff de 5 s / 15 s / 45 s e avisa quando desiste, em vez de uma única tentativa silenciosa.
- Banner "Sessão não iniciada" no popout com o comando exato `adguardvpn-cli login` e botão de copiar (`wl-copy`/`xclip`).
- Acessibilidade de teclado: botões de ação, cards de localização e estrelas de favorito agora recebem foco por Tab, respondem a Enter/Espaço, expõem roles/nomes `Accessible` e mostram borda de foco.
- Chips no hero para a interface de túnel ativa (TUN) e o endpoint do proxy SOCKS (`host:porta`) no modo SOCKS.
- Pressionar Enter no campo "Destino direto" conecta à localização digitada; Enter no campo DNS aplica o upstream.
- Testes unitários dos parsers (`scripts/test-parsers.mjs`, 26 casos, zero dependências) cobrindo formatos de status/license/config/locations e regressões de código ISO, integrados ao CI.
- Scroll do popout agora usa o `DankFlickable` do shell (momentum suave de touchpad, scrollbar overlay com auto-hide) com canal reservado à direita para a scrollbar nunca cobrir o conteúdo.

#### Alterado

- README renovado para o registry: nova capa (`docs/cover.png`), badges de CI/versão/i18n/testes, matriz de recursos atualizada, `bypassMultiRouteCheck` documentada e novo `docs/screenshot.png` composto com capturas reais do popout atual.
- Polling de status recua para no mínimo 30 s enquanto o CLI está indisponível, em vez de criar um processo com falha a cada ciclo; o intervalo configurado volta assim que o CLI responde.
- Trocar o idioma do plugin agora atualiza imediatamente as strings de estado imperativas (resumo de status), sem esperar o próximo poll.
- Favoritos legados em `favoriteLocationIsos` são persistidos na chave nova `favoriteLocationTargets` no primeiro carregamento.

#### Corrigido

- Campo de localização não é mais apagado durante a digitação: saves não relacionados (ex.: favoritar) resetavam o campo "Destino direto" para a localização padrão salva.
- Salvar qualquer setting não reinicia mais os timers nem refaz a cascata completa de refresh do CLI; timers reiniciam apenas quando `refreshIntervalSec`/`autoRefreshLocations` mudam e a disponibilidade do CLI só é reverificada quando `adguardBinary` muda.
- Timeouts de comando agora funcionam de verdade: o valor passado ao `Proc.runCommand` era o debounce, não o timeout — todo comando ficava limitado aos 10 s padrão. Connects agora têm 60 s, `disconnect`/`license` 30 s, leituras 15 s, e timeout (exit 124) exibe mensagem dedicada.
- Abrir o log do túnel não reporta mais falha falsa após 10 s: terminais blocking são lançados em background e considerados sucesso se continuarem vivos logo após o spawn.
- Fallback do parser de localizações não trata mais palavras minúsculas de duas letras ("to", "in", "of") como códigos ISO de país.
- Removido o burst duplicado de refresh completo no startup (Service e Widget disparavam `refreshAll`).
- Campos de busca e destino direto renderizavam colapsados/invisíveis por causa de attached properties `Layout.fillWidth` dentro de `Column` puro; ambos agora são `DankTextField`s empilhados em largura total (verificado por screenshots).
- O campo de destino direto não inicia mais vazio quando há localização padrão salva: o seed agora vem de um binding reativo a `pluginData` a cada abertura do popout, em vez de uma cópia única que corria contra o carregamento dos dados.
- Botão de protocolo "Auto" não trunca mais ("Autom...") em pt-BR.
- Timestamps agora seguem o idioma configurado no plugin em vez do locale do sistema.
- Linhas de debug (`DBG:`) do abridor de log não vazam mais para o texto de erro do hero (mantidas em `lastErrorDebug`).
- Texto da barra não reserva mais 140 px fixos ao exibir status curto como "Off".

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
