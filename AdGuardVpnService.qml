pragma Singleton

import QtQuick
import Quickshell
import qs.Common
import qs.Services

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
            autoRefreshLocations: true
        })

    property string adguardBinary: defaults.adguardBinary
    property int refreshIntervalSec: defaults.refreshIntervalSec
    property int locationsCount: defaults.locationsCount
    property string connectStrategy: defaults.connectStrategy
    property string defaultLocation: defaults.defaultLocation
    property string ipStack: defaults.ipStack
    property bool autoRefreshLocations: defaults.autoRefreshLocations

    property bool cliAvailable: false
    property string cliVersion: ""
    property bool commandRunning: false
    property string runningCommand: ""

    property bool isConnected: false
    property string statusSummary: "Unknown"
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

    property var locations: []
    property string lastError: ""
    property string lastStatusRaw: ""
    property string lastConfigRaw: ""
    property string lastLicenseRaw: ""

    property double lastRefreshMs: 0
    property double lastLocationsRefreshMs: 0

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
        return (text || "")
            .replace(/\x1b\[[0-9;?]*[ -/]*[@-~]/g, "")
            .replace(/\x1b[@-_]/g, "");
    }

    function cleanOutput(text) {
        return stripAnsi(text || "").replace(/\r/g, "").trim();
    }

    function normalizeProtocol(value) {
        const text = (value || "").toString().toLowerCase();
        if (text.indexOf("http2") >= 0) {
            return "http2";
        }
        if (text.indexOf("quic") >= 0) {
            return "quic";
        }
        return "auto";
    }

    function normalizeChannel(value) {
        const text = (value || "").toString().toLowerCase();
        if (text.indexOf("beta") >= 0) {
            return "beta";
        }
        if (text.indexOf("nightly") >= 0) {
            return "nightly";
        }
        return "release";
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

        restartTimers();
        checkCliAvailability();
    }

    function saveSetting(key, value) {
        PluginService.savePluginData(pluginId, key, value);
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
                statusSummary = "adguardvpn-cli unavailable";
                connectedLocation = "";
                connectedMode = "";
                tunnelInterface = "";
                lastError = clean || "Unable to run adguardvpn-cli";
                return;
            }

            lastError = "";
            refreshAll(true);
        });
    }

    function parseStatus(stdout, exitCode) {
        const clean = cleanOutput(stdout);
        lastStatusRaw = clean;
        lastRefreshMs = Date.now();

        if (exitCode !== 0) {
            isConnected = false;
            statusSummary = clean || "Failed to read VPN status";
            connectedLocation = "";
            connectedMode = "";
            tunnelInterface = "";
            lastError = statusSummary;
            return;
        }

        cliAvailable = true;
        lastError = "";

        const lines = clean.split("\n").map(line => line.trim()).filter(Boolean);
        if (!lines.length) {
            isConnected = false;
            statusSummary = "No status output";
            connectedLocation = "";
            connectedMode = "";
            tunnelInterface = "";
            return;
        }

        const firstLine = lines[0];

        const connectedMatch = firstLine.match(/^Connected to\s+(.+?)\s+in\s+([^\s]+)\s+mode,\s+running on\s+([^\s]+)$/i);
        if (connectedMatch) {
            isConnected = true;
            connectedLocation = connectedMatch[1].trim();
            connectedMode = connectedMatch[2].toUpperCase();
            tunnelInterface = connectedMatch[3].trim();
            statusSummary = `Connected (${connectedLocation})`;
            return;
        }

        if (/not\s+connected|disconnected|not\s+running|stopped/i.test(firstLine)) {
            isConnected = false;
            statusSummary = "Disconnected";
            connectedLocation = "";
            connectedMode = "";
            tunnelInterface = "";
            return;
        }

        isConnected = /connected/i.test(firstLine) && !/not\s+connected/i.test(firstLine);
        statusSummary = firstLine;

        if (!isConnected) {
            connectedLocation = "";
            connectedMode = "";
            tunnelInterface = "";
        }
    }

    function parseLicense(stdout, exitCode) {
        const clean = cleanOutput(stdout);
        lastLicenseRaw = clean;

        if (exitCode !== 0) {
            return;
        }

        const lines = clean.split("\n").map(line => line.trim()).filter(Boolean);

        accountEmail = "";
        accountTier = "";
        maxDevices = 0;
        subscriptionRenewDate = "";

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            let match = line.match(/^Logged in as\s+(.+)$/i);
            if (match) {
                accountEmail = match[1].trim();
                continue;
            }

            match = line.match(/^You are using the\s+(.+?)\s+version$/i);
            if (match) {
                accountTier = match[1].trim();
                continue;
            }

            match = line.match(/^Up to\s+(\d+)\s+devices/i);
            if (match) {
                maxDevices = parseInt(match[1], 10);
                continue;
            }

            match = line.match(/^Your subscription will be renewed on\s+([0-9]{4}-[0-9]{2}-[0-9]{2})$/i);
            if (match) {
                subscriptionRenewDate = match[1];
            }
        }
    }

    function parseConfig(stdout, exitCode) {
        const clean = cleanOutput(stdout);
        lastConfigRaw = clean;

        if (exitCode !== 0) {
            return;
        }

        const lines = clean.split("\n");
        const values = ({});

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            if (!line || /^Current configuration/i.test(line)) {
                continue;
            }

            const separatorIndex = line.indexOf(":");
            if (separatorIndex < 0) {
                continue;
            }

            const key = line.slice(0, separatorIndex).trim().toLowerCase();
            const value = line.slice(separatorIndex + 1).trim();
            values[key] = value;
        }

        currentMode = (values["mode"] || currentMode || "").toString().toUpperCase();
        currentProtocolRaw = values["protocol"] || currentProtocolRaw;
        currentProtocol = normalizeProtocol(values["protocol"] || currentProtocol);
        currentUpdateChannel = normalizeChannel(values["update channel"] || currentUpdateChannel);
        dnsUpstream = values["dns upstream"] || dnsUpstream;
        socksHost = values["socks host"] || socksHost;
        socksPort = asInt(values["socks port"], socksPort || 1080, 1, 65535);
        routingMode = (values["tunnel routing mode"] || routingMode || "").toString().toLowerCase();
        changeSystemDns = /on|enabled|true/i.test(values["change system dns"] || "");
    }

    function parseLocations(stdout, exitCode) {
        const clean = cleanOutput(stdout);

        if (exitCode !== 0) {
            if (clean) {
                lastError = clean;
            }
            return;
        }

        const parsed = [];
        const lines = clean.split("\n");

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].replace(/\s+$/, "");
            if (!line || /^ISO\s+/i.test(line) || /^You can connect/i.test(line)) {
                continue;
            }

            const columns = line.split(/\s{2,}/).map(chunk => chunk.trim()).filter(Boolean);
            if (columns.length < 3) {
                continue;
            }

            const iso = columns[0];
            if (!/^[A-Z]{2}$/.test(iso)) {
                continue;
            }

            const country = columns[1];
            const city = columns[2];
            const pingRaw = columns.length > 3 ? columns[3] : "";
            const pingValue = /^\d+$/.test(pingRaw) ? parseInt(pingRaw, 10) : -1;

            parsed.push({
                iso: iso,
                country: country,
                city: city,
                ping: pingValue,
                label: `${city}, ${country} (${iso})`
            });
        }

        locations = parsed;
        lastLocationsRefreshMs = Date.now();
    }

    function refreshStatus() {
        if (!cliAvailable && !adguardBinary) {
            return;
        }

        runCli("status", ["status"], (stdout, exitCode) => {
            if (exitCode !== 0 && /not found|no such file|cannot execute/i.test(cleanOutput(stdout))) {
                cliAvailable = false;
                statusSummary = "adguardvpn-cli unavailable";
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

    function connectWithStrategy() {
        if (connectStrategy === "location" && defaultLocation) {
            connectToLocation(defaultLocation);
            return;
        }
        connectFastest();
    }

    function connectFastest() {
        const args = ["connect", "-f", "-y", "--no-progress"];
        if (ipStack === "ipv4") {
            args.push("-4");
        } else if (ipStack === "ipv6") {
            args.push("-6");
        }

        runAction("connectFastest", args, "AdGuard VPN", "Fastest location selected");
    }

    function connectToLocation(locationText) {
        const target = (locationText || "").toString().trim();
        if (!target) {
            ToastService.showError("AdGuard VPN", "Location is empty");
            return;
        }

        const args = ["connect", "-l", target, "-y", "--no-progress"];
        if (ipStack === "ipv4") {
            args.push("-4");
        } else if (ipStack === "ipv6") {
            args.push("-6");
        }

        runAction("connectLocation", args, "AdGuard VPN", `Connecting to ${target}`);
    }

    function disconnect() {
        runAction("disconnect", ["disconnect"], "AdGuard VPN", "Disconnect requested");
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
        runAction("setMode", ["config", "set-mode", normalized], "AdGuard VPN", `Mode set to ${normalized.toUpperCase()}`);
    }

    function setProtocol(protocol) {
        const normalized = normalizedChoice(protocol, "auto", ["auto", "http2", "quic"]);
        runAction("setProtocol", ["config", "set-protocol", normalized], "AdGuard VPN", `Protocol set to ${normalized}`);
    }

    function setUpdateChannel(channel) {
        const normalized = normalizedChoice(channel, "release", ["release", "beta", "nightly"]);
        runAction("setUpdateChannel", ["config", "set-update-channel", normalized], "AdGuard VPN", `Channel set to ${normalized}`);
    }

    function setDns(upstream) {
        const normalized = (upstream || "").toString().trim();
        if (!normalized) {
            ToastService.showError("AdGuard VPN", "DNS upstream cannot be empty");
            return;
        }

        runAction("setDns", ["config", "set-dns", normalized], "AdGuard VPN", `DNS set to ${normalized}`);
    }

    function runAction(operation, args, toastTitle, toastMessage) {
        if (!cliAvailable) {
            ToastService.showError("AdGuard VPN", "adguardvpn-cli is unavailable");
            return;
        }

        if (commandRunning) {
            ToastService.showInfo("AdGuard VPN", "Another operation is running");
            return;
        }

        commandRunning = true;
        runningCommand = operation;
        lastError = "";

        runCli(operation, args, (stdout, exitCode) => {
            commandRunning = false;
            runningCommand = "";

            const clean = cleanOutput(stdout);
            if (exitCode === 0) {
                if (toastTitle) {
                    const firstLine = clean.split("\n").map(line => line.trim()).filter(Boolean)[0];
                    ToastService.showInfo(toastTitle, firstLine || toastMessage || "Done");
                }

                Qt.callLater(() => {
                    refreshStatus();
                    refreshConfig();
                    refreshLicense();
                });
                return;
            }

            lastError = clean || `${operation} failed (code ${exitCode})`;
            ToastService.showError("AdGuard VPN", lastError);
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
        checkCliAvailability();
    }
}
