pragma Singleton

import QtQuick
import qs.Services
import "./i18n/en.js" as En
import "./i18n/pt_BR.js" as PtBR

QtObject {
    id: root

    readonly property string pluginId: "adguardVPplugin"

    property string languageOverride: "auto"
    property string localeName: {
        try {
            return (Qt.locale().name || "en_US").toString();
        } catch (error) {
            return "en_US";
        }
    }

    readonly property string normalizedLocale: normalizeLocale(languageOverride === "auto" ? localeName : languageOverride)
    readonly property var fallbackTranslations: En.translations
    readonly property var activeTranslations: getBundle(normalizedLocale)

    function normalizeLocale(value) {
        const raw = (value || "en_US").toString().replace("-", "_").trim();
        if (!raw) {
            return "en_US";
        }
        const lower = raw.toLowerCase();
        if (lower.indexOf("pt") === 0) {
            return "pt_BR";
        }
        return "en_US";
    }

    function getBundle(locale) {
        if (locale === "pt_BR") {
            return PtBR.translations;
        }
        return En.translations;
    }

    function tr(key, fallback, params) {
        let text = activeTranslations[key];
        if (text === undefined || text === null || text === "") {
            text = fallbackTranslations[key];
        }
        if (text === undefined || text === null || text === "") {
            text = fallback || key;
        }

        if (!params) {
            return text;
        }

        for (const param in params) {
            const value = params[param] === undefined || params[param] === null
                ? ""
                : params[param].toString();
            text = text.replace(new RegExp("\\{" + param + "\\}", "g"), value);
        }
        return text;
    }

    function loadSettings() {
        const stored = PluginService.loadPluginData(pluginId, "languageOverride");
        if (stored === undefined || stored === null || stored === "") {
            languageOverride = "auto";
            return;
        }
        languageOverride = stored.toString();
    }

    property var pluginDataConnection: Connections {
        target: PluginService
        function onPluginDataChanged(changedPluginId) {
            if (changedPluginId === root.pluginId) {
                loadSettings();
            }
        }
    }

    Component.onCompleted: loadSettings()
}
