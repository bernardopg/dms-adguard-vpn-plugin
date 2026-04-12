pragma Singleton

import QtQuick
import qs.Services
import "./i18n/en.js" as En
import "./i18n/pt_BR.js" as PtBR
import "./i18n/es_ES.js" as EsES
import "./i18n/zh_CN.js" as ZhCN
import "./i18n/hi_IN.js" as HiIN
import "./i18n/ar.js" as Ar
import "./i18n/bn_BD.js" as BnBD
import "./i18n/fr_FR.js" as FrFR
import "./i18n/de_DE.js" as DeDE
import "./i18n/ja_JP.js" as JaJP
import "./i18n/ru_RU.js" as RuRU
import "./i18n/ko_KR.js" as KoKR
import "./i18n/id_ID.js" as IdID
import "./i18n/tr_TR.js" as TrTR
import "./i18n/vi_VN.js" as ViVN
import "./i18n/it_IT.js" as ItIT
import "./i18n/pl_PL.js" as PlPL
import "./i18n/nl_NL.js" as NlNL
import "./i18n/fa_IR.js" as FaIR
import "./i18n/th_TH.js" as ThTH
import "./i18n/ur_PK.js" as UrPK
import "./i18n/ms_MY.js" as MsMY

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
        if (lower.indexOf("es") === 0) {
            return "es_ES";
        }
        if (lower.indexOf("zh") === 0) {
            return "zh_CN";
        }
        if (lower.indexOf("hi") === 0) {
            return "hi_IN";
        }
        if (lower.indexOf("ar") === 0) {
            return "ar";
        }
        if (lower.indexOf("bn") === 0) {
            return "bn_BD";
        }
        if (lower.indexOf("fr") === 0) {
            return "fr_FR";
        }
        if (lower.indexOf("de") === 0) {
            return "de_DE";
        }
        if (lower.indexOf("ja") === 0) {
            return "ja_JP";
        }
        if (lower.indexOf("ru") === 0) {
            return "ru_RU";
        }
        if (lower.indexOf("ko") === 0) {
            return "ko_KR";
        }
        if (lower.indexOf("id") === 0 || lower.indexOf("in") === 0) {
            return "id_ID";
        }
        if (lower.indexOf("tr") === 0) {
            return "tr_TR";
        }
        if (lower.indexOf("vi") === 0) {
            return "vi_VN";
        }
        if (lower.indexOf("it") === 0) {
            return "it_IT";
        }
        if (lower.indexOf("pl") === 0) {
            return "pl_PL";
        }
        if (lower.indexOf("nl") === 0) {
            return "nl_NL";
        }
        if (lower.indexOf("fa") === 0) {
            return "fa_IR";
        }
        if (lower.indexOf("th") === 0) {
            return "th_TH";
        }
        if (lower.indexOf("ur") === 0) {
            return "ur_PK";
        }
        if (lower.indexOf("ms") === 0) {
            return "ms_MY";
        }
        return "en_US";
    }

    function getBundle(locale) {
        if (locale === "pt_BR") {
            return PtBR.translations;
        }
        if (locale === "es_ES") {
            return EsES.translations;
        }
        if (locale === "zh_CN") {
            return ZhCN.translations;
        }
        if (locale === "hi_IN") {
            return HiIN.translations;
        }
        if (locale === "ar") {
            return Ar.translations;
        }
        if (locale === "bn_BD") {
            return BnBD.translations;
        }
        if (locale === "fr_FR") {
            return FrFR.translations;
        }
        if (locale === "de_DE") {
            return DeDE.translations;
        }
        if (locale === "ja_JP") {
            return JaJP.translations;
        }
        if (locale === "ru_RU") {
            return RuRU.translations;
        }
        if (locale === "ko_KR") {
            return KoKR.translations;
        }
        if (locale === "id_ID") {
            return IdID.translations;
        }
        if (locale === "tr_TR") {
            return TrTR.translations;
        }
        if (locale === "vi_VN") {
            return ViVN.translations;
        }
        if (locale === "it_IT") {
            return ItIT.translations;
        }
        if (locale === "pl_PL") {
            return PlPL.translations;
        }
        if (locale === "nl_NL") {
            return NlNL.translations;
        }
        if (locale === "fa_IR") {
            return FaIR.translations;
        }
        if (locale === "th_TH") {
            return ThTH.translations;
        }
        if (locale === "ur_PK") {
            return UrPK.translations;
        }
        if (locale === "ms_MY") {
            return MsMY.translations;
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
            const value = params[param] === undefined || params[param] === null ? "" : params[param].toString();
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
