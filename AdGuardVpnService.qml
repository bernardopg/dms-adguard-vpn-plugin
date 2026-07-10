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
            useSystemdService: false,
            favoriteLocationTargets: [],
            bypassMultiRouteCheck: false
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
    property bool useSystemdService: defaults.useSystemdService
    property var favoriteLocationTargets: defaults.favoriteLocationTargets
    property bool bypassMultiRouteCheck: defaults.bypassMultiRouteCheck
    property bool initialSettingsLoaded: false
    property bool startupAutoConnectAttempted: false
    property bool startupAutoConnectEnabled: false
    property bool startupStatusKnown: false
    property bool startupConfigKnown: false
    property bool suppressReconnectOnce: false
    property bool reconnectPending: false
    property int reconnectAttempts: 0
    readonly property var reconnectDelaysMs: [5000, 15000, 45000]

    property bool cliAvailable: false
    property string cliVersion: ""
    property bool commandRunning: false
    property string runningCommand: ""
    property bool tunnelLogOpening: false

    property bool isConnected: false
    property string statusSummary: AdGuardVpnI18n.tr("status.unknown", "Unknown")
    property string connectedLocation: ""
    property string connectedMode: ""
    property string tunnelInterface: ""
    property bool dnsWarning: false

    property string accountEmail: ""
    property string accountTier: ""
    property int maxDevices: 0
    property string subscriptionRenewDate: ""
    property bool loginRequired: false

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
    readonly property string controlSocketPath: "$HOME/.local/share/adguardvpn-cli/vpn.socket"

    property var locations: []
    property string lastError: ""
    property string lastErrorDebug: ""
    property string lastStatusRaw: ""
    property string lastConfigRaw: ""
    property string lastLicenseRaw: ""
    property string lastCommandText: ""
    property int lastCommandExitCode: -1
    property string lastCommandOutput: ""
    property double lastCommandAtMs: 0
    property bool licenseRefreshInFlight: false
    property double licenseRefreshStartedAtMs: 0
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
        if (typeof value === "boolean") {
            return value;
        }
        if (typeof value === "string") {
            const cleaned = value.toLowerCase().trim();
            if (["true", "1", "yes", "on"].indexOf(cleaned) >= 0) {
                return true;
            }
            if (["false", "0", "no", "off"].indexOf(cleaned) >= 0) {
                return false;
            }
            return fallback;
        }
        if (typeof value === "number") {
            return value !== 0;
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

    function normalizeLocationTarget(value) {
        const text = (value || "").toString().replace(/\s+/g, " ").trim();
        if (/^[A-Z]{2}$/i.test(text)) {
            return text.toUpperCase();
        }
        return text;
    }

    function locationTarget(locationItem) {
        const item = locationItem || {};
        const iso = normalizeLocationTarget(item.iso || "");
        const country = normalizeLocationTarget(item.country || "");
        const city = normalizeLocationTarget(item.city || "");

        if (city && country) {
            return `${city}, ${country}`;
        }
        return city || country || iso;
    }

    function normalizeFavoriteLocationTargets(value) {
        const list = [];
        const seen = ({});
        const source = Array.isArray(value) ? value : [];

        for (let i = 0; i < source.length; i++) {
            const target = normalizeLocationTarget(source[i]);
            const key = target.toLowerCase();
            if (!target || target.length > 120 || seen[key]) {
                continue;
            }
            seen[key] = true;
            list.push(target);
        }

        return list;
    }

    function loadSettings() {
        const load = (key, defaultValue) => {
            const stored = PluginService.loadPluginData(pluginId, key);
            return stored !== undefined ? stored : defaultValue;
        };

        const firstLoad = !initialSettingsLoaded;
        const previousBinary = adguardBinary;
        const previousRefreshIntervalSec = refreshIntervalSec;
        const previousAutoRefreshLocations = autoRefreshLocations;

        adguardBinary = (load("adguardBinary", defaults.adguardBinary) || defaults.adguardBinary).toString().trim();
        refreshIntervalSec = asInt(load("refreshIntervalSec", defaults.refreshIntervalSec), defaults.refreshIntervalSec, 3, 120);
        locationsCount = asInt(load("locationsCount", defaults.locationsCount), defaults.locationsCount, 5, 100);
        connectStrategy = normalizedChoice(load("connectStrategy", defaults.connectStrategy), defaults.connectStrategy, ["fastest", "location"]);
        defaultLocation = (load("defaultLocation", defaults.defaultLocation) || "").toString().trim();
        ipStack = normalizedChoice(load("ipStack", defaults.ipStack), defaults.ipStack, ["auto", "ipv4", "ipv6"]);
        autoRefreshLocations = asBool(load("autoRefreshLocations", defaults.autoRefreshLocations), defaults.autoRefreshLocations);
        autoConnectOnStartup = asBool(load("autoConnectOnStartup", defaults.autoConnectOnStartup), defaults.autoConnectOnStartup);
        autoReconnectOnDrop = asBool(load("autoReconnectOnDrop", defaults.autoReconnectOnDrop), defaults.autoReconnectOnDrop);
        useSystemdService = asBool(load("useSystemdService", defaults.useSystemdService), defaults.useSystemdService);
        const storedFavoriteTargets = PluginService.loadPluginData(pluginId, "favoriteLocationTargets");
        const legacyFavoriteIsos = PluginService.loadPluginData(pluginId, "favoriteLocationIsos");
        const favoriteSource = storedFavoriteTargets !== undefined && storedFavoriteTargets !== null ? storedFavoriteTargets : (legacyFavoriteIsos !== undefined && legacyFavoriteIsos !== null ? legacyFavoriteIsos : defaults.favoriteLocationTargets);
        favoriteLocationTargets = normalizeFavoriteLocationTargets(favoriteSource);
        if ((storedFavoriteTargets === undefined || storedFavoriteTargets === null) && legacyFavoriteIsos !== undefined && legacyFavoriteIsos !== null) {
            saveSetting("favoriteLocationTargets", favoriteLocationTargets);
        }
        bypassMultiRouteCheck = asBool(load("bypassMultiRouteCheck", defaults.bypassMultiRouteCheck), defaults.bypassMultiRouteCheck);

        if (!initialSettingsLoaded) {
            startupAutoConnectEnabled = autoConnectOnStartup;
            initialSettingsLoaded = true;
        }

        if (firstLoad || refreshIntervalSec !== previousRefreshIntervalSec || autoRefreshLocations !== previousAutoRefreshLocations) {
            restartTimers();
        }
        if (firstLoad || adguardBinary !== previousBinary) {
            checkCliAvailability();
        }
    }

    function saveSetting(key, value) {
        PluginService.savePluginData(pluginId, key, value);
    }

    function isFavoriteLocation(locationItem) {
        const target = locationTarget(locationItem);
        const iso = normalizeLocationTarget((locationItem || {}).iso || "");
        if (!target && !iso) {
            return false;
        }

        const targetKey = target.toLowerCase();
        const isoKey = iso.toLowerCase();
        for (let i = 0; i < favoriteLocationTargets.length; i++) {
            const favoriteKey = normalizeLocationTarget(favoriteLocationTargets[i]).toLowerCase();
            if (favoriteKey === targetKey || (isoKey && favoriteKey === isoKey)) {
                return true;
            }
        }
        return false;
    }

    function toggleFavoriteLocation(locationItem) {
        const target = locationTarget(locationItem);
        const iso = normalizeLocationTarget((locationItem || {}).iso || "");
        if (!target) {
            return;
        }

        const next = favoriteLocationTargets.slice();
        const targetKey = target.toLowerCase();
        const isoKey = iso.toLowerCase();
        let index = -1;

        for (let i = 0; i < next.length; i++) {
            const favoriteKey = normalizeLocationTarget(next[i]).toLowerCase();
            if (favoriteKey === targetKey || (isoKey && favoriteKey === isoKey)) {
                index = i;
                break;
            }
        }

        if (index >= 0) {
            next.splice(index, 1);
        } else {
            next.push(target);
        }

        favoriteLocationTargets = normalizeFavoriteLocationTargets(next);
        saveSetting("favoriteLocationTargets", favoriteLocationTargets);
    }

    // Back off the status poll while the CLI is missing: the recovery probe
    // still runs, but at >=30 s instead of spawning a failing process every tick.
    function statusPollIntervalMs() {
        const seconds = cliAvailable ? refreshIntervalSec : Math.max(refreshIntervalSec, 30);
        return seconds * 1000;
    }

    onCliAvailableChanged: {
        statusTimer.interval = statusPollIntervalMs();
    }

    function restartTimers() {
        statusTimer.interval = statusPollIntervalMs();
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

    // Proc.runCommand signature: (id, command, callback, debounceMs, timeoutMs).
    // Command ids are unique per call, so debounce is useless here — always 0.
    function isServiceLifecycleOperation(operation) {
        return operation === "connectFastest" || operation === "connectLocation" || operation === "disconnect";
    }

    function serviceLifecycleCommand(operation, args) {
        if (!useSystemdService) {
            return null;
        }

        const control = ["sudo", "-n", "/usr/local/sbin/adguardvpn-dms-control"];

        if (operation === "connectFastest") {
            return control.concat(["connect-fastest"]);
        }
        if (operation === "connectLocation") {
            const locationIndex = args.indexOf("-l");
            const location = locationIndex >= 0 ? args[locationIndex + 1] : "";
            return control.concat(["connect-location", location]);
        }
        if (operation === "disconnect") {
            return control.concat(["disconnect"]);
        }
        return null;
    }

    function runCli(operation, args, callback, timeoutMs) {
        const commandId = `${pluginId}.${operation}.${Date.now()}`;
        const lifecycleCommand = isServiceLifecycleOperation(operation) ? serviceLifecycleCommand(operation, args || []) : null;
        const command = lifecycleCommand || [adguardBinary].concat(args || []);
        const timeoutValue = timeoutMs !== undefined && timeoutMs !== null ? timeoutMs : 15000;

        Proc.runCommand(commandId, command, (stdout, exitCode) => {
            callback(stdout || "", exitCode);
        }, 0, timeoutValue);
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
        });
    }

    function parseStatus(stdout, exitCode) {
        const wasConnected = isConnected;
        const clean = cleanOutput(stdout);
        lastStatusRaw = clean;
        lastRefreshMs = Date.now();
        startupStatusKnown = exitCode === 0;

        if (exitCode !== 0) {
            isConnected = false;
            statusSummary = clean || t("status.failed_read", "Failed to read VPN status");
            connectedLocation = "";
            connectedMode = "";
            tunnelInterface = "";
            dnsWarning = false;
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
            dnsWarning = false;
            maybeScheduleReconnect(wasConnected, isConnected);
            return;
        }

        if (parsed.disconnected) {
            isConnected = false;
            statusSummary = t("status.disconnected", "Disconnected");
            connectedLocation = "";
            connectedMode = "";
            tunnelInterface = "";
            dnsWarning = false;
            maybeScheduleReconnect(wasConnected, isConnected);
            return;
        }

        if (parsed.connected) {
            isConnected = true;
            connectedLocation = parsed.connectedLocation || "";
            connectedMode = parsed.connectedMode || "";
            tunnelInterface = parsed.tunnelInterface || "";
            dnsWarning = !!parsed.dnsWarning;
            statusSummary = t("status.connected", "Connected ({location})", {
                location: connectedLocation
            });
            if (!accountEmail && !licenseRefreshInFlight) {
                refreshLicense();
            }
            maybeScheduleReconnect(wasConnected, isConnected);
            return;
        }

        isConnected = !!parsed.isConnected;
        statusSummary = parsed.firstLine || t("status.unknown", "Unknown");
        dnsWarning = isConnected ? !!parsed.dnsWarning : false;

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

        if (/not\s+logged\s+in|login\s+required|not\s+authorized/i.test(clean)) {
            accountEmail = "";
            accountTier = "";
            maxDevices = 0;
            subscriptionRenewDate = "";
            loginRequired = true;
            return;
        }

        if (exitCode !== 0 && !clean) {
            return;
        }

        const parsed = AdGuardVpnParsers.parseLicenseOutput(clean);
        if (parsed.accountEmail) {
            accountEmail = parsed.accountEmail;
            loginRequired = false;
        }
        if (parsed.accountTier) {
            accountTier = parsed.accountTier;
        }
        if (parsed.maxDevices > 0) {
            maxDevices = parsed.maxDevices;
        }
        if (parsed.subscriptionRenewDate) {
            subscriptionRenewDate = parsed.subscriptionRenewDate;
        }
    }

    function parseConfig(stdout, exitCode) {
        const clean = cleanOutput(stdout);
        lastConfigRaw = clean;

        if (exitCode !== 0) {
            return;
        }

        startupConfigKnown = true;

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
            maybeAutoConnectOnStartup();
        });
    }

    function refreshConfig() {
        if (!cliAvailable) {
            return;
        }

        runCli("config", ["config", "show"], (stdout, exitCode) => {
            parseConfig(stdout, exitCode);
            maybeAutoConnectOnStartup();
        });
    }

    function refreshLicense() {
        if (!cliAvailable) {
            return;
        }

        const now = Date.now();
        if (licenseRefreshInFlight) {
            if ((now - licenseRefreshStartedAtMs) < 45000) {
                return;
            }
            licenseRefreshInFlight = false;
            licenseRefreshStartedAtMs = 0;
        }

        licenseRefreshInFlight = true;
        licenseRefreshStartedAtMs = now;
        runCli("license", ["license"], (stdout, exitCode) => {
            parseLicense(stdout, exitCode);
            licenseRefreshInFlight = false;
            licenseRefreshStartedAtMs = 0;
        }, 30000);
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
        if (startupAutoConnectAttempted || !startupAutoConnectEnabled || !autoConnectOnStartup || !startupStatusKnown || !startupConfigKnown || !cliAvailable || commandRunning || isConnected) {
            return;
        }

        startupAutoConnectAttempted = true;
        connectWithStrategy();
    }

    function maybeScheduleReconnect(wasConnected, nowConnected) {
        if (nowConnected) {
            reconnectTimer.stop();
            suppressReconnectOnce = false;
            reconnectPending = false;
            reconnectAttempts = 0;
            return;
        }

        if (suppressReconnectOnce) {
            suppressReconnectOnce = false;
            reconnectPending = false;
            reconnectAttempts = 0;
            return;
        }

        if (!autoReconnectOnDrop || !cliAvailable || commandRunning || reconnectTimer.running) {
            return;
        }

        if (wasConnected) {
            reconnectPending = true;
            reconnectAttempts = 0;
            ToastService.showInfo(t("app.title", "AdGuard VPN"), t("toast.reconnect_scheduled", "Connection dropped. Reconnecting..."));
        }

        if (!reconnectPending) {
            return;
        }

        if (reconnectAttempts >= reconnectDelaysMs.length) {
            reconnectPending = false;
            ToastService.showError(t("app.title", "AdGuard VPN"), t("toast.reconnect_giveup", "Auto-reconnect gave up after {count} attempts", {
                count: reconnectDelaysMs.length
            }));
            return;
        }

        reconnectTimer.interval = reconnectDelaysMs[reconnectAttempts];
        reconnectTimer.start();
    }

    function connectFastest() {
        const args = buildArgs(["connect", "-f"], true);

        runAction("connectFastest", args, t("app.title", "AdGuard VPN"), t("toast.fastest_selected", "Fastest location selected"), {
            prepareDisconnectedRuntime: true,
            timeoutMs: 60000
        });
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

            if (iso && iso.toLowerCase() === normalizedInput) {
                return iso;
            }
            if (city && city.toLowerCase() === normalizedInput) {
                return locationTarget(locationItem) || rawTarget;
            }
            if (city && country && `${city}, ${country}`.toLowerCase() === normalizedInput) {
                return locationTarget(locationItem) || rawTarget;
            }
            if (city && country && `${country}, ${city}`.toLowerCase() === normalizedInput) {
                return locationTarget(locationItem) || rawTarget;
            }
            if (country && country.toLowerCase() === normalizedInput) {
                return country;
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
        }), {
            prepareDisconnectedRuntime: true,
            timeoutMs: 60000
        });
    }

    function disconnect() {
        suppressReconnectOnce = true;
        runAction("disconnect", ["disconnect"], t("app.title", "AdGuard VPN"), t("toast.disconnect_requested", "Disconnect requested"), {
            timeoutMs: 30000
        });
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
        if (tunnelLogOpening) {
            ToastService.showInfo(t("app.title", "AdGuard VPN"), t("toast.log_opening", "Opening tunnel log..."));
            return;
        }
        tunnelLogOpening = true;

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

            # Terminals block until their window closes. Launch in background and
            # treat "still alive shortly after spawn" as success, so the plugin's
            # command timeout never kills an open log window.
            launch_bg() {
                "$@" >/dev/null 2>&1 &
                _BG_PID=$!
                sleep 0.3
                kill -0 "$_BG_PID" 2>/dev/null
            }

            if command -v kitty >/dev/null 2>&1; then
                if [ -n "$KITTY_LISTEN_ON" ]; then
                    kitty @ launch --type=window --title "AdGuard VPN Log" sh -lc "$LOG_CMD" sh "$TARGET" >/dev/null 2>&1 && exit 0
                fi
                launch_bg kitty --title "AdGuard VPN Log" sh -lc "$LOG_CMD" sh "$TARGET" && exit 0
                printf 'DBG:kitty_failed display=%s wayland=%s listen=%s\\n' "\${DISPLAY:-}" "\${WAYLAND_DISPLAY:-}" "\${KITTY_LISTEN_ON:-}"
            fi

            if command -v x-terminal-emulator >/dev/null 2>&1; then
                launch_bg x-terminal-emulator -e sh -lc "$LOG_CMD" sh "$TARGET" && exit 0
            fi

            if command -v gnome-terminal >/dev/null 2>&1; then
                gnome-terminal -- sh -lc "$LOG_CMD" sh "$TARGET" >/dev/null 2>&1 && exit 0
            fi

            if command -v konsole >/dev/null 2>&1; then
                launch_bg konsole -e sh -lc "$LOG_CMD" sh "$TARGET" && exit 0
            fi

            if command -v alacritty >/dev/null 2>&1; then
                launch_bg alacritty -e sh -lc "$LOG_CMD" sh "$TARGET" && exit 0
            fi

            if command -v wezterm >/dev/null 2>&1; then
                launch_bg wezterm start -- sh -lc "$LOG_CMD" sh "$TARGET" && exit 0
            fi

            if command -v xfce4-terminal >/dev/null 2>&1; then
                launch_bg xfce4-terminal --hold -e "sh -lc '$LOG_CMD' sh '$TARGET'" && exit 0
            fi

            if command -v mate-terminal >/dev/null 2>&1; then
                launch_bg mate-terminal -- sh -lc "$LOG_CMD" sh "$TARGET" && exit 0
            fi

            if command -v lxterminal >/dev/null 2>&1; then
                launch_bg lxterminal -e "sh -lc '$LOG_CMD' sh '$TARGET'" && exit 0
            fi

            if command -v terminator >/dev/null 2>&1; then
                launch_bg terminator -x sh -lc "$LOG_CMD" sh "$TARGET" && exit 0
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
            tunnelLogOpening = false;
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

            lastErrorDebug = debugLine;

            ToastService.showError(t("app.title", "AdGuard VPN"), lastError);
            if (openUnsupported) {
                ToastService.showInfo(t("app.title", "AdGuard VPN"), t("toast.log_manual_command", "Run in terminal: {cmd}", {
                    cmd: manualCommand
                }));
            }
        }, 0, 15000);
    }

    function copyToClipboard(text) {
        const value = (text || "").toString();
        if (!value) {
            return;
        }

        const copyScript = 'printf %s "$1" | wl-copy 2>/dev/null || printf %s "$1" | xclip -selection clipboard 2>/dev/null';
        Proc.runCommand(`${pluginId}.copy.${Date.now()}`, ["sh", "-c", copyScript, "sh", value], (stdout, exitCode) => {
            if (exitCode === 0) {
                ToastService.showInfo(t("app.title", "AdGuard VPN"), t("toast.copied", "Copied: {text}", {
                    text: value
                }));
            } else {
                ToastService.showError(t("app.title", "AdGuard VPN"), t("toast.copy_failed", "Could not copy to clipboard"));
            }
        }, 0, 5000);
    }

    function prepareDisconnectedRuntime(callback) {
        const tunPreflightRequired = (currentMode || "").toString().toLowerCase() !== "socks";
        const prepScript = `
            CLI_BIN="$1"

            resolve_home() {
                if [ -n "$HOME" ]; then
                    printf '%s' "$HOME"
                    return
                fi
                getent passwd "$(id -u)" | cut -d: -f6
            }

            HOME_DIR="$(resolve_home)"
            SOCKET_PATH="${controlSocketPath}"
            case "$SOCKET_PATH" in
                '$HOME'/*)
                    SOCKET_PATH="$HOME_DIR/\${SOCKET_PATH#'$HOME'/}"
                    ;;
            esac

            if [ "${tunPreflightRequired ? "1" : "0"}" = "1" ] && [ "${bypassMultiRouteCheck ? "1" : "0"}" = "0" ] && command -v ip >/dev/null 2>&1; then
                _ROUTES="$(ip -o route show to default)"
                _MIN_MET="$(printf '%s\n' "$_ROUTES" | awk '{m="0"; for(i=1;i<=NF;i++){if($i=="metric"){m=$(i+1);break}}; print m+0}' | sort -n | head -1)"
                DEFAULT_ROUTE_COUNT="$(printf '%s\n' "$_ROUTES" | awk -v minm="$_MIN_MET" '{iface=""; m="0"; for(i=1;i<=NF;i++){if($i=="dev") iface=$(i+1); if($i=="metric") m=$(i+1)}; if(iface~/^(lo$|docker|veth|br-|virbr|dummy)/) next; if(m+0==minm+0) print}' | wc -l | tr -d ' ')"
                if [ "\${DEFAULT_ROUTE_COUNT:-0}" -gt 1 ]; then
                    printf 'multi-default'
                    exit 44
                fi
            fi

            if [ ! -S "$SOCKET_PATH" ]; then
                printf 'clean'
                exit 0
            fi

            if [ -n "$CLI_BIN" ]; then
                "$CLI_BIN" disconnect >/dev/null 2>&1 || true
                sleep 1
            fi

            if command -v lsof >/dev/null 2>&1 && lsof -nP "$SOCKET_PATH" >/dev/null 2>&1; then
                printf 'busy'
                exit 42
            fi

            if command -v fuser >/dev/null 2>&1 && fuser "$SOCKET_PATH" >/dev/null 2>&1; then
                printf 'busy'
                exit 42
            fi

            rm -f "$SOCKET_PATH" >/dev/null 2>&1 || true

            if [ -S "$SOCKET_PATH" ]; then
                printf 'stale'
                exit 43
            fi

            printf 'cleaned'
        `;

        Proc.runCommand(`${pluginId}.prepareRuntime.${Date.now()}`, ["sh", "-lc", prepScript, "sh", adguardBinary], (stdout, exitCode) => {
            callback(cleanOutput(stdout), exitCode);
        }, 0, 15000);
    }

    function runAction(operation, args, toastTitle, toastMessage, options) {
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
        lastErrorDebug = "";
        suspendPolling();

        const executeAction = () => {
            runningCommand = operation;

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

                if (exitCode === 124) {
                    lastError = t("toast.command_timeout", "{operation} timed out. The CLI did not answer in time.", {
                        operation: operation
                    });
                } else {
                    lastError = clean || t("toast.operation_failed", "{operation} failed (code {code})", {
                        operation: operation,
                        code: exitCode
                    });
                }
                const hint = buildLocationHelpHint(lastError);
                if (hint) {
                    lastError = `${lastError}\n${hint}`;
                }
                ToastService.showError(t("app.title", "AdGuard VPN"), lastError);
                refreshStatus();
            }, options && options.timeoutMs ? options.timeoutMs : undefined);
        };

        if (options && options.prepareDisconnectedRuntime && !(useSystemdService && isServiceLifecycleOperation(operation))) {
            runningCommand = `${operation}.prepare`;
            prepareDisconnectedRuntime((prepStatus, prepExitCode) => {
                if (prepExitCode === 0) {
                    executeAction();
                    return;
                }

                commandRunning = false;
                runningCommand = "";
                resumePolling();
                recordLastCommand(args, prepExitCode, prepStatus || "prepare_failed");
                lastError = prepStatus === "multi-default" ? t("toast.multiple_default_routes", "Multiple default routes are active. Disconnect the redundant network interface before connecting in TUN mode.") : (prepStatus === "busy" ? t("toast.runtime_busy", "AdGuard VPN runtime is still busy after cleanup. Try again in a few seconds.") : t("toast.runtime_cleanup_failed", "Could not recover the AdGuard VPN runtime before connecting."));
                ToastService.showError(t("app.title", "AdGuard VPN"), lastError);
                refreshStatus();
            });
            return;
        }

        executeAction();
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
                root.reconnectAttempts += 1;
                root.connectWithStrategy();
            } else if (root.isConnected) {
                root.reconnectPending = false;
                root.reconnectAttempts = 0;
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

    Connections {
        target: AdGuardVpnI18n
        // State strings (statusSummary etc.) are assigned imperatively, so a
        // language switch only shows up after the next poll. Force one now.
        function onNormalizedLocaleChanged() {
            if (root.cliAvailable) {
                root.refreshStatus();
            } else {
                root.statusSummary = root.t("status.cli_unavailable", "adguardvpn-cli unavailable");
            }
        }
    }

    Component.onCompleted: {
        loadSettings();
    }
}
