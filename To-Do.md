# To-Do — AdGuard VPN Plugin (DMS)

> Revisão técnica completa em 2026-06-11 (base: v1.3.4, branch `main` limpa).
> Prioridades: **P0** = bug real / corrigir já · **P1** = lógica/UX importante · **P2** = melhoria · **P3** = docs/infra/polimento.

---

## P1 — Lógica

- [ ] **Detecção de "disconnected" agressiva demais** — `AdGuardVpnParsers.js:34-35`: `disconnectPattern` testa o output inteiro; qualquer linha auxiliar contendo "disconnected"/"stopped" (ex.: aviso histórico do CLI) marca o estado como desconectado mesmo com a primeira linha "Connected to …". Restringir o teste do `fullOutput` a padrões mais específicos ou priorizar o match de connected na primeira linha antes do disconnect no full output.
- [ ] **`openTunnelLog` roda fora do guard `commandRunning`** — pode rodar em paralelo com connect/disconnect (ambos via `Proc.runCommand`). Baixo risco, mas avaliar guard ou fila.

## P1 — UI/UX

- [ ] **`popoutHeight: 760` fixo** — em telas baixas (768p com barra) estoura. Calcular: `Math.min(760, Screen.height - margens)` ou equivalente DMS. (Pendente: requer verificar como o DMS clampa popouts antes de mexer.)

## P2 — Melhorias

- [ ] **Indicador visual de ping** — colorir o badge de ping (verde <80ms, amarelo <150, vermelho acima) nos cards de localização.
- [ ] **Confirmação/feedback de favoritos** — toast leve ou animação na estrela ao favoritar.
- [ ] **Copiar diagnóstico** — botão "copiar" no bloco Command output / last command.
- [ ] **Limpar 8 chaves i18n órfãs** — `summary.account`, `summary.mode_protocol_channel`, `summary.cli_last_sync`, `summary.last_command`, `summary.last_command_none`, `summary.last_command_output`, `section.quick_actions`, `locations.top_last_update` definidas em `en.js`/locales mas não usadas. (`action.favorite`/`action.unfavorite` foram reusadas como `Accessible.name` da estrela em 2026-06-11.)
- [ ] **Completar traduções dos locales estendidos** — 106-116 chaves em fallback EN por locale (saída do `check-i18n-keys.mjs`). Priorizar es_ES/fr_FR/de_DE.
- [ ] **Gerar lista de idiomas das Settings a partir de array** — `AdGuardVpnSettings.qml:92-191`: 23 opções hardcoded; gerar via `options: AdGuardVpnI18n.availableLocales.map(...)` e centralizar no I18n singleton.
- [ ] **Backoff/regulagem do `licenseRefresh`** — watchdog de 45s ok, mas considerar pular refresh de license quando popout fechado (telemetria desnecessária).
- [ ] **Banner de erro dismissível** — erros de connect somem no próximo poll bem-sucedido (~8s) porque `parseStatus` zera `lastError`; manter último erro de ação num banner fechável separado do erro de status.

## P3 — Documentação

- [ ] **ARCHITECTURE.md: "four layers" vs tabela com 5 linhas** — o texto diz quatro camadas, a tabela lista UI/Settings/Service/Localization/Parsers (5). Alinhar (UI+Settings = camada de apresentação, ou assumir 5).
- [ ] **CHANGELOG: adicionar links de comparação** — Keep a Changelog recomenda `[1.3.4]: https://github.com/.../compare/v1.3.3...v1.3.4` no rodapé.
- [ ] **docs/COMMANDS.md**: incluir `openTunnelLog` e `prepareDisconnectedRuntime` na tabela de operações (hoje só descritos em prosa) com seus exit codes (44/45, 42/43/44).

## P3 — Infra

- [ ] **CI: instalar formatador QML de forma determinística** — o loop `for pkg in ...` no `quality.yml` instala "o primeiro que der"; fixar `qt6-declarative-dev-tools` (Ubuntu 24.04) e falhar com mensagem clara se ausente, em vez de validação silenciosamente parcial.
- [ ] **Adicionar `qmllint` real ao validate-qml.sh** se disponível (sintaxe + warnings de binding), não só formatador.

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
