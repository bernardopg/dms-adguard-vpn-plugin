import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "adguardVPplugin"

    StyledText {
        width: parent.width
        text: "AdGuard VPN Settings"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Configure how the widget executes adguardvpn-cli and how aggressively it refreshes telemetry."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    StringSetting {
        settingKey: "adguardBinary"
        label: "adguardvpn-cli Binary"
        description: "Binary name or full path used to execute the AdGuard CLI."
        defaultValue: "adguardvpn-cli"
        placeholder: "adguardvpn-cli"
    }

    SliderSetting {
        settingKey: "refreshIntervalSec"
        label: "Status Refresh Interval"
        description: "How often the widget polls `adguardvpn-cli status`."
        defaultValue: 8
        minimum: 3
        maximum: 120
        unit: "sec"
        leftIcon: "timer"
    }

    SliderSetting {
        settingKey: "locationsCount"
        label: "Location Samples"
        description: "Number of locations fetched for quick-connect suggestions."
        defaultValue: 20
        minimum: 5
        maximum: 100
        unit: "items"
        leftIcon: "public"
    }

    SelectionSetting {
        settingKey: "connectStrategy"
        label: "Default Connect Strategy"
        description: "Behavior used by the main Connect action in the widget."
        options: [
            { label: "Fastest", value: "fastest" },
            { label: "Preferred Location", value: "location" }
        ]
        defaultValue: "fastest"
    }

    StringSetting {
        settingKey: "defaultLocation"
        label: "Preferred Location"
        description: "City, country, or ISO used when strategy is Preferred Location."
        defaultValue: ""
        placeholder: "Sao Paulo, Brazil"
    }

    SelectionSetting {
        settingKey: "ipStack"
        label: "IP Stack"
        description: "Append IPv4/IPv6 flags on connect operations."
        options: [
            { label: "Auto", value: "auto" },
            { label: "IPv4 only", value: "ipv4" },
            { label: "IPv6 only", value: "ipv6" }
        ]
        defaultValue: "auto"
    }

    ToggleSetting {
        settingKey: "autoRefreshLocations"
        label: "Auto Refresh Locations"
        description: "Periodically update ranked server locations in the popout."
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "showLocationInBar"
        label: "Show Text in Bar"
        description: "Show connection text/location next to the icon in the horizontal bar."
        defaultValue: true
    }
}
