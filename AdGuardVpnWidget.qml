import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    pluginId: "adguardVPplugin"
    layerNamespacePlugin: "adguard-vpn"

    property string locationInputText: ""
    property string dnsInputText: ""
    property bool showLocationInBar: pluginData.showLocationInBar !== undefined ? pluginData.showLocationInBar : true

    readonly property string barIconName: {
        if (!AdGuardVpnService.cliAvailable) {
            return "warning";
        }
        if (AdGuardVpnService.commandRunning) {
            return "sync";
        }
        return AdGuardVpnService.isConnected ? "shield_lock" : "shield";
    }

    readonly property color barIconColor: {
        if (!AdGuardVpnService.cliAvailable) {
            return Theme.warning;
        }
        if (AdGuardVpnService.isConnected) {
            return Theme.primary;
        }
        return Theme.surfaceVariantText;
    }

    readonly property string barText: {
        if (!AdGuardVpnService.cliAvailable) {
            return "CLI";
        }
        if (AdGuardVpnService.commandRunning) {
            return "...";
        }
        if (AdGuardVpnService.isConnected) {
            return AdGuardVpnService.connectedLocation || "Connected";
        }
        return "Off";
    }

    function formatTimestamp(ms) {
        if (!ms || ms <= 0) {
            return "never";
        }

        try {
            return new Date(ms).toLocaleTimeString();
        } catch (error) {
            return "unknown";
        }
    }

    function safeText(value, fallback) {
        if (value === undefined || value === null || value === "") {
            return fallback;
        }
        return value;
    }

    component ActionButton: StyledRect {
        id: buttonRoot

        required property string iconName
        required property string label
        property bool active: false
        property bool actionEnabled: true

        signal triggered

        implicitHeight: 40
        radius: Theme.cornerRadius
        color: {
            if (!actionEnabled) {
                return Theme.surfaceContainer;
            }
            if (active) {
                return Theme.primaryContainer;
            }
            return buttonMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh;
        }
        opacity: actionEnabled ? 1 : 0.55

        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: Theme.spacingS

            DankIcon {
                name: buttonRoot.iconName
                size: 16
                color: buttonRoot.active ? Theme.primary : Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: buttonRoot.label
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: buttonRoot.active ? Theme.primary : Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            enabled: buttonRoot.actionEnabled
            hoverEnabled: true
            cursorShape: buttonRoot.actionEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: buttonRoot.triggered()
        }
    }

    Ref {
        service: AdGuardVpnService
    }

    Connections {
        target: pluginService

        function onPluginDataChanged(changedPluginId) {
            if (changedPluginId !== root.pluginId) {
                return;
            }

            locationInputText = pluginData.defaultLocation || "";
        }
    }

    Connections {
        target: AdGuardVpnService

        function onDnsUpstreamChanged() {
            if (!dnsInput.activeFocus) {
                dnsInputText = AdGuardVpnService.dnsUpstream || "";
            }
        }
    }

    Component.onCompleted: {
        locationInputText = pluginData.defaultLocation || "";
        dnsInputText = AdGuardVpnService.dnsUpstream || "";
        AdGuardVpnService.refreshAll(true);
    }

    popoutWidth: 500
    popoutHeight: 720

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingS

            DankIcon {
                name: root.barIconName
                size: root.iconSize
                color: root.barIconColor
                anchors.verticalCenter: parent.verticalCenter

                RotationAnimator on rotation {
                    running: AdGuardVpnService.commandRunning
                    from: 0
                    to: 360
                    loops: Animation.Infinite
                    duration: 1100
                }
            }

            StyledText {
                visible: root.showLocationInBar
                text: root.barText
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeSmall
                width: 140
                elide: Text.ElideRight
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            DankIcon {
                name: root.barIconName
                size: root.iconSize
                color: root.barIconColor
                anchors.horizontalCenter: parent.horizontalCenter

                RotationAnimator on rotation {
                    running: AdGuardVpnService.commandRunning
                    from: 0
                    to: 360
                    loops: Animation.Infinite
                    duration: 1100
                }
            }
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: popout

            headerText: "AdGuard VPN"
            detailsText: AdGuardVpnService.cliAvailable
                ? AdGuardVpnService.statusSummary
                : "adguardvpn-cli not available"
            showCloseButton: true

            Item {
                width: parent.width
                implicitHeight: root.popoutHeight - popout.headerHeight - popout.detailsHeight - Theme.spacingXL

                Flickable {
                    id: contentFlick
                    anchors.fill: parent
                    clip: true
                    contentWidth: width
                    contentHeight: contentColumn.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: contentColumn
                        width: contentFlick.width
                        spacing: Theme.spacingM

                        StyledRect {
                            width: parent.width
                            radius: Theme.cornerRadius
                            color: Theme.surfaceContainerHigh
                            border.color: AdGuardVpnService.isConnected ? Theme.withAlpha(Theme.primary, 0.35) : "transparent"
                            border.width: 1
                            implicitHeight: statusColumn.implicitHeight + Theme.spacingM * 2

                            Column {
                                id: statusColumn
                                anchors.fill: parent
                                anchors.margins: Theme.spacingM
                                spacing: Theme.spacingS

                                Row {
                                    width: parent.width
                                    spacing: Theme.spacingS

                                    DankIcon {
                                        name: root.barIconName
                                        size: 18
                                        color: root.barIconColor
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    StyledText {
                                        width: parent.width - 26
                                        text: AdGuardVpnService.isConnected
                                            ? `Connected to ${root.safeText(AdGuardVpnService.connectedLocation, "location unknown")}`
                                            : root.safeText(AdGuardVpnService.statusSummary, "Disconnected")
                                        color: Theme.surfaceText
                                        font.pixelSize: Theme.fontSizeMedium
                                        font.weight: Font.Bold
                                        wrapMode: Text.WordWrap
                                    }
                                }

                                StyledText {
                                    visible: !!AdGuardVpnService.lastError
                                    width: parent.width
                                    text: AdGuardVpnService.lastError
                                    color: Theme.warning
                                    font.pixelSize: Theme.fontSizeSmall
                                    wrapMode: Text.WordWrap
                                }

                                StyledText {
                                    width: parent.width
                                    text: `Account: ${root.safeText(AdGuardVpnService.accountEmail, "not logged")}`
                                    color: Theme.surfaceVariantText
                                    font.pixelSize: Theme.fontSizeSmall
                                    elide: Text.ElideRight
                                }

                                StyledText {
                                    width: parent.width
                                    text: `Plan: ${root.safeText(AdGuardVpnService.accountTier, "unknown")}  •  Devices: ${AdGuardVpnService.maxDevices || "-"}`
                                    color: Theme.surfaceVariantText
                                    font.pixelSize: Theme.fontSizeSmall
                                }

                                StyledText {
                                    visible: !!AdGuardVpnService.subscriptionRenewDate
                                    width: parent.width
                                    text: `Renewal: ${AdGuardVpnService.subscriptionRenewDate}`
                                    color: Theme.surfaceVariantText
                                    font.pixelSize: Theme.fontSizeSmall
                                }

                                StyledText {
                                    width: parent.width
                                    text: `Mode: ${root.safeText(AdGuardVpnService.currentMode, "-")}  •  Protocol: ${root.safeText(AdGuardVpnService.currentProtocolRaw || AdGuardVpnService.currentProtocol, "-")}  •  Channel: ${AdGuardVpnService.currentUpdateChannel}`
                                    color: Theme.surfaceVariantText
                                    font.pixelSize: Theme.fontSizeSmall
                                    wrapMode: Text.WordWrap
                                }

                                StyledText {
                                    width: parent.width
                                    text: `CLI: ${root.safeText(AdGuardVpnService.cliVersion, "unknown")}  •  Last sync: ${root.formatTimestamp(AdGuardVpnService.lastRefreshMs)}`
                                    color: Theme.surfaceVariantText
                                    font.pixelSize: Theme.fontSizeSmall
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }

                        StyledRect {
                            width: parent.width
                            radius: Theme.cornerRadius
                            color: Theme.surfaceContainerHigh
                            implicitHeight: actionColumn.implicitHeight + Theme.spacingM * 2

                            Column {
                                id: actionColumn
                                anchors.fill: parent
                                anchors.margins: Theme.spacingM
                                spacing: Theme.spacingS

                                StyledText {
                                    width: parent.width
                                    text: "Quick Actions"
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Medium
                                }

                                RowLayout {
                                    width: parent.width
                                    spacing: Theme.spacingS

                                    ActionButton {
                                        Layout.fillWidth: true
                                        iconName: AdGuardVpnService.isConnected ? "link_off" : "link"
                                        label: AdGuardVpnService.isConnected ? "Disconnect" : "Connect"
                                        active: AdGuardVpnService.isConnected
                                        actionEnabled: AdGuardVpnService.cliAvailable && !AdGuardVpnService.commandRunning
                                        onTriggered: AdGuardVpnService.toggleConnection()
                                    }

                                    ActionButton {
                                        Layout.fillWidth: true
                                        iconName: "speed"
                                        label: "Fastest"
                                        actionEnabled: AdGuardVpnService.cliAvailable && !AdGuardVpnService.commandRunning
                                        onTriggered: AdGuardVpnService.connectFastest()
                                    }

                                    ActionButton {
                                        Layout.fillWidth: true
                                        iconName: "refresh"
                                        label: "Refresh"
                                        actionEnabled: !AdGuardVpnService.commandRunning
                                        onTriggered: AdGuardVpnService.refreshAll(true)
                                    }
                                }

                                StyledText {
                                    width: parent.width
                                    visible: AdGuardVpnService.commandRunning
                                    text: `Running: ${AdGuardVpnService.runningCommand}`
                                    color: Theme.primary
                                    font.pixelSize: Theme.fontSizeSmall
                                }
                            }
                        }

                        StyledRect {
                            width: parent.width
                            radius: Theme.cornerRadius
                            color: Theme.surfaceContainerHigh
                            implicitHeight: locationsColumn.implicitHeight + Theme.spacingM * 2

                            Column {
                                id: locationsColumn
                                anchors.fill: parent
                                anchors.margins: Theme.spacingM
                                spacing: Theme.spacingS

                                StyledText {
                                    width: parent.width
                                    text: "Locations"
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Medium
                                }

                                TextField {
                                    id: locationInput
                                    width: parent.width
                                    placeholderText: "City, country, or ISO code (e.g. Sao Paulo / BR)"
                                    text: root.locationInputText
                                    selectByMouse: true
                                    color: Theme.surfaceText
                                    selectedTextColor: Theme.onPrimary
                                    selectionColor: Theme.primary
                                    onTextChanged: root.locationInputText = text

                                    background: Rectangle {
                                        radius: Theme.cornerRadius
                                        color: Theme.surfaceContainer
                                        border.width: 1
                                        border.color: locationInput.activeFocus ? Theme.primary : Theme.outlineVariant
                                    }
                                }

                                RowLayout {
                                    width: parent.width
                                    spacing: Theme.spacingS

                                    ActionButton {
                                        Layout.fillWidth: true
                                        iconName: "near_me"
                                        label: "Connect"
                                        actionEnabled: AdGuardVpnService.cliAvailable && !AdGuardVpnService.commandRunning && locationInput.text.trim().length > 0
                                        onTriggered: AdGuardVpnService.connectToLocation(locationInput.text.trim())
                                    }

                                    ActionButton {
                                        Layout.fillWidth: true
                                        iconName: "save"
                                        label: "Set Default"
                                        actionEnabled: locationInput.text.trim().length > 0
                                        onTriggered: {
                                            const value = locationInput.text.trim();
                                            root.locationInputText = value;
                                            AdGuardVpnService.saveSetting("defaultLocation", value);
                                            ToastService.showInfo("AdGuard VPN", `Default location saved: ${value}`);
                                        }
                                    }
                                }

                                StyledText {
                                    width: parent.width
                                    text: `Top ${AdGuardVpnService.locations.length} locations • Last update: ${root.formatTimestamp(AdGuardVpnService.lastLocationsRefreshMs)}`
                                    color: Theme.surfaceVariantText
                                    font.pixelSize: Theme.fontSizeSmall
                                }

                                Column {
                                    width: parent.width
                                    spacing: Theme.spacingXS

                                    Repeater {
                                        model: Math.min(8, AdGuardVpnService.locations.length)

                                        StyledRect {
                                            required property int index
                                            readonly property var locationItem: AdGuardVpnService.locations[index]

                                            width: parent.width
                                            implicitHeight: 38
                                            radius: Theme.cornerRadius
                                            color: locationMouse.containsMouse
                                                ? Theme.surfaceContainerHighest
                                                : Theme.surfaceContainer

                                            Row {
                                                anchors.fill: parent
                                                anchors.leftMargin: Theme.spacingS
                                                anchors.rightMargin: Theme.spacingS
                                                spacing: Theme.spacingS

                                                StyledText {
                                                    width: 28
                                                    text: locationItem.iso
                                                    color: Theme.primary
                                                    font.pixelSize: Theme.fontSizeSmall
                                                    font.weight: Font.Bold
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }

                                                StyledText {
                                                    width: parent.width - 120
                                                    text: `${locationItem.city}, ${locationItem.country}`
                                                    color: Theme.surfaceText
                                                    font.pixelSize: Theme.fontSizeSmall
                                                    elide: Text.ElideRight
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }

                                                StyledText {
                                                    width: 40
                                                    text: locationItem.ping >= 0 ? `${locationItem.ping}ms` : "-"
                                                    color: Theme.surfaceVariantText
                                                    font.pixelSize: Theme.fontSizeSmall
                                                    horizontalAlignment: Text.AlignRight
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }
                                            }

                                            MouseArea {
                                                id: locationMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    AdGuardVpnService.connectToLocation(locationItem.city + ", " + locationItem.country);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        StyledRect {
                            width: parent.width
                            radius: Theme.cornerRadius
                            color: Theme.surfaceContainerHigh
                            implicitHeight: configColumn.implicitHeight + Theme.spacingM * 2

                            Column {
                                id: configColumn
                                anchors.fill: parent
                                anchors.margins: Theme.spacingM
                                spacing: Theme.spacingS

                                StyledText {
                                    width: parent.width
                                    text: "Configuration"
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Medium
                                }

                                StyledText {
                                    width: parent.width
                                    text: "Mode"
                                    color: Theme.surfaceVariantText
                                    font.pixelSize: Theme.fontSizeSmall
                                }

                                RowLayout {
                                    width: parent.width
                                    spacing: Theme.spacingS

                                    ActionButton {
                                        Layout.fillWidth: true
                                        iconName: "device_hub"
                                        label: "TUN"
                                        active: (AdGuardVpnService.currentMode || "").toLowerCase() === "tun"
                                        actionEnabled: AdGuardVpnService.cliAvailable && !AdGuardVpnService.commandRunning
                                        onTriggered: AdGuardVpnService.setMode("tun")
                                    }

                                    ActionButton {
                                        Layout.fillWidth: true
                                        iconName: "safety_check"
                                        label: "SOCKS"
                                        active: (AdGuardVpnService.currentMode || "").toLowerCase() === "socks"
                                        actionEnabled: AdGuardVpnService.cliAvailable && !AdGuardVpnService.commandRunning
                                        onTriggered: AdGuardVpnService.setMode("socks")
                                    }
                                }

                                StyledText {
                                    width: parent.width
                                    text: "Protocol"
                                    color: Theme.surfaceVariantText
                                    font.pixelSize: Theme.fontSizeSmall
                                }

                                RowLayout {
                                    width: parent.width
                                    spacing: Theme.spacingS

                                    ActionButton {
                                        Layout.fillWidth: true
                                        iconName: "auto_awesome"
                                        label: "Auto"
                                        active: AdGuardVpnService.currentProtocol === "auto"
                                        actionEnabled: AdGuardVpnService.cliAvailable && !AdGuardVpnService.commandRunning
                                        onTriggered: AdGuardVpnService.setProtocol("auto")
                                    }

                                    ActionButton {
                                        Layout.fillWidth: true
                                        iconName: "http"
                                        label: "HTTP2"
                                        active: AdGuardVpnService.currentProtocol === "http2"
                                        actionEnabled: AdGuardVpnService.cliAvailable && !AdGuardVpnService.commandRunning
                                        onTriggered: AdGuardVpnService.setProtocol("http2")
                                    }

                                    ActionButton {
                                        Layout.fillWidth: true
                                        iconName: "rocket_launch"
                                        label: "QUIC"
                                        active: AdGuardVpnService.currentProtocol === "quic"
                                        actionEnabled: AdGuardVpnService.cliAvailable && !AdGuardVpnService.commandRunning
                                        onTriggered: AdGuardVpnService.setProtocol("quic")
                                    }
                                }

                                StyledText {
                                    width: parent.width
                                    text: "Update channel"
                                    color: Theme.surfaceVariantText
                                    font.pixelSize: Theme.fontSizeSmall
                                }

                                RowLayout {
                                    width: parent.width
                                    spacing: Theme.spacingS

                                    ActionButton {
                                        Layout.fillWidth: true
                                        iconName: "new_releases"
                                        label: "Release"
                                        active: AdGuardVpnService.currentUpdateChannel === "release"
                                        actionEnabled: AdGuardVpnService.cliAvailable && !AdGuardVpnService.commandRunning
                                        onTriggered: AdGuardVpnService.setUpdateChannel("release")
                                    }

                                    ActionButton {
                                        Layout.fillWidth: true
                                        iconName: "science"
                                        label: "Beta"
                                        active: AdGuardVpnService.currentUpdateChannel === "beta"
                                        actionEnabled: AdGuardVpnService.cliAvailable && !AdGuardVpnService.commandRunning
                                        onTriggered: AdGuardVpnService.setUpdateChannel("beta")
                                    }

                                    ActionButton {
                                        Layout.fillWidth: true
                                        iconName: "bolt"
                                        label: "Nightly"
                                        active: AdGuardVpnService.currentUpdateChannel === "nightly"
                                        actionEnabled: AdGuardVpnService.cliAvailable && !AdGuardVpnService.commandRunning
                                        onTriggered: AdGuardVpnService.setUpdateChannel("nightly")
                                    }
                                }

                                StyledText {
                                    width: parent.width
                                    text: "DNS upstream"
                                    color: Theme.surfaceVariantText
                                    font.pixelSize: Theme.fontSizeSmall
                                }

                                RowLayout {
                                    width: parent.width
                                    spacing: Theme.spacingS

                                    TextField {
                                        id: dnsInput
                                        Layout.fillWidth: true
                                        placeholderText: "1.1.1.1"
                                        text: root.dnsInputText
                                        selectByMouse: true
                                        color: Theme.surfaceText
                                        selectedTextColor: Theme.onPrimary
                                        selectionColor: Theme.primary
                                        onTextChanged: root.dnsInputText = text

                                        background: Rectangle {
                                            radius: Theme.cornerRadius
                                            color: Theme.surfaceContainer
                                            border.width: 1
                                            border.color: dnsInput.activeFocus ? Theme.primary : Theme.outlineVariant
                                        }
                                    }

                                    ActionButton {
                                        Layout.preferredWidth: 120
                                        iconName: "check"
                                        label: "Apply"
                                        actionEnabled: AdGuardVpnService.cliAvailable && !AdGuardVpnService.commandRunning && dnsInput.text.trim().length > 0
                                        onTriggered: AdGuardVpnService.setDns(dnsInput.text.trim())
                                    }
                                }
                            }
                        }

                        Item {
                            width: parent.width
                            height: Theme.spacingL
                        }
                    }
                }
            }
        }
    }
}
