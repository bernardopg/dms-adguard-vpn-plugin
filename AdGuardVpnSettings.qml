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

    StyledRect {
        width: parent.width
        radius: Theme.cornerRadius + 4
        color: Theme.surfaceContainerHigh
        border.width: 1
        border.color: Theme.withAlpha(Theme.primary, 0.2)
        implicitHeight: heroColumn.implicitHeight + Theme.spacingL * 2
        clip: true

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: Theme.withAlpha(Theme.primary, 0.16)
                }
                GradientStop {
                    position: 0.55
                    color: Theme.withAlpha(Theme.surfaceContainerHighest, 0.08)
                }
                GradientStop {
                    position: 1.0
                    color: Theme.withAlpha(Theme.surfaceContainer, 0.02)
                }
            }
        }

        Rectangle {
            width: 160
            height: 160
            radius: 80
            x: parent.width - width * 0.72
            y: -height * 0.35
            color: Theme.withAlpha(Theme.primary, 0.08)
        }

        Column {
            id: heroColumn
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingS

            StyledText {
                width: parent.width
                text: root.t("settings.eyebrow", "Premium control surface")
                color: Theme.surfaceVariantText
                font.pixelSize: Theme.fontSizeSmall - 1
                font.weight: Font.DemiBold
            }

            StyledText {
                width: parent.width
                text: root.t("settings.title", "AdGuard VPN Settings")
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.Bold
                color: Theme.surfaceText
                wrapMode: Text.WordWrap
            }

            StyledText {
                width: parent.width
                text: root.t("settings.subtitle", "Configure how the widget executes adguardvpn-cli and how aggressively it refreshes telemetry.")
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                wrapMode: Text.WordWrap
            }
        }
    }

    StyledText {
        width: parent.width
        text: root.t("settings.group.interface", "Interface")
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Font.DemiBold
        color: Theme.surfaceVariantText
    }

    SelectionSetting {
        settingKey: "languageOverride"
        label: root.t("settings.language.label", "Language")
        description: root.t("settings.language.description", "UI language for this plugin. Auto follows system locale.")
        options: [
            {
                label: root.t("settings.language.auto", "Auto (System)"),
                value: "auto"
            },
            {
                label: root.t("settings.language.en", "English"),
                value: "en_US"
            },
            {
                label: root.t("settings.language.pt_BR", "Portuguese (Brazil)"),
                value: "pt_BR"
            },
            {
                label: root.t("settings.language.es_ES", "Spanish"),
                value: "es_ES"
            },
            {
                label: root.t("settings.language.zh_CN", "Chinese (Simplified)"),
                value: "zh_CN"
            },
            {
                label: root.t("settings.language.hi_IN", "Hindi"),
                value: "hi_IN"
            },
            {
                label: root.t("settings.language.ar", "Arabic"),
                value: "ar"
            },
            {
                label: root.t("settings.language.bn_BD", "Bengali"),
                value: "bn_BD"
            },
            {
                label: root.t("settings.language.fr_FR", "French"),
                value: "fr_FR"
            },
            {
                label: root.t("settings.language.de_DE", "German"),
                value: "de_DE"
            },
            {
                label: root.t("settings.language.ja_JP", "Japanese"),
                value: "ja_JP"
            },
            {
                label: root.t("settings.language.ru_RU", "Russian"),
                value: "ru_RU"
            },
            {
                label: root.t("settings.language.ko_KR", "Korean"),
                value: "ko_KR"
            },
            {
                label: root.t("settings.language.id_ID", "Indonesian"),
                value: "id_ID"
            },
            {
                label: root.t("settings.language.tr_TR", "Turkish"),
                value: "tr_TR"
            },
            {
                label: root.t("settings.language.vi_VN", "Vietnamese"),
                value: "vi_VN"
            },
            {
                label: root.t("settings.language.it_IT", "Italian"),
                value: "it_IT"
            },
            {
                label: root.t("settings.language.pl_PL", "Polish"),
                value: "pl_PL"
            },
            {
                label: root.t("settings.language.nl_NL", "Dutch"),
                value: "nl_NL"
            },
            {
                label: root.t("settings.language.fa_IR", "Persian"),
                value: "fa_IR"
            },
            {
                label: root.t("settings.language.th_TH", "Thai"),
                value: "th_TH"
            },
            {
                label: root.t("settings.language.ur_PK", "Urdu"),
                value: "ur_PK"
            },
            {
                label: root.t("settings.language.ms_MY", "Malay"),
                value: "ms_MY"
            }
        ]
        defaultValue: "auto"
    }

    ToggleSetting {
        settingKey: "showLocationInBar"
        label: root.t("settings.show_text_in_bar.label", "Show Text in Bar")
        description: root.t("settings.show_text_in_bar.description", "Show connection text/location next to the icon in the horizontal bar.")
        defaultValue: true
    }

    StyledText {
        width: parent.width
        text: root.t("settings.group.runtime", "Runtime")
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Font.DemiBold
        color: Theme.surfaceVariantText
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

    StyledText {
        width: parent.width
        text: root.t("settings.group.behavior", "Connection behavior")
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Font.DemiBold
        color: Theme.surfaceVariantText
    }

    SelectionSetting {
        settingKey: "connectStrategy"
        label: root.t("settings.connect_strategy.label", "Default Connect Strategy")
        description: root.t("settings.connect_strategy.description", "Behavior used by the main Connect action in the widget.")
        options: [
            {
                label: root.t("settings.connect_strategy.fastest", "Fastest"),
                value: "fastest"
            },
            {
                label: root.t("settings.connect_strategy.location", "Preferred Location"),
                value: "location"
            }
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
            {
                label: root.t("settings.ip_stack.auto", "Auto"),
                value: "auto"
            },
            {
                label: root.t("settings.ip_stack.ipv4", "IPv4 only"),
                value: "ipv4"
            },
            {
                label: root.t("settings.ip_stack.ipv6", "IPv6 only"),
                value: "ipv6"
            }
        ]
        defaultValue: "auto"
    }

    StyledText {
        width: parent.width
        text: root.t("settings.group.automation", "Automation")
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Font.DemiBold
        color: Theme.surfaceVariantText
    }

    ToggleSetting {
        settingKey: "autoRefreshLocations"
        label: root.t("settings.auto_refresh_locations.label", "Auto Refresh Locations")
        description: root.t("settings.auto_refresh_locations.description", "Periodically update ranked server locations in the popout.")
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "autoConnectOnStartup"
        label: root.t("settings.auto_connect_startup.label", "Auto Connect on Startup")
        description: root.t("settings.auto_connect_startup.description", "Automatically trigger Connect when the plugin/session starts.")
        defaultValue: false
    }

    ToggleSetting {
        settingKey: "autoReconnectOnDrop"
        label: root.t("settings.auto_reconnect_drop.label", "Auto Reconnect on Drop")
        description: root.t("settings.auto_reconnect_drop.description", "Automatically reconnect when the tunnel drops unexpectedly.")
        defaultValue: false
    }
}
