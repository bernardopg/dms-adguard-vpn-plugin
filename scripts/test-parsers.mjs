#!/usr/bin/env node
// EN: Unit tests for AdGuardVpnParsers.js (pure .pragma library, loaded via vm).
// PT-BR: Testes unitários dos parsers (biblioteca pura, carregada via vm).
// Run: node scripts/test-parsers.mjs

import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import path from "node:path";
import vm from "node:vm";

const here = path.dirname(fileURLToPath(import.meta.url));
const source = readFileSync(path.join(here, "..", "AdGuardVpnParsers.js"), "utf8")
    .replace(/^\.pragma library\s*$/m, "");

const sandbox = {};
vm.createContext(sandbox);
vm.runInContext(source, sandbox);

const P = sandbox;

let passed = 0;
let failed = 0;
const failures = [];

function test(name, fn) {
    try {
        fn();
        passed += 1;
    } catch (error) {
        failed += 1;
        failures.push({ name, message: error.message });
    }
}

function eq(actual, expected, label) {
    const a = JSON.stringify(actual);
    const b = JSON.stringify(expected);
    if (a !== b) {
        throw new Error(`${label || "value"}: expected ${b}, got ${a}`);
    }
}

// ---------------------------------------------------------------------------
// normalizeProtocol / normalizeChannel
// ---------------------------------------------------------------------------

test("normalizeProtocol maps variants", () => {
    eq(P.normalizeProtocol("HTTP2"), "http2");
    eq(P.normalizeProtocol("Default (auto)"), "auto");
    eq(P.normalizeProtocol("QUIC experimental"), "quic");
    eq(P.normalizeProtocol(""), "auto");
    eq(P.normalizeProtocol(null), "auto");
});

test("normalizeChannel maps variants", () => {
    eq(P.normalizeChannel("Beta"), "beta");
    eq(P.normalizeChannel("nightly build"), "nightly");
    eq(P.normalizeChannel("release"), "release");
    eq(P.normalizeChannel(""), "release");
});

// ---------------------------------------------------------------------------
// parseStatusOutput
// ---------------------------------------------------------------------------

test("status: connected with mode and interface", () => {
    const r = P.parseStatusOutput("Connected to São Paulo in TUN mode, running on tun0");
    eq(r.connected, true, "connected");
    eq(r.connectedLocation, "São Paulo", "location");
    eq(r.connectedMode, "TUN", "mode");
    eq(r.tunnelInterface, "tun0", "iface");
});

test("status: dns leak warning detected", () => {
    const r = P.parseStatusOutput([
        "Connected to São Paulo in TUN mode, running on tun0",
        "Warning: System DNS could not be configured. DNS queries may bypass the VPN tunnel"
    ].join("\n"));
    eq(r.connected, true, "connected");
    eq(r.dnsWarning, true, "dns warning flagged");
});

test("status: no dns leak warning when absent", () => {
    const r = P.parseStatusOutput("Connected to São Paulo in TUN mode, running on tun0");
    eq(r.dnsWarning, false, "no dns warning");
});

test("status: connected simple", () => {
    const r = P.parseStatusOutput("Connected to New York");
    eq(r.connected, true, "connected");
    eq(r.connectedLocation, "New York", "location");
    eq(r.connectedMode, "", "no mode");
});

test("status: key-value block with Status: connected", () => {
    const r = P.parseStatusOutput([
        "Status: connected",
        "Location: Miami, United States",
        "Mode: socks",
        "Interface: tun1"
    ].join("\n"));
    eq(r.connected, true, "connected");
    eq(r.connectedLocation, "Miami, United States", "location");
    eq(r.connectedMode, "SOCKS", "mode");
    eq(r.tunnelInterface, "tun1", "iface");
});

test("status: disconnected variants", () => {
    for (const text of ["VPN is disconnected", "Not connected", "The service is stopped"]) {
        const r = P.parseStatusOutput(text);
        eq(r.disconnected, true, `disconnected for "${text}"`);
    }
});

test("status: connected first line survives disconnect keyword in auxiliary line", () => {
    const r = P.parseStatusOutput([
        "Connected to Frankfurt in TUN mode, running on tun0",
        "Note: a previous session was stopped due to a network change"
    ].join("\n"));
    eq(r.connected, true, "still connected");
    eq(r.disconnected, undefined, "not flagged disconnected");
});

test("status: empty output", () => {
    eq(P.parseStatusOutput("").empty, true);
    eq(P.parseStatusOutput("   \n  ").empty, true);
});

// ---------------------------------------------------------------------------
// parseLicenseOutput
// ---------------------------------------------------------------------------

test("license: full premium output", () => {
    const r = P.parseLicenseOutput([
        "Logged in as user@example.com",
        "You are using the PREMIUM version",
        "Up to 10 devices can be connected simultaneously",
        "Your subscription will be renewed on 2026-08-17"
    ].join("\n"));
    eq(r.accountEmail, "user@example.com", "email");
    eq(r.accountTier, "PREMIUM", "tier");
    eq(r.maxDevices, 10, "devices");
    eq(r.subscriptionRenewDate, "2026-08-17", "renew");
});

test("license: alternate field formats", () => {
    const r = P.parseLicenseOutput([
        "Account email: someone@host.org",
        "Plan: Free",
        "Max devices: 5",
        "Renews on: 2027-01-02"
    ].join("\n"));
    eq(r.accountEmail, "someone@host.org", "email");
    eq(r.accountTier, "Free", "tier");
    eq(r.maxDevices, 5, "devices");
    eq(r.subscriptionRenewDate, "2027-01-02", "renew");
});

test("license: bare email anywhere in line", () => {
    const r = P.parseLicenseOutput("Session for joe.doe+vpn@mail.example.com is active");
    eq(r.accountEmail, "joe.doe+vpn@mail.example.com", "email");
});

// ---------------------------------------------------------------------------
// parseConfigOutput
// ---------------------------------------------------------------------------

const CONFIG_SAMPLE = [
    "Current configuration:",
    "Mode: TUN",
    "Protocol: Default (auto)",
    "Update channel: nightly",
    "DNS upstream: 1.1.1.1",
    "Socks host: 127.0.0.1",
    "Socks port: 1080",
    "Tunnel routing mode: Global",
    "Change system DNS: off"
].join("\n");

test("config: full parse", () => {
    const r = P.parseConfigOutput(CONFIG_SAMPLE, {});
    eq(r.currentMode, "TUN", "mode");
    eq(r.currentProtocol, "auto", "protocol");
    eq(r.currentProtocolRaw, "Default (auto)", "protocolRaw");
    eq(r.currentUpdateChannel, "nightly", "channel");
    eq(r.dnsUpstream, "1.1.1.1", "dns");
    eq(r.socksHost, "127.0.0.1", "socksHost");
    eq(r.socksPort, 1080, "socksPort");
    eq(r.routingMode, "global", "routing");
    eq(r.changeSystemDns, false, "changeSystemDns off");
});

test("config: partial output falls back to current state", () => {
    const r = P.parseConfigOutput("Protocol: QUIC", {
        currentMode: "SOCKS",
        dnsUpstream: "9.9.9.9",
        socksPort: 4444
    });
    eq(r.currentMode, "SOCKS", "mode fallback");
    eq(r.currentProtocol, "quic", "protocol parsed");
    eq(r.dnsUpstream, "9.9.9.9", "dns fallback");
    eq(r.socksPort, 4444, "port fallback");
});

test("config: socks port clamped and defaulted", () => {
    eq(P.parseConfigOutput("Socks port: 99999", {}).socksPort, 65535, "clamp high");
    eq(P.parseConfigOutput("Socks port: abc", {}).socksPort, 1080, "default invalid");
});

test("config: change system dns on", () => {
    eq(P.parseConfigOutput("Change system DNS: enabled", {}).changeSystemDns, true);
});

// ---------------------------------------------------------------------------
// parseLocationLine — column strategies
// ---------------------------------------------------------------------------

test("location line: multi-space columns with ping", () => {
    const r = P.parseLocationLine("BR    Brazil    Sao Paulo    20 ms");
    eq(r.iso, "BR", "iso");
    eq(r.country, "Brazil", "country");
    eq(r.city, "Sao Paulo", "city");
    eq(r.ping, 20, "ping");
});

test("location line: tab columns", () => {
    const r = P.parseLocationLine("US\tUnited States\tMiami\t92");
    eq(r.iso, "US", "iso");
    eq(r.city, "Miami", "city");
    eq(r.ping, 92, "ping");
});

test("location line: pipe columns", () => {
    const r = P.parseLocationLine("CH|Switzerland|Zurich|222");
    eq(r.iso, "CH", "iso");
    eq(r.country, "Switzerland", "country");
});

test("location line: csv columns", () => {
    const r = P.parseLocationLine("AR,Argentina,Buenos Aires,134");
    eq(r.iso, "AR", "iso");
    eq(r.city, "Buenos Aires", "city");
});

test("location line: dashed format", () => {
    const r = P.parseLocationLine("FR France - Marseille 219ms");
    eq(r.iso, "FR", "iso");
    eq(r.country, "France", "country");
    eq(r.city, "Marseille", "city");
    eq(r.ping, 219, "ping");
});

test("location line: fallback with bracket iso and flag emoji", () => {
    const r = P.parseLocationLine("🇧🇷 Brazil, Sao Paulo (BR) 23ms");
    eq(r.iso, "BR", "iso");
    eq(r.country, "Brazil", "country");
    eq(r.city, "Sao Paulo", "city");
    eq(r.ping, 23, "ping");
});

test("location line: no ping yields -1", () => {
    const r = P.parseLocationLine("DE    Germany    Berlin");
    eq(r.iso, "DE", "iso");
    eq(r.ping, -1, "ping");
});

// ---------------------------------------------------------------------------
// parseLocationLine — regression: lowercase words must not become ISO codes
// ---------------------------------------------------------------------------

test("regression: lowercase two-letter words are not ISO codes", () => {
    eq(P.parseLocationLine("connect to the location"), null, "prose line");
    eq(P.parseLocationLine("to be - or not"), null, "dashed prose");
    eq(P.parseLocationLine("go in - out now"), null, "dashed prose 2");
});

test("regression: lowercase iso in columns is rejected", () => {
    eq(P.parseLocationLine("br    Brazil    Sao Paulo    20"), null, "lowercase first column");
});

// ---------------------------------------------------------------------------
// parseLocationsOutput
// ---------------------------------------------------------------------------

test("locations output: headers and separators are skipped", () => {
    const r = P.parseLocationsOutput([
        "ISO    COUNTRY    CITY    PING",
        "====================================",
        "BR     Brazil     Sao Paulo     20",
        "CL     Chile      Santiago      74",
        "You can connect to a location with: adguardvpn-cli connect -l <ISO>"
    ].join("\n"));
    eq(r.locations.length, 2, "count");
    eq(r.locations[0].iso, "BR", "first iso");
    eq(r.locations[1].city, "Santiago", "second city");
    eq(r.parseFailed, false, "parseFailed");
});

test("locations output: garbage marks parseFailed", () => {
    const r = P.parseLocationsOutput("completely unrelated text\nwithout any location rows");
    eq(r.locations.length, 0, "count");
    eq(r.parseFailed, true, "parseFailed");
});

test("locations output: empty input is not a failure", () => {
    const r = P.parseLocationsOutput("");
    eq(r.locations.length, 0, "count");
    eq(r.parseFailed, false, "parseFailed");
});

// ---------------------------------------------------------------------------
// Report
// ---------------------------------------------------------------------------

if (failures.length) {
    console.error(`❌ ${failed} test(s) failed, ${passed} passed:`);
    for (const f of failures) {
        console.error(`  - ${f.name}: ${f.message}`);
    }
    process.exit(1);
}

console.log(`✅ All ${passed} parser tests passed`);
