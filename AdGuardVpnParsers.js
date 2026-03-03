// @ts-nocheck
.pragma library

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

function parseStatusOutput(clean) {
    const lines = (clean || "").split("\n").map(line => line.trim()).filter(Boolean);
    if (!lines.length) {
        return { empty: true };
    }

    const firstLine = lines[0];
    const fullOutput = lines.join("\n");
    const disconnectPattern = /not\s+connected|disconnected|not\s+running|stopped/i;
    if (disconnectPattern.test(firstLine) || disconnectPattern.test(fullOutput)) {
        return {
            disconnected: true,
            firstLine: firstLine
        };
    }

    const connectedWithIface = firstLine.match(/^Connected to\s+(.+?)\s+in\s+([^\s]+)\s+mode,\s+running on\s+([^\s]+)$/i);
    if (connectedWithIface) {
        return {
            connected: true,
            connectedLocation: connectedWithIface[1].trim(),
            connectedMode: connectedWithIface[2].trim().toUpperCase(),
            tunnelInterface: connectedWithIface[3].trim(),
            firstLine: firstLine
        };
    }

    let location = "";
    let mode = "";
    let iface = "";

    const connectedSimple = firstLine.match(/^Connected to\s+(.+?)\s+in\s+([^\s]+)\s+mode$/i)
        || firstLine.match(/^Connected to\s+(.+)$/i);
    if (connectedSimple) {
        location = connectedSimple[1].trim();
        mode = connectedSimple[2] ? connectedSimple[2].trim().toUpperCase() : "";
    }

    for (let i = 0; i < lines.length; i++) {
        const line = lines[i];

        if (!location) {
            const locationMatch = line.match(/^Location\s*:\s*(.+)$/i);
            if (locationMatch) {
                location = locationMatch[1].trim();
            }
        }

        if (!mode) {
            const modeMatch = line.match(/^Mode\s*:\s*(.+)$/i);
            if (modeMatch) {
                mode = modeMatch[1].trim().toUpperCase();
            }
        }

        if (!iface) {
            const ifaceMatch = line.match(/^(?:Interface|Tunnel(?:\s+interface)?)\s*:\s*(.+)$/i);
            if (ifaceMatch) {
                iface = ifaceMatch[1].trim();
            }
        }
    }

    const hasConnectedSignal = /connected/i.test(firstLine) || /status\s*:\s*connected/i.test(fullOutput);
    if (hasConnectedSignal && location) {
        return {
            connected: true,
            connectedLocation: location,
            connectedMode: mode,
            tunnelInterface: iface,
            firstLine: firstLine
        };
    }

    const fallbackConnected = /connected/i.test(firstLine) && !/not\s+connected/i.test(firstLine);
    return {
        fallback: true,
        isConnected: fallbackConnected,
        firstLine: firstLine
    };
}

function parseLicenseOutput(clean) {
    const lines = (clean || "").split("\n").map(line => line.trim()).filter(Boolean);

    let accountEmail = "";
    let accountTier = "";
    let maxDevices = 0;
    let subscriptionRenewDate = "";

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

    return {
        accountEmail: accountEmail,
        accountTier: accountTier,
        maxDevices: maxDevices,
        subscriptionRenewDate: subscriptionRenewDate
    };
}

function parseConfigOutput(clean, currentState) {
    const lines = (clean || "").split("\n");
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

    const fallbackState = currentState || {};
    const socksPortRaw = values["socks port"];
    let socksPort = parseInt(socksPortRaw, 10);
    if (isNaN(socksPort)) {
        socksPort = parseInt(fallbackState.socksPort, 10);
    }
    if (isNaN(socksPort) || socksPort < 1) {
        socksPort = 1080;
    }
    if (socksPort > 65535) {
        socksPort = 65535;
    }

    return {
        currentMode: (values["mode"] || fallbackState.currentMode || "").toString().toUpperCase(),
        currentProtocolRaw: values["protocol"] || fallbackState.currentProtocolRaw || "",
        currentProtocol: normalizeProtocol(values["protocol"] || fallbackState.currentProtocol),
        currentUpdateChannel: normalizeChannel(values["update channel"] || fallbackState.currentUpdateChannel),
        dnsUpstream: values["dns upstream"] || fallbackState.dnsUpstream || "",
        socksHost: values["socks host"] || fallbackState.socksHost || "",
        socksPort: socksPort,
        routingMode: (values["tunnel routing mode"] || fallbackState.routingMode || "").toString().toLowerCase(),
        changeSystemDns: /on|enabled|true/i.test(values["change system dns"] || "")
    };
}

function parseLocationLine(line) {
    const compact = (line || "").trim();
    if (!compact) {
        return null;
    }

    const tryColumns = (parts) => {
        const columns = (parts || []).map(chunk => (chunk || "").trim()).filter(Boolean);
        if (columns.length < 3) {
            return null;
        }

        const iso = columns[0].toUpperCase();
        if (!/^[A-Z]{2}$/.test(iso)) {
            return null;
        }

        const country = columns[1];
        const city = columns[2];
        const pingRaw = columns.length > 3 ? columns[3] : "";
        const pingDigits = (pingRaw || "").toString().replace(/[^0-9]/g, "");
        const pingValue = pingDigits ? parseInt(pingDigits, 10) : -1;

        return {
            iso: iso,
            country: country,
            city: city,
            ping: pingValue,
            label: `${city}, ${country} (${iso})`
        };
    };

    const byMultiSpace = tryColumns(compact.split(/\s{2,}/));
    if (byMultiSpace) {
        return byMultiSpace;
    }

    const byTab = tryColumns(compact.split(/\t+/));
    if (byTab) {
        return byTab;
    }

    const byPipe = tryColumns(compact.split("|"));
    if (byPipe) {
        return byPipe;
    }

    const byCsv = tryColumns(compact.split(","));
    if (byCsv) {
        return byCsv;
    }

    const dashedMatch = compact.match(/^([A-Z]{2})\s+(.+?)\s*[-–—]\s*(.+?)(?:\s+(\d+)\s*ms?)?$/i);
    if (dashedMatch) {
        const iso = dashedMatch[1].toUpperCase();
        const country = dashedMatch[2].trim();
        const city = dashedMatch[3].trim();
        const pingValue = dashedMatch[4] ? parseInt(dashedMatch[4], 10) : -1;
        return {
            iso: iso,
            country: country,
            city: city,
            ping: pingValue,
            label: `${city}, ${country} (${iso})`
        };
    }

    const normalized = compact
        .replace(/(?:\uD83C[\uDDE6-\uDDFF]){2}/g, "")
        .replace(/[•·]/g, " ")
        .replace(/\s+/g, " ")
        .trim();

    const bracketIsoMatch = normalized.match(/\(([A-Z]{2})\)/i);
    const plainIsoMatch = normalized.match(/\b([A-Z]{2})\b/i);
    const iso = (bracketIsoMatch ? bracketIsoMatch[1] : (plainIsoMatch ? plainIsoMatch[1] : "")).toUpperCase();
    if (!/^[A-Z]{2}$/.test(iso)) {
        return null;
    }

    const pingMatch = normalized.match(/(\d{1,5})\s*ms\b/i);
    const pingValue = pingMatch ? parseInt(pingMatch[1], 10) : -1;

    const textWithoutPing = normalized.replace(/\d{1,5}\s*ms\b/i, "")
        .replace(new RegExp(`\\(${iso}\\)`, "ig"), "")
        .replace(new RegExp(`\\b${iso}\\b`, "ig"), "")
        .replace(/^[\s,|:\-–—]+|[\s,|:\-–—]+$/g, "")
        .trim();

    let country = "";
    let city = "";

    if (textWithoutPing.indexOf(",") >= 0) {
        const parts = textWithoutPing.split(",").map(part => part.trim()).filter(Boolean);
        if (parts.length >= 2) {
            country = parts[0];
            city = parts.slice(1).join(", ");
        } else if (parts.length === 1) {
            city = parts[0];
        }
    } else if (textWithoutPing.indexOf(" - ") >= 0) {
        const dashedParts = textWithoutPing.split(/\s+[-–—]\s+/).map(part => part.trim()).filter(Boolean);
        if (dashedParts.length >= 2) {
            country = dashedParts[0];
            city = dashedParts.slice(1).join(" - ");
        } else if (dashedParts.length === 1) {
            city = dashedParts[0];
        }
    } else {
        city = textWithoutPing;
    }

    if (!city) {
        city = iso;
    }

    return {
        iso: iso,
        country: country,
        city: city,
        ping: pingValue,
        label: country ? `${city}, ${country} (${iso})` : `${city} (${iso})`
    };
}

function parseLocationsOutput(clean) {
    const parsed = [];
    const lines = (clean || "").split("\n");

    for (let i = 0; i < lines.length; i++) {
        const line = lines[i].replace(/\s+$/, "");
        if (!line
                || /^ISO\s+/i.test(line)
                || /^You can connect/i.test(line)
                || /^[-=]{4,}$/.test(line)
                || /^(Country|City|Ping)\b/i.test(line)) {
            continue;
        }

        const parsedLine = parseLocationLine(line);
        if (parsedLine) {
            parsed.push(parsedLine);
        }
    }

    return {
        locations: parsed,
        parseFailed: parsed.length === 0 && !!(clean || "").trim()
    };
}
