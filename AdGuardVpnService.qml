pragma Singleton

import QtQuick
import Quickshell
import qs.Common
import qs.Services
import "./AdGuardVpnParsers.js" as AdGuardVpnParsers

Item {
    id: root

    readonly property string pluginId: "adguardVPplugin"

    readonly property var defaults: ({
            adguardBinary: "adguardvpn-cli",
            refreshIntervalSec: 8,
            locationsCount: 20,
            connectStrategy: "fastest",
            defaultLocation: "",
            ipStack: "auto",
            autoRefreshLocations: true,
            autoConnectOnStartup: false,
            autoReconnectOnDrop: false,
            favoriteLocationIsos: []
        })

    property string adguardBinary: defaults.adguardBinary
    property int refreshIntervalSec: defaults.refreshIntervalSec
    property int locationsCount: defaults.locationsCount
    property string connectStrategy: defaults.connectStrategy
    property string defaultLocation: defaults.defaultLocation
    property string ipStack: defaults.ipStack
    property bool autoRefreshLocations: defaults.autoRefreshLocations
    property bool autoConnectOnStartup: defaults.autoConnectOnStartup
    property bool autoReconnectOnDrop: defaults.autoReconnectOnDrop
    property var favoriteLocationIsos: defaults.favoriteLocationIsos
    property bool startupAutoConnectAttempted: false
    property bool suppressReconnectOnce: false

    property bool cliAvailable: false
    property string cliVersion: ""
    property bool commandRunning: false
    property string runningCommand: ""

    property bool isConnected: false
    property string statusSummary: AdGuardVpnI18n.tr("status.unknown", "Unknown")
    property string connectedLocation: ""
    property string connectedMode: ""
    property string tunnelInterface: ""

    property string accountEmail: ""
    property string accountTier: ""
    property int maxDevices: 0
    property string subscriptionRenewDate: ""

    property string currentMode: ""
    property string currentProtocol: "auto"
    property string currentProtocolRaw: ""
    property string currentUpdateChannel: "release"
    property string dnsUpstream: ""
    property string socksHost: ""
    property int socksPort: 1080
    property string routingMode: ""
    property bool changeSystemDns: false
    readonly property string tunnelLogPath: "$HOME/.local/share/adguardvpn-cli/tunnel.log"

    property var locations: []
    property string lastError: ""
    property string lastStatusRaw: ""
    property string lastConfigRaw: ""
    property string lastLicenseRaw: ""
    property string lastCommandText: ""
    property int lastCommandExitCode: -1
    property string lastCommandOutput: ""
    property double lastCommandAtMs: 0
    property var pollingSnapshot: ({
            status: false,
            metadata: false,
            locations: false
        })

    property double lastRefreshMs: 0
    property double lastLocationsRefreshMs: 0

    function t(key, fallback, params) {
        return AdGuardVpnI18n.tr(key, fallback, params);
    }

    function asInt(value, fallback, minimum, maximum) {
        var parsed = parseInt(value, 10);
        if (isNaN(parsed)) {
            parsed = fallback;
        }
        if (minimum !== undefined && parsed < minimum) {
            parsed = minimum;
        }
        if (maximum !== undefined && parsed > maximum) {
            parsed = maximum;
        }
        return parsed;
    }

    function asBool(value, fallback) {
        if (value === undefined || value === null) {
            return fallback;
        }
        return !!value;
    }

    function normalizedChoice(value, fallback, allowedValues) {
        var cleaned = (value || fallback || "").toString().toLowerCase().trim();
        if (allowedValues.indexOf(cleaned) >= 0) {
            return cleaned;
        }
        return fallback;
    }

    function stripAnsi(text) {
        return (text || "").replace(/\x1b\[[0-9;?]*[ -/]*[@-~]/g, "").replace(/\x1b[@-_]/g, "");
    }

    function cleanOutput(text) {
        return stripAnsi(text || "").replace(/\r/g, "").trim();
    }

    function normalizeFavoriteLocationIsos(value) {
        const list = [];
        const seen = ({});
        const source = Array.isArray(value) ? value : [];

        for (let i = 0; i < source.length; i++) {
            const iso = (source[i] || "").toString().trim().toUpperCase();
            if (!/^[A-Z]{2}$/.test(iso) || seen[iso]) {
                continue;
            }
            seen[iso] = true;
            list.push(iso);
        }

        return list;
    }

    function loadSettings() {
        const load = (key, defaultValue) => {
            const stored = PluginService.loadPluginData(pluginId, key);
            return stored !== undefined ? stored : defaultValue;
        };

        adguardBinary = (load("adguardBinary", defaults.adguardBinary) || defaults.adguardBinary).toString().trim();
        refreshIntervalSec = asInt(load("refreshIntervalSec", defaults.refreshIntervalSec), defaults.refreshIntervalSec, 3, 120);
        locationsCount = asInt(load("locationsCount", defaults.locationsCount), defaults.locationsCount, 5, 100);
        connectStrategy = normalizedChoice(load("connectStrategy", defaults.connectStrategy), defaults.connectStrategy, ["fastest", "location"]);
        defaultLocation = (load("defaultLocation", defaults.defaultLocation) || "").toString().trim();
        ipStack = normalizedChoice(load("ipStack", defaults.ipStack), defaults.ipStack, ["auto", "ipv4", "ipv6"]);
        autoRefreshLocations = asBool(load("autoRefreshLocations", defaults.autoRefreshLocations), defaults.autoRefreshLocations);
        autoConnectOnStartup = asBool(load("autoConnectOnStartup", defaults.autoConnectOnStartup), defaults.autoConnectOnStartup);
        autoReconnectOnDrop = asBool(load("autoReconnectOnDrop", defaults.autoReconnectOnDrop), defaults.autoReconnectOnDrop);
        favoriteLocationIsos = normalizeFavoriteLocationIsos(load("favoriteLocationIsos", defaults.favoriteLocationIsos));

        restartTimers();
        checkCliAvailability();
    }

    function saveSetting(key, value) {
        PluginService.savePluginData(pluginId, key, value);
    }

    function isFavoriteLocation(iso) {
        const normalizedIso = (iso || "").toString().trim().toUpperCase();
        if (!/^[A-Z]{2}$/.test(normalizedIso)) {
            return false;
        }
        return favoriteLocationIsos.indexOf(normalizedIso) >= 0;
    }

    function toggleFavoriteLocation(iso) {
        const normalizedIso = (iso || "").toString().trim().toUpperCase();
        if (!/^[A-Z]{2}$/.test(normalizedIso)) {
            return;
        }

        const next = favoriteLocationIsos.slice();
        const index = next.indexOf(normalizedIso);
        if (index >= 0) {
            next.splice(index, 1);
        } else {
            next.push(normalizedIso);
        }

        favoriteLocationIsos = normalizeFavoriteLocationIsos(next);
        saveSetting("favoriteLocationIsos", favoriteLocationIsos);
    }

    function restartTimers() {
        statusTimer.interval = refreshIntervalSec * 1000;
        metadataTimer.interval = Math.max(15, refreshIntervalSec * 3) * 1000;
        locationsTimer.interval = Math.max(30, refreshIntervalSec * 6) * 1000;

        if (!statusTimer.running) {
            statusTimer.start();
        }
        if (!metadataTimer.running) {
            metadataTimer.start();
        }
        locationsTimer.running = autoRefreshLocations;
        if (autoRefreshLocations) {
            locationsTimer.restart();
        }
    }

    function runCli(operation, args, callback) {
        const commandId = `${pluginId}.${operation}.${Date.now()}`;
        const command = [adguardBinary].concat(args || []);

        Proc.runCommand(commandId, command, (stdout, exitCode) => {
            callback(stdout || "", exitCode);
        }, 100);
    }

    function checkCliAvailability() {
        runCli("version", ["--version"], (stdout, exitCode) => {
            const clean = cleanOutput(stdout);
            cliAvailable = exitCode === 0;
            cliVersion = clean;

            if (!cliAvailable) {
                isConnected = false;
                statusSummary = t("status.cli_unavailable", "adguardvpn-cli unavailable");
                connectedLocation = "";
                connectedMode = "";
                tunnelInterface = "";
                lastError = clean || t("status.unable_run_cli", "Unable to run adguardvpn-cli");
                return;
            }

            lastError = "";
            refreshAll(true);
            maybeAutoConnectOnStartup();
        });
    }

    function parseStatus(stdout, exitCode) {
        const wasConnected = isConnected;
        const clean = cleanOutput(stdout);
        lastStatusRaw = clean;
        lastRefreshMs = Date.now();

        if (exitCode !== 0) {
            isConnected = false;
            statusSummary = clean || t("status.failed_read", "Failed to read VPN status");
            connectedLocation = "";
            connectedMode = "";
            tunnelInterface = "";
            lastError = statusSummary;
            maybeScheduleReconnect(wasConnected, isConnected);
            return;
        }

        cliAvailable = true;
        lastError = "";

        const parsed = AdGuardVpnParsers.parseStatusOutput(clean);
        if (parsed.empty) {
            isConnected = false;
            statusSummary = t("status.no_output", "No status output");
            connectedLocation = "";
            connectedMode = "";
            tunnelInterface = "";
            maybeScheduleReconnect(wasConnected, isConnected);
            return;
        }

        if (parsed.disconnected) {
            isConnected = false;
            statusSummary = t("status.disconnected", "Disconnected");
            connectedLocation = "";
            connectedMode = "";
            tunnelInterface = "";
            maybeScheduleReconnect(wasConnected, isConnected);
            return;
        }

        if (parsed.connected) {
            isConnected = true;
            connectedLocation = parsed.connectedLocation || "";
            connectedMode = parsed.connectedMode || "";
            tunnelInterface = parsed.tunnelInterface || "";
            statusSummary = t("status.connected", "Connected ({location})", {
                location: connectedLocation
            });
            maybeScheduleReconnect(wasConnected, isConnected);
            return;
        }

        isConnected = !!parsed.isConnected;
        statusSummary = parsed.firstLine || t("status.unknown", "Unknown");

        if (!isConnected) {
            connectedLocation = "";
            connectedMode = "";
            tunnelInterface = "";
        }

        maybeScheduleReconnect(wasConnected, isConnected);
    }

    function parseLicense(stdout, exitCode) {
        const clean = cleanOutput(stdout);
        lastLicenseRaw = clean;

        if (exitCode !== 0) {
            return;
        }

        const parsed = AdGuardVpnParsers.parseLicenseOutput(clean);
        accountEmail = parsed.accountEmail;
        accountTier = parsed.accountTier;
        maxDevices = parsed.maxDevices;
        subscriptionRenewDate = parsed.subscriptionRenewDate;
    }

    function parseConfig(stdout, exitCode) {
        const clean = cleanOutput(stdout);
        lastConfigRaw = clean;

        if (exitCode !== 0) {
            return;
        }

        const parsed = AdGuardVpnParsers.parseConfigOutput(clean, {
            currentMode: currentMode,
            currentProtocol: currentProtocol,
            currentProtocolRaw: currentProtocolRaw,
            currentUpdateChannel: currentUpdateChannel,
            dnsUpstream: dnsUpstream,
            socksHost: socksHost,
            socksPort: socksPort,
            routingMode: routingMode
        });

        currentMode = parsed.currentMode;
        currentProtocolRaw = parsed.currentProtocolRaw;
        currentProtocol = parsed.currentProtocol;
        currentUpdateChannel = parsed.currentUpdateChannel;
        dnsUpstream = parsed.dnsUpstream;
        socksHost = parsed.socksHost;
        socksPort = parsed.socksPort;
        routingMode = parsed.routingMode;
        changeSystemDns = parsed.changeSystemDns;
    }

    function buildLocationHelpHint(messageText) {
        const text = (messageText || "").toString();
        if (/no location with the specified city name, country name, or iso code/i.test(text) || /location not found/i.test(text)) {
            return t("hint.location_not_found", "Try refreshing locations and using the ISO code (e.g., BR).", {});
        }
        return "";
    }

    function parseLocations(stdout, exitCode) {
        const clean = cleanOutput(stdout);

        if (exitCode !== 0) {
            if (clean) {
                lastError = clean;
            }
            return;
        }

        const parsed = AdGuardVpnParsers.parseLocationsOutput(clean);

        if (parsed.parseFailed) {
            lastError = t("status.locations_parse_failed", "Could not parse locations list from CLI output");
        }

        locations = parsed.locations;
        lastLocationsRefreshMs = Date.now();
    }

    function refreshStatus() {
        if (!cliAvailable && !adguardBinary) {
            return;
        }

        runCli("status", ["status"], (stdout, exitCode) => {
            if (exitCode !== 0 && /not found|no such file|cannot execute/i.test(cleanOutput(stdout))) {
                cliAvailable = false;
                statusSummary = t("status.cli_unavailable", "adguardvpn-cli unavailable");
            }
            parseStatus(stdout, exitCode);
        });
    }

    function refreshConfig() {
        if (!cliAvailable) {
            return;
        }

        runCli("config", ["config", "show"], (stdout, exitCode) => {
            parseConfig(stdout, exitCode);
        });
    }

    function refreshLicense() {
        if (!cliAvailable) {
            return;
        }

        runCli("license", ["license"], (stdout, exitCode) => {
            parseLicense(stdout, exitCode);
        });
    }

    function refreshLocations() {
        if (!cliAvailable) {
            return;
        }

        runCli("locations", ["list-locations", locationsCount.toString()], (stdout, exitCode) => {
            parseLocations(stdout, exitCode);
        });
    }

    function refreshAll(includeLocations) {
        refreshStatus();
        refreshConfig();
        refreshLicense();

        if (includeLocations || autoRefreshLocations || locations.length === 0) {
            refreshLocations();
        }
    }

    function buildArgs(baseArgs, includeConnectFlags) {
        const args = (baseArgs || []).slice();
        if (includeConnectFlags) {
            args.push("-y");
            args.push("--no-progress");

            if (ipStack === "ipv4") {
                args.push("-4");
            } else if (ipStack === "ipv6") {
                args.push("-6");
            }
        }
        return args;
    }

    function suspendPolling() {
        pollingSnapshot = ({
                status: statusTimer.running,
                metadata: metadataTimer.running,
                locations: locationsTimer.running
            });

        statusTimer.stop();
        metadataTimer.stop();
        locationsTimer.stop();
    }

    function resumePolling() {
        if (pollingSnapshot.status) {
            statusTimer.start();
        }
        if (pollingSnapshot.metadata) {
            metadataTimer.start();
        }
        if (pollingSnapshot.locations && autoRefreshLocations) {
            locationsTimer.start();
        }
    }

    function recordLastCommand(args, exitCode, cleanOutputText) {
        const fullCommand = [adguardBinary].concat(args || []);
        const lines = (cleanOutputText || "").split("\n").map(line => line.trim()).filter(Boolean);

        lastCommandText = fullCommand.join(" ");
        lastCommandExitCode = exitCode;
        lastCommandOutput = lines.length ? lines[0] : "";
        lastCommandAtMs = Date.now();
    }

    function connectWithStrategy() {
        if (connectStrategy === "location" && defaultLocation) {
            connectToLocation(defaultLocation);
            return;
        }
        connectFastest();
    }

    function maybeAutoConnectOnStartup() {
        if (startupAutoConnectAttempted || !autoConnectOnStartup || !cliAvailable || commandRunning || isConnected) {
            return;
        }

        startupAutoConnectAttempted = true;
        connectWithStrategy();
    }

    function maybeScheduleReconnect(wasConnected, nowConnected) {
        if (nowConnected) {
            reconnectTimer.stop();
            suppressReconnectOnce = false;
            return;
        }

        if (suppressReconnectOnce) {
            suppressReconnectOnce = false;
            return;
        }

        if (!autoReconnectOnDrop || !wasConnected || !cliAvailable || commandRunning || reconnectTimer.running) {
            return;
        }

        ToastService.showInfo(t("app.title", "AdGuard VPN"), t("toast.reconnect_scheduled", "Connection dropped. Reconnecting..."));
        reconnectTimer.start();
    }

    function connectFastest() {
        const args = buildArgs(["connect", "-f"], true);

        runAction("connectFastest", args, t("app.title", "AdGuard VPN"), t("toast.fastest_selected", "Fastest location selected"));
    }

    function resolveLocationTarget(locationText) {
        const rawTarget = (locationText || "").toString().trim();
        if (!rawTarget) {
            return "";
        }

        const normalizedInput = rawTarget.toLowerCase();
        for (let i = 0; i < locations.length; i++) {
            const locationItem = locations[i];
            const iso = (locationItem.iso || "").toString().trim();
            const country = (locationItem.country || "").toString().trim();
            const city = (locationItem.city || "").toString().trim();

            const candidates = [iso, city, country, `${city}, ${country}`, `${country}, ${city}`].filter(Boolean);

            for (let c = 0; c < candidates.length; c++) {
                if (candidates[c].toLowerCase() === normalizedInput) {
                    return iso || rawTarget;
                }
            }
        }

        return rawTarget;
    }

    function connectToLocation(locationText) {
        const rawTarget = (locationText || "").toString().trim();
        if (!rawTarget) {
            ToastService.showError(t("app.title", "AdGuard VPN"), t("toast.location_empty", "Location is empty"));
            return;
        }

        const target = resolveLocationTarget(rawTarget);

        const args = buildArgs(["connect", "-l", target], true);

        runAction("connectLocation", args, t("app.title", "AdGuard VPN"), t("toast.connecting_to", "Connecting to {location}", {
            location: rawTarget
        }));
    }

    function disconnect() {
        suppressReconnectOnce = true;
        runAction("disconnect", ["disconnect"], t("app.title", "AdGuard VPN"), t("toast.disconnect_requested", "Disconnect requested"));
    }

    function toggleConnection() {
        if (isConnected) {
            disconnect();
        } else {
            connectWithStrategy();
        }
    }

    function setMode(mode) {
        const normalized = normalizedChoice(mode, "tun", ["tun", "socks"]);
        runAction("setMode", ["config", "set-mode", normalized], t("app.title", "AdGuard VPN"), t("toast.mode_set", "Mode set to {mode}", {
            mode: normalized.toUpperCase()
        }));
    }

    function setProtocol(protocol) {
        const normalized = normalizedChoice(protocol, "auto", ["auto", "http2", "quic"]);
        runAction("setProtocol", ["config", "set-protocol", normalized], t("app.title", "AdGuard VPN"), t("toast.protocol_set", "Protocol set to {protocol}", {
            protocol: normalized
        }));
    }

    function setUpdateChannel(channel) {
        const normalized = normalizedChoice(channel, "release", ["release", "beta", "nightly"]);
        runAction("setUpdateChannel", ["config", "set-update-channel", normalized], t("app.title", "AdGuard VPN"), t("toast.channel_set", "Channel set to {channel}", {
            channel: normalized
        }));
    }

    function setDns(upstream) {
        const normalized = (upstream || "").toString().trim();
        if (!normalized) {
            ToastService.showError(t("app.title", "AdGuard VPN"), t("toast.dns_empty", "DNS upstream cannot be empty"));
            return;
        }

        runAction("setDns", ["config", "set-dns", normalized], t("app.title", "AdGuard VPN"), t("toast.dns_set", "DNS set to {dns}", {
            dns: normalized
        }));
    }

    function openTunnelLog() {
        const openScript = `
            resolve_home() {
                if [ -n "$HOME" ]; then
                    printf '%s' "$HOME"
                    return
                fi
                getent passwd "$(id -u)" | cut -d: -f6
            }

            HOME_DIR="$(resolve_home)"
            TARGET=""

            for candidate in \
                "${tunnelLogPath}" \
                "$HOME_DIR/.local/share/adguardvpn-cli/tunnel.log" \
                "$HOME_DIR/.local/state/adguardvpn-cli/tunnel.log" \
                "$HOME_DIR/.cache/adguardvpn-cli/tunnel.log" \
                "$HOME_DIR/.cache/adguardvpn/tunnel.log"; do
                expanded="$candidate"
                case "$expanded" in
                    '$HOME'/*)
                        expanded="$HOME_DIR/\${expanded#'$HOME'/}"
                        ;;
                esac
                if [ -f "$expanded" ]; then
                    TARGET="$expanded"
                    break
                fi
            done

            [ -z "$TARGET" ] && exit 44

            LOG_CMD='printf "AdGuard VPN log: %s\\nCtrl+C para sair.\\n\\n" "$1"; tail -n 200 -f "$1"'

            if command -v kitty >/dev/null 2>&1; then
                if [ -n "$KITTY_LISTEN_ON" ]; then
                    kitty @ launch --type=window --title "AdGuard VPN Log" sh -lc "$LOG_CMD" sh "$TARGET" >/dev/null 2>&1 && exit 0
                fi
                kitty --title "AdGuard VPN Log" sh -lc "$LOG_CMD" sh "$TARGET" >/dev/null 2>&1 && exit 0
                printf 'DBG:kitty_failed rc=%s display=%s wayland=%s listen=%s\\n' "$?" "\${DISPLAY:-}" "\${WAYLAND_DISPLAY:-}" "\${KITTY_LISTEN_ON:-}"
            fi

            if command -v x-terminal-emulator >/dev/null 2>&1; then
                x-terminal-emulator -e sh -lc "$LOG_CMD" sh "$TARGET" >/dev/null 2>&1 && exit 0
            fi

            if command -v gnome-terminal >/dev/null 2>&1; then
                gnome-terminal -- sh -lc "$LOG_CMD" sh "$TARGET" >/dev/null 2>&1 && exit 0
            fi

            if command -v konsole >/dev/null 2>&1; then
                konsole -e sh -lc "$LOG_CMD" sh "$TARGET" >/dev/null 2>&1 && exit 0
            fi

            if command -v alacritty >/dev/null 2>&1; then
                alacritty -e sh -lc "$LOG_CMD" sh "$TARGET" >/dev/null 2>&1 && exit 0
            fi

            if command -v wezterm >/dev/null 2>&1; then
                wezterm start -- sh -lc "$LOG_CMD" sh "$TARGET" >/dev/null 2>&1 && exit 0
            fi

            if command -v xfce4-terminal >/dev/null 2>&1; then
                xfce4-terminal --hold -e "sh -lc '$LOG_CMD' sh '$TARGET'" >/dev/null 2>&1 && exit 0
            fi

            if command -v mate-terminal >/dev/null 2>&1; then
                mate-terminal -- sh -lc "$LOG_CMD" sh "$TARGET" >/dev/null 2>&1 && exit 0
            fi

            if command -v lxterminal >/dev/null 2>&1; then
                lxterminal -e "sh -lc '$LOG_CMD' sh '$TARGET'" >/dev/null 2>&1 && exit 0
            fi

            if command -v terminator >/dev/null 2>&1; then
                terminator -x sh -lc "$LOG_CMD" sh "$TARGET" >/dev/null 2>&1 && exit 0
            fi

            if command -v xdg-open >/dev/null 2>&1; then
                xdg-open "$TARGET" >/dev/null 2>&1 && exit 0
            fi

            if command -v gio >/dev/null 2>&1; then
                gio open "$TARGET" >/dev/null 2>&1 && exit 0
            fi

            if command -v code >/dev/null 2>&1; then
                code -r "$TARGET" >/dev/null 2>&1 && exit 0
            fi

            printf '%s\n%s\n%s' "$TARGET" "tail -n 200 -f '$TARGET'" "DBG:display=\${DISPLAY:-} wayland=\${WAYLAND_DISPLAY:-} xdg=\${XDG_SESSION_TYPE:-}"

            exit 45
        `;

        Proc.runCommand(`${pluginId}.openTunnelLog.${Date.now()}`, ["sh", "-lc", openScript], (stdout, exitCode) => {
            if (exitCode === 0) {
                ToastService.showInfo(t("app.title", "AdGuard VPN"), t("toast.log_opened", "Tunnel log opened"));
                return;
            }

            const missingLog = exitCode === 44;
            const openUnsupported = exitCode === 45;
            const outputLines = (cleanOutput(stdout) || "").split("\n").map(line => line.trim()).filter(Boolean);
            const resolvedPath = outputLines.length > 0 ? outputLines[0] : tunnelLogPath;
            const manualCommand = outputLines.length > 1 ? outputLines[1] : `tail -n 200 -f '${resolvedPath}'`;
            const debugLine = outputLines.length > 2 ? outputLines[2] : "";
            lastError = missingLog ? t("toast.log_missing", "Tunnel log file not found: {path}", {
                path: tunnelLogPath
            }) : (openUnsupported ? t("toast.log_open_unsupported", "Could not open a terminal/editor automatically. Log: {path}", {
                path: resolvedPath
            }) : t("toast.log_open_failed", "Failed to open tunnel log"));

            if (debugLine) {
                lastError = `${lastError}\n${debugLine}`;
            }

            ToastService.showError(t("app.title", "AdGuard VPN"), lastError);
            if (openUnsupported) {
                ToastService.showInfo(t("app.title", "AdGuard VPN"), t("toast.log_manual_command", "Run in terminal: {cmd}", {
                    cmd: manualCommand
                }));
            }
        }, 100);
    }

    function runAction(operation, args, toastTitle, toastMessage) {
        if (!cliAvailable) {
            ToastService.showError(t("app.title", "AdGuard VPN"), t("toast.cli_unavailable", "adguardvpn-cli is unavailable"));
            return;
        }

        if (commandRunning) {
            ToastService.showInfo(t("app.title", "AdGuard VPN"), t("toast.operation_running", "Another operation is running"));
            return;
        }

        commandRunning = true;
        runningCommand = operation;
        lastError = "";
        suspendPolling();

        runCli(operation, args, (stdout, exitCode) => {
            commandRunning = false;
            runningCommand = "";
            resumePolling();

            const clean = cleanOutput(stdout);
            recordLastCommand(args, exitCode, clean);
            if (exitCode === 0) {
                if (toastTitle) {
                    const firstLine = clean.split("\n").map(line => line.trim()).filter(Boolean)[0];
                    ToastService.showInfo(toastTitle, firstLine || toastMessage || t("toast.done", "Done"));
                }

                Qt.callLater(() => {
                    refreshStatus();
                    refreshConfig();
                    refreshLicense();
                });
                return;
            }

            lastError = clean || t("toast.operation_failed", "{operation} failed (code {code})", {
                operation: operation,
                code: exitCode
            });
            const hint = buildLocationHelpHint(lastError);
            if (hint) {
                lastError = `${lastError}\n${hint}`;
            }
            ToastService.showError(t("app.title", "AdGuard VPN"), lastError);
            refreshStatus();
        });
    }

    Timer {
        id: statusTimer
        interval: 8000
        running: false
        repeat: true
        onTriggered: root.refreshStatus()
    }

    Timer {
        id: metadataTimer
        interval: 30000
        running: false
        repeat: true
        onTriggered: {
            root.refreshConfig();
            root.refreshLicense();
        }
    }

    Timer {
        id: locationsTimer
        interval: 60000
        running: false
        repeat: true
        onTriggered: root.refreshLocations()
    }

    Timer {
        id: reconnectTimer
        interval: 5000
        running: false
        repeat: false
        onTriggered: {
            if (!root.isConnected && root.autoReconnectOnDrop && root.cliAvailable && !root.commandRunning) {
                root.connectWithStrategy();
            }
        }
    }

    Connections {
        target: PluginService
        function onPluginDataChanged(changedPluginId) {
            if (changedPluginId === root.pluginId) {
                loadSettings();
            }
        }
    }

    Component.onCompleted: {
        loadSettings();
    }
}
