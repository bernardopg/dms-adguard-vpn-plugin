import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "adguardVPplugin"

    function t(key, fallback, params) {
        return AdGuardVpnI18n.tr(key, fallback, params);
    }

    StyledText {
        width: parent.width
        text: root.t("settings.title", "AdGuard VPN Settings")
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: root.t("settings.subtitle", "Configure how the widget executes adguardvpn-cli and how aggressively it refreshes telemetry.")
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    SelectionSetting {
        settingKey: "languageOverride"
        label: root.t("settings.language.label", "Language")
        description: root.t("settings.language.description", "UI language for this plugin. Auto follows system locale.")
        options: [
            { label: root.t("settings.language.auto", "Auto (System)"), value: "auto" },
            { label: root.t("settings.language.en", "English"), value: "en_US" },
            { label: root.t("settings.language.pt_BR", "Portuguese (Brazil)"), value: "pt_BR" }
        ]
        defaultValue: "auto"
    }

    StringSetting {
        settingKey: "adguardBinary"
        label: root.t("settings.binary.label", "adguardvpn-cli Binary")
        description: root.t("settings.binary.description", "Binary name or full path used to execute the AdGuard CLI.")
        defaultValue: "adguardvpn-cli"
        placeholder: "adguardvpn-cli"
    }

    SliderSetting {
        settingKey: "refreshIntervalSec"
        label: root.t("settings.refresh_interval.label", "Status Refresh Interval")
        description: root.t("settings.refresh_interval.description", "How often the widget polls `adguardvpn-cli status`.")
        defaultValue: 8
        minimum: 3
        maximum: 120
        unit: root.t("settings.unit.sec", "sec")
        leftIcon: "timer"
    }

    SliderSetting {
        settingKey: "locationsCount"
        label: root.t("settings.locations_count.label", "Location Samples")
        description: root.t("settings.locations_count.description", "Number of locations fetched for quick-connect suggestions.")
        defaultValue: 20
        minimum: 5
        maximum: 100
        unit: root.t("settings.unit.items", "items")
        leftIcon: "public"
    }

    SelectionSetting {
        settingKey: "connectStrategy"
        label: root.t("settings.connect_strategy.label", "Default Connect Strategy")
        description: root.t("settings.connect_strategy.description", "Behavior used by the main Connect action in the widget.")
        options: [
            { label: root.t("settings.connect_strategy.fastest", "Fastest"), value: "fastest" },
            { label: root.t("settings.connect_strategy.location", "Preferred Location"), value: "location" }
        ]
        defaultValue: "fastest"
    }

    StringSetting {
        settingKey: "defaultLocation"
        label: root.t("settings.default_location.label", "Preferred Location")
        description: root.t("settings.default_location.description", "City, country, or ISO used when strategy is Preferred Location.")
        defaultValue: ""
        placeholder: root.t("settings.default_location.placeholder", "Sao Paulo, Brazil")
    }

    SelectionSetting {
        settingKey: "ipStack"
        label: root.t("settings.ip_stack.label", "IP Stack")
        description: root.t("settings.ip_stack.description", "Append IPv4/IPv6 flags on connect operations.")
        options: [
            { label: root.t("settings.ip_stack.auto", "Auto"), value: "auto" },
            { label: root.t("settings.ip_stack.ipv4", "IPv4 only"), value: "ipv4" },
            { label: root.t("settings.ip_stack.ipv6", "IPv6 only"), value: "ipv6" }
        ]
        defaultValue: "auto"
    }

    ToggleSetting {
        settingKey: "autoRefreshLocations"
        label: root.t("settings.auto_refresh_locations.label", "Auto Refresh Locations")
        description: root.t("settings.auto_refresh_locations.description", "Periodically update ranked server locations in the popout.")
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "showLocationInBar"
        label: root.t("settings.show_text_in_bar.label", "Show Text in Bar")
        description: root.t("settings.show_text_in_bar.description", "Show connection text/location next to the icon in the horizontal bar.")
        defaultValue: true
    }
}
