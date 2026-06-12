# DONE — AdGuard VPN Plugin (DMS)

> Tarefas concluídas, movidas do `To-Do.md`. Revisão técnica original: 2026-06-11 (base v1.3.4).
> Tudo abaixo foi entregue na **v1.4.0** (2026-06-12) — commits `8841494` + `70c90a4`.

---

## P0 — Bugs

- [x] **Input de localização é apagado enquanto o usuário digita** — ✅ 2026-06-11 (v2): refatorado para `readonly property savedDefaultLocation` (binding reativo a `pluginData`) + seed por abertura de popout + sync externo só quando o campo não está focado. Elimina a corrida de init que deixava o campo vazio mesmo com padrão salvo (verificado visualmente via screenshot).
- [x] **Cascata pesada a cada save de setting** — ✅ 2026-06-11: `loadSettings()` só chama `restartTimers()` se `refreshIntervalSec`/`autoRefreshLocations` mudaram e `checkCliAvailability()` só se `adguardBinary` mudou (ou primeiro load).
- [x] **Fallback do parser de localização aceita palavras minúsculas como ISO** — ✅ 2026-06-11: removida flag `/i` de `plainIsoMatch`, `bracketIsoMatch` e `dashedMatch`; `tryColumns` valida maiúsculas antes do `toUpperCase()`.
- [x] **Timeout de comandos** — ✅ 2026-06-11: **descoberta**: assinatura real é `Proc.runCommand(id, cmd, cb, debounceMs, timeoutMs)` — o 4º arg que o plugin passava (`100`/`300`) era *debounce*, não timeout; tudo rodava com timeout default de 10s (exit 124). `runCli` agora passa debounce 0 + `timeoutMs` real: default 15s, `license` 30s, `disconnect` 30s, connects 60s (via `options.timeoutMs` no `runAction`). Exit 124 ganhou mensagem própria (`toast.command_timeout`, en+pt_BR). Bônus: `openTunnelLog` lança terminais blocking em background (`launch_bg` + `kill -0`) — antes o timeout de 10s matava o `sh` e gerava toast de erro falso com a janela de log aberta.

## P1 — Lógica

- [x] **Lista de localizações limitada a 8 itens sem indicação** — ✅ 2026-06-11: `locationsDisplayLimit` progressivo (8 inicial, +12 por clique em "Mostrar mais ({count} ocultas)"), reset ao mudar a busca; label "Showing X/Y" agora reporta o nº realmente renderizado.
- [x] **Auto-reconnect tenta uma única vez** — ✅ 2026-06-11: `reconnectPending` + backoff 5s/15s/45s (máx. 3 tentativas), toast de desistência (`toast.reconnect_giveup`); reset em sucesso ou disconnect manual.
- [x] **Polling sem backoff com CLI indisponível** — ✅ 2026-06-11: `statusPollIntervalMs()` — poll de recuperação a ≥30s enquanto `cliAvailable === false`, volta ao intervalo configurado via `onCliAvailableChanged`.
- [x] **`refreshAll` duplicado no startup** — ✅ 2026-06-11: Widget só chama `refreshAll(true)` se `AdGuardVpnService.lastRefreshMs` ainda for 0.
- [x] **Migração de favoritos legados nunca persiste** — ✅ 2026-06-11: `loadSettings()` grava `favoriteLocationTargets` quando migra de `favoriteLocationIsos`.
- [x] **Strings de estado não re-traduzem ao trocar idioma** — ✅ 2026-06-11 (mínimo): `Connections` no Service observa `AdGuardVpnI18n.normalizedLocale` e força `refreshStatus()` (ou re-traduz `status.cli_unavailable`). Ideal (chaves+params em binding) fica como refino futuro.

## P1 — UI/UX

- [x] **Acessibilidade zero nos botões** — ✅ 2026-06-11: `VpnActionButton`, cards de localização e estrela de favorito ganharam `activeFocusOnTab`, `Keys.onReturn/Enter/Space`, `Accessible.role/name/description` e borda de foco funcional.
- [x] **Estado "não logado" sem CTA** — ✅ 2026-06-11: `AdGuardVpnService.loginRequired` (setado pelo parse de `license`) + banner no hero com comando `{adguardBinary} login` e botão "Copiar comando" (`copyToClipboard` via `wl-copy`/`xclip`).
- [x] **Largura fixa de 140px no texto da barra** — ✅ 2026-06-11: `Math.min(implicitWidth, 140)`.
- [x] **Inputs inconsistentes** — ✅ 2026-06-11 (v2): busca e destino migrados para `DankTextField` (leftIconName, clear button na busca) e **empilhados em largura total** — o layout antigo de 2 colunas (`Column` + `Layout.fillWidth` + filhos `width: parent.width` dentro de `RowLayout`) colapsava a coluna da busca (campo invisível em produção, confirmado em screenshots antes/depois). Import `QtQuick.Controls` removido (não usado). Verificado visualmente: ambos os campos renderizam com ícone e placeholder.
- [x] **Dados parseados nunca exibidos** — ✅ 2026-06-11 (parcial): chips no hero para `tunnelInterface` (conectado) e `SOCKS host:port` (modo socks). `routingMode`/`changeSystemDns` ficam para uma futura seção Diagnostics.
- [x] **`Enter` não conecta** — ✅ 2026-06-11: `onAccepted` no campo destino dispara `connectToLocation`.
- [x] **Erro multi-linha cru no hero** — ✅ 2026-06-11: linha `DBG:` separada em `lastErrorDebug` (não exibida no hero); zerada no início de cada ação.
- [x] **`formatTimestamp` ignora idioma do plugin** — ✅ 2026-06-11: `toLocaleTimeString(Qt.locale(AdGuardVpnI18n.normalizedLocale), Locale.ShortFormat)`.
- [x] **Flickable `contentWidth` incoerente** — ✅ 2026-06-11: `contentWidth: width`; depois evoluído para `DankFlickable` (momentum + scrollbar overlay auto-hide) com canal reservado à direita para a scrollbar nunca cobrir conteúdo.
- [x] **Botão de protocolo "Autom..." truncado em pt-BR** — ✅ 2026-06-12: label literal "Auto" (achado na verificação visual).

## P2 — Melhorias

- [x] **Testes unitários dos parsers** — ✅ 2026-06-11: `scripts/test-parsers.mjs` (26 testes, sem dependências, carrega a lib via `node:vm`): status (4 formatos), license (3 variantes), config (parcial/clamp/fallback), locations (5 estratégias de coluna + emoji de bandeira), regressões do P0-3 (palavras minúsculas ≠ ISO). Integrado ao CI (`quality.yml`).

## P3 — Documentação

- [x] **README: tabela de settings desatualizada (EN e PT-BR)** — ✅ 2026-06-12: `bypassMultiRouteCheck` documentada nas duas tabelas.
- [x] **README: exemplo de publish com tag velha** — ✅ 2026-06-12: placeholder `vX.Y.Z`.
- [x] **README vendável** — ✅ 2026-06-12: capa nova (`docs/cover.png`, SVG autoral renderizado, tema navy+âmbar da UI), badges (CI, versão, DMS, i18n, testes, licença), `docs/screenshot.png` refeito com capturas reais do popout atual (2 painéis compostos com sombra/fundo on-brand), tabelas de features EN/PT atualizadas com acessibilidade, retry e testes.
- [x] **Documentar cap de exibição da lista / retry único** — ✅ obsoleto em 2026-06-12: o cap virou paginação "Mostrar mais" e o retry ganhou backoff — não há mais limitação a documentar.

## P3 — Infra

- [x] **CI: rodar testes de parser** — ✅ 2026-06-11: step "Run parser tests" no `quality.yml`.
- [x] **Release v1.4.0** — ✅ 2026-06-12: `plugin.json` 1.4.0, CHANGELOG (EN+PT), `docs/releases/v1.4.0.md`, tag `v1.4.0`, GitHub Release publicado, CI verde, registry validado (sem PR necessário — o registry não versiona; screenshot raw de `main` já propaga).

---

## Verificado e OK (sem ação) — auditoria 2026-06-11

- Paridade i18n: `check-i18n-keys.mjs` passa (base en.js, 22 locales; pt_BR com paridade estrita).
- Escapes bash em template literals JS (`openTunnelLog`, `prepareDisconnectedRuntime`) corretos conforme regra do projeto.
- Lógica multi-rota (menor métrica + filtro de interfaces virtuais + bypass toggle) consistente entre código, CHANGELOG v1.3.3 e COMMANDS.md.
- `connectToLocation` passa input do usuário como argv (sem shell) — sem injeção.
- Preflight usa `adguardBinary` configurado (fix v1.3.4 confirmado no código).
- Auto-connect no startup espera `startupStatusKnown && startupConfigKnown` (fix v1.3.4 confirmado).
- `asBool` trata strings `"false"/"0"/"off"/"no"` (fix v1.3.4 confirmado).
- Dependências de binding do `filteredLocations` capturam `favoriteLocationTargets` via `isFavoriteLocation` (QML rastreia leituras de propriedade dentro de funções chamadas no binding).
