# To-Do — AdGuard VPN Plugin (DMS)

> Revisão técnica completa em 2026-06-11 (base: v1.3.4, branch `main` limpa).
> Prioridades: **P0** = bug real / corrigir já · **P1** = lógica/UX importante · **P2** = melhoria · **P3** = docs/infra/polimento.

---

## P0 — Bugs

- [x] **Input de localização é apagado enquanto o usuário digita** — ✅ 2026-06-11 (v2): refatorado para `readonly property savedDefaultLocation` (binding reativo a `pluginData`) + seed por abertura de popout + sync externo só quando o campo não está focado. Elimina a corrida de init que deixava o campo vazio mesmo com padrão salvo (verificado visualmente via screenshot).
- [x] **Cascata pesada a cada save de setting** — ✅ 2026-06-11: `loadSettings()` só chama `restartTimers()` se `refreshIntervalSec`/`autoRefreshLocations` mudaram e `checkCliAvailability()` só se `adguardBinary` mudou (ou primeiro load).
- [x] **Fallback do parser de localização aceita palavras minúsculas como ISO** — ✅ 2026-06-11: removida flag `/i` de `plainIsoMatch`, `bracketIsoMatch` e `dashedMatch`; `tryColumns` valida maiúsculas antes do `toUpperCase()`.
- [x] **Timeout de comandos** — ✅ 2026-06-11: **descoberta**: assinatura real é `Proc.runCommand(id, cmd, cb, debounceMs, timeoutMs)` — o 4º arg que o plugin passava (`100`/`300`) era *debounce*, não timeout; tudo rodava com timeout default de 10s (exit 124). `runCli` agora passa debounce 0 + `timeoutMs` real: default 15s, `license` 30s, `disconnect` 30s, connects 60s (via `options.timeoutMs` no `runAction`). Exit 124 ganhou mensagem própria (`toast.command_timeout`, en+pt_BR). Bônus: `openTunnelLog` lança terminais blocking em background (`launch_bg` + `kill -0`) — antes o timeout de 10s matava o `sh` e gerava toast de erro falso com a janela de log aberta.

## P1 — Lógica

- [x] **Lista de localizações limitada a 8 itens sem indicação** — ✅ 2026-06-11: `locationsDisplayLimit` progressivo (8 inicial, +12 por clique em "Mostrar mais ({count} ocultas)"), reset ao mudar a busca; label "Showing X/Y" agora reporta o nº realmente renderizado.
- [ ] **Detecção de "disconnected" agressiva demais** — `AdGuardVpnParsers.js:34-35`: `disconnectPattern` testa o output inteiro; qualquer linha auxiliar contendo "disconnected"/"stopped" (ex.: aviso histórico do CLI) marca o estado como desconectado mesmo com a primeira linha "Connected to …". Restringir o teste do `fullOutput` a padrões mais específicos ou priorizar o match de connected na primeira linha antes do disconnect no full output.
- [x] **Auto-reconnect tenta uma única vez** — ✅ 2026-06-11: `reconnectPending` + backoff 5s/15s/45s (máx. 3 tentativas), toast de desistência (`toast.reconnect_giveup`); reset em sucesso ou disconnect manual.
- [x] **Polling sem backoff com CLI indisponível** — ✅ 2026-06-11: `statusPollIntervalMs()` — poll de recuperação a ≥30s enquanto `cliAvailable === false`, volta ao intervalo configurado via `onCliAvailableChanged`.
- [x] **`refreshAll` duplicado no startup** — ✅ 2026-06-11: Widget só chama `refreshAll(true)` se `AdGuardVpnService.lastRefreshMs` ainda for 0.
- [x] **Migração de favoritos legados nunca persiste** — ✅ 2026-06-11: `loadSettings()` grava `favoriteLocationTargets` quando migra de `favoriteLocationIsos`.
- [x] **Strings de estado não re-traduzem ao trocar idioma** — ✅ 2026-06-11 (mínimo): `Connections` no Service observa `AdGuardVpnI18n.normalizedLocale` e força `refreshStatus()` (ou re-traduz `status.cli_unavailable`). Ideal (chaves+params em binding) fica como refino futuro.
- [ ] **`openTunnelLog` roda fora do guard `commandRunning`** — pode rodar em paralelo com connect/disconnect (ambos via `Proc.runCommand`). Baixo risco, mas avaliar guard ou fila.

## P1 — UI/UX

- [x] **Acessibilidade zero nos botões** — ✅ 2026-06-11: `VpnActionButton`, cards de localização e estrela de favorito ganharam `activeFocusOnTab`, `Keys.onReturn/Enter/Space`, `Accessible.role/name/description` e borda de foco funcional.
- [x] **Estado "não logado" sem CTA** — ✅ 2026-06-11: `AdGuardVpnService.loginRequired` (setado pelo parse de `license`) + banner no hero com comando `{adguardBinary} login` e botão "Copiar comando" (`copyToClipboard` via `wl-copy`/`xclip`).
- [x] **Largura fixa de 140px no texto da barra** — ✅ 2026-06-11: `Math.min(implicitWidth, 140)`.
- [x] **Inputs inconsistentes** — ✅ 2026-06-11 (v2): busca e destino migrados para `DankTextField` (leftIconName, clear button na busca) e **empilhados em largura total** — o layout antigo de 2 colunas (`Column` + `Layout.fillWidth` + filhos `width: parent.width` dentro de `RowLayout`) colapsava a coluna da busca (campo invisível em produção, confirmado em screenshots antes/depois). Import `QtQuick.Controls` removido (não usado). Verificado visualmente: ambos os campos renderizam com ícone e placeholder.
- [x] **Dados parseados nunca exibidos** — ✅ 2026-06-11 (parcial): chips no hero para `tunnelInterface` (conectado) e `SOCKS host:port` (modo socks). `routingMode`/`changeSystemDns` ficam para uma futura seção Diagnostics.
- [x] **`Enter` não conecta** — ✅ 2026-06-11: `onAccepted` no campo destino dispara `connectToLocation`.
- [x] **Erro multi-linha cru no hero** — ✅ 2026-06-11: linha `DBG:` separada em `lastErrorDebug` (não exibida no hero); zerada no início de cada ação.
- [x] **`formatTimestamp` ignora idioma do plugin** — ✅ 2026-06-11: `toLocaleTimeString(Qt.locale(AdGuardVpnI18n.normalizedLocale), Locale.ShortFormat)`.
- [ ] **`popoutHeight: 760` fixo** — em telas baixas (768p com barra) estoura. Calcular: `Math.min(760, Screen.height - margens)` ou equivalente DMS. (Pendente: requer verificar como o DMS clampa popouts antes de mexer.)
- [x] **Flickable `contentWidth` incoerente** — ✅ 2026-06-11: `contentWidth: width`; ScrollBar padrão com `policy: AsNeeded`, sem margem negativa.

## P2 — Melhorias

- [x] **Testes unitários dos parsers** — ✅ 2026-06-11: `scripts/test-parsers.mjs` (26 testes, sem dependências, carrega a lib via `node:vm`): status (4 formatos), license (3 variantes), config (parcial/clamp/fallback), locations (5 estratégias de coluna + emoji de bandeira), regressões do P0-3 (palavras minúsculas ≠ ISO). Integrado ao CI (`quality.yml`).
- [ ] **Indicador visual de ping** — colorir o badge de ping (verde <80ms, amarelo <150, vermelho acima) nos cards de localização.
- [ ] **Confirmação/feedback de favoritos** — toast leve ou animação na estrela ao favoritar.
- [ ] **Copiar diagnóstico** — botão "copiar" no bloco Command output / last command.
- [ ] **Limpar 8 chaves i18n órfãs** — `summary.account`, `summary.mode_protocol_channel`, `summary.cli_last_sync`, `summary.last_command`, `summary.last_command_none`, `summary.last_command_output`, `section.quick_actions`, `locations.top_last_update` definidas em `en.js`/locales mas não usadas. (`action.favorite`/`action.unfavorite` foram reusadas como `Accessible.name` da estrela em 2026-06-11.)
- [ ] **Completar traduções dos locales estendidos** — 106-116 chaves em fallback EN por locale (saída do `check-i18n-keys.mjs`). Priorizar es_ES/fr_FR/de_DE.
- [ ] **Gerar lista de idiomas das Settings a partir de array** — `AdGuardVpnSettings.qml:92-191`: 23 opções hardcoded; gerar via `options: AdGuardVpnI18n.availableLocales.map(...)` e centralizar no I18n singleton.
- [ ] **Backoff/regulagem do `licenseRefresh`** — watchdog de 45s ok, mas considerar pular refresh de license quando popout fechado (telemetria desnecessária).
- [ ] **Banner de erro dismissível** — erros de connect somem no próximo poll bem-sucedido (~8s) porque `parseStatus` zera `lastError`; manter último erro de ação num banner fechável separado do erro de status.

## P3 — Documentação

- [x] **README: tabela de settings desatualizada (EN e PT-BR)** — ✅ 2026-06-12: `bypassMultiRouteCheck` documentada nas duas tabelas.
- [x] **README: exemplo de publish com tag velha** — ✅ 2026-06-12: placeholder `vX.Y.Z`.
- [x] **README vendável** — ✅ 2026-06-12: capa nova (`docs/cover.png`, SVG autoral renderizado, tema navy+âmbar da UI), badges (CI, versão, DMS, i18n, testes, licença), `docs/screenshot.png` refeito com capturas reais do popout v-atual (2 painéis compostos com sombra/fundo on-brand), tabelas de features EN/PT atualizadas com acessibilidade, retry e testes.
- [ ] **ARCHITECTURE.md: "four layers" vs tabela com 5 linhas** — o texto diz quatro camadas, a tabela lista UI/Settings/Service/Localization/Parsers (5). Alinhar (UI+Settings = camada de apresentação, ou assumir 5).
- [ ] **CHANGELOG: adicionar links de comparação** — Keep a Changelog recomenda `[1.3.4]: https://github.com/.../compare/v1.3.3...v1.3.4` no rodapé.
- [ ] **Documentar cap de exibição da lista de localizações** (ou remover o cap — ver P1) e o comportamento de retry único do auto-reconnect enquanto não evoluir.
- [ ] **docs/COMMANDS.md**: incluir `openTunnelLog` e `prepareDisconnectedRuntime` na tabela de operações (hoje só descritos em prosa) com seus exit codes (44/45, 42/43/44).

## P3 — Infra

- [ ] **CI: instalar formatador QML de forma determinística** — o loop `for pkg in ...` no `quality.yml` instala "o primeiro que der"; fixar `qt6-declarative-dev-tools` (Ubuntu 24.04) e falhar com mensagem clara se ausente, em vez de validação silenciosamente parcial.
- [ ] **CI: rodar futuros testes de parser** (depende do item P2).
- [ ] **Adicionar `qmllint` real ao validate-qml.sh** se disponível (sintaxe + warnings de binding), não só formatador.
- [ ] **Release v1.3.5/1.4.0** — agrupar P0+P1 num release; atualizar CHANGELOG (seção Unreleased está vazia), docs/releases/, e `plugin.json` version.

---

## Verificado e OK (sem ação)

- Paridade i18n: `check-i18n-keys.mjs` passa (base en.js, 22 locales; pt_BR com paridade estrita).
- Escapes bash em template literals JS (`openTunnelLog`, `prepareDisconnectedRuntime`) corretos conforme regra do projeto.
- Lógica multi-rota (menor métrica + filtro de interfaces virtuais + bypass toggle) consistente entre código, CHANGELOG v1.3.3 e COMMANDS.md.
- `connectToLocation` passa input do usuário como argv (sem shell) — sem injeção.
- Preflight usa `adguardBinary` configurado (fix v1.3.4 confirmado no código, linha 927).
- Auto-connect no startup espera `startupStatusKnown && startupConfigKnown` (fix v1.3.4 confirmado, linha 606).
- `asBool` trata strings `"false"/"0"/"off"/"no"` (fix v1.3.4 confirmado).
- Dependências de binding do `filteredLocations` capturam `favoriteLocationTargets` via `isFavoriteLocation` (QML rastreia leituras de propriedade dentro de funções chamadas no binding).
- `plugin.json` v1.3.4 = CHANGELOG mais recente = docs/releases/v1.3.4.md presentes.
