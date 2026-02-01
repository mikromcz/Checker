/**
 * @description Translation system for Checker application
 * Loads translations from external INI files in the lang/ folder.
 * Supports automatic language detection with English fallback.
 * @author mikrom, ClaudeAI
 * @version 4.2.0
 *
 * Supported languages:
 * - English (en.ini) - default/fallback
 * - Czech (cs.ini) - language code 0405
 * - Slovak (sk.ini) - language code 041B
 * - Polish (pl.ini) - language code 0415
 * - German (de.ini) - language codes 0407, 0807, 0C07
 *
 * To add a new language:
 * 1. Copy en.ini to xx.ini (where xx is the language code)
 * 2. Translate all values in the [Strings] section
 * 3. Add the language code mapping in Translation.init()
 */
class Translation {
    static strings := ""
    static currentLanguage := ""
    static langFolder := ""

    /**
     * Initializes the translation system
     * Checks for manual override in Checker.ini, then detects system language
     */
    static init() {
        if (Translation.strings == "") {
            Translation.strings := Map()
            Translation.langFolder := A_ScriptDir . "\lib\Checker\lang\"

            ; First check for manual language override in Checker.ini
            manualLang := ""
            try {
                iniFile := A_ScriptDir . "\Checker.ini"
                if (FileExist(iniFile)) {
                    manualLang := IniRead(iniFile, "Checker", "language", "")
                }
            }

            if (manualLang != "" && FileExist(Translation.langFolder . manualLang . ".ini")) {
                ; Use manually configured language
                Translation.currentLanguage := manualLang
            } else {
                ; Map system language codes to INI file names
                langMap := Map(
                    "0405", "cs",  ; Czech
                    "041B", "sk",  ; Slovak
                    "0415", "pl",  ; Polish
                    "0407", "de",  ; German (Germany)
                    "0807", "de",  ; German (Switzerland)
                    "0C07", "de"   ; German (Austria)
                )

                ; Determine which language file to use based on system language
                Translation.currentLanguage := langMap.Has(A_Language) ? langMap[A_Language] : "en"
            }

            ; Load the language file (with English fallback)
            Translation.loadLanguageFile()
        }
    }

    /**
     * Loads translations from the appropriate INI file
     * Falls back to English for missing keys
     */
    static loadLanguageFile() {

        langFile := Translation.langFolder . Translation.currentLanguage . ".ini"
        fallbackFile := Translation.langFolder . "en.ini"

        ; First load English as fallback (ensures all keys exist)
        if (FileExist(fallbackFile)) {
            Translation.loadFromIni(fallbackFile)
        }

        ; Then load the target language (overwrites English values)
        if (Translation.currentLanguage != "en" && FileExist(langFile)) {
            Translation.loadFromIni(langFile)
        }
    }

    /**
     * Loads all strings from an INI file into the strings Map
     * Uses FileRead with UTF-8 encoding instead of IniRead to properly handle special characters
     * @param {String} iniFile Path to the INI file
     */
    static loadFromIni(iniFile) {
        try {
            ; Read file with UTF-8 encoding (IniRead doesn't handle UTF-8 properly)
            content := FileRead(iniFile, "UTF-8")

            ; Find [Strings] section and parse it
            inStringsSection := false

            for line in StrSplit(content, "`n", "`r") {
                line := Trim(line)

                ; Skip empty lines and comments
                if (line == "" || SubStr(line, 1, 1) == ";")
                    continue

                ; Check for section headers
                if (SubStr(line, 1, 1) == "[") {
                    inStringsSection := (line == "[Strings]")
                    continue
                }

                ; Parse key=value pairs in [Strings] section
                if (inStringsSection && InStr(line, "=")) {
                    parts := StrSplit(line, "=", , 2)
                    if (parts.Length >= 2) {
                        key := Trim(parts[1])
                        value := Trim(parts[2])
                        Translation.strings[key] := value
                    }
                }
            }
        } catch as e {
            ; If loading fails, strings Map remains empty or partial
            ; get() will return the key itself as fallback
        }
    }

    /**
     * Retrieves translated string for the given key
     * @param {String} key Translation key to lookup
     * @returns {String} Localized string or key itself if not found
     */
    static get(key) {
        Translation.init()
        return Translation.strings.Has(key) ? Translation.strings[key] : key
    }

    /**
     * Gets the current language code
     * @returns {String} Current language code (e.g., "en", "cs", "sk")
     */
    static getLanguage() {
        Translation.init()
        return Translation.currentLanguage
    }

    /**
     * Gets list of available languages by scanning lang folder
     * @returns {Array} Array of available language codes
     */
    static getAvailableLanguages() {
        Translation.init()
        languages := []
        Loop Files, Translation.langFolder . "*.ini" {
            langCode := StrReplace(A_LoopFileName, ".ini", "")
            languages.Push(langCode)
        }
        return languages
    }
}
