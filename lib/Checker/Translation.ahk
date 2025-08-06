class Translation {
    static strings := ""

    static init() {
        if (Translation.strings == "") {
            Translation.strings := Map()

            ; Detect Czech system language (0405 = Czech)
            isCzech := (A_Language = "0405") ; 0809 Roman

            ; Main application strings
            Translation.strings["app_title"] := isCzech ? "Checker - Nástroj pro ověření souřadnic" : "Checker - Coordinate Verification Tool"
            Translation.strings["ready"] := isCzech ? "Připraven" : "Ready"
            Translation.strings["initializing_webview"] := isCzech ? "Inicializace WebView2..." : "Initializing WebView2..."
            Translation.strings["loading_url"] := isCzech ? "Načítání URL..." : "Loading URL..."
            Translation.strings["page_loaded"] := isCzech ? "Stránka úspěšně načtena" : "Page loaded successfully"
            Translation.strings["dom_loaded"] := isCzech ? "DOM načten - Vyplňování souřadnic..." : "DOM loaded - Filling coordinates..."
            Translation.strings["coordinates_filled"] := isCzech ? "Souřadnice úspěšně vyplněny - Odešlete formulář a čekejte..." : "Coordinates filled successfully - Submit form and wait..."
            Translation.strings["geocheck_captcha"] := isCzech ? "Souřadnice úspěšně vyplněny - Vyřešte captcha a odešlete formulář" : "Coordinates filled successfully - Please solve captcha and submit form"
            Translation.strings["refreshing"] := isCzech ? "Obnovování stránky..." : "Refreshing page..."
            Translation.strings["no_url_refresh"] := isCzech ? "Žádná URL k obnovení" : "No URL to refresh"
            Translation.strings["checking"] := isCzech ? "Kontrola" : "Checking"
            Translation.strings["correct"] := isCzech ? "Správně!" : "Correct!"
            Translation.strings["wrong"] := isCzech ? "Špatně!" : "Wrong!"
            Translation.strings["result_checking_disabled"] := isCzech ? "Kontrola výsledků zakázána" : "Result checking disabled"

            ; Menu strings
            Translation.strings["menu_file"] := isCzech ? "&Soubor" : "&File"
            Translation.strings["menu_preferences"] := isCzech ? "&Předvolby..." : "&Preferences..."
            Translation.strings["menu_exit"] := isCzech ? "&Konec" : "E&xit"
            Translation.strings["menu_help"] := isCzech ? "&Nápověda" : "&Help"
            Translation.strings["menu_about"] := isCzech ? "&O aplikaci..." : "&About..."

            ; Preferences dialog
            Translation.strings["preferences_title"] := isCzech ? "Předvolby" : "Preferences"
            Translation.strings["result_checking"] := isCzech ? "Kontrola výsledků:" : "Result Checking:"
            Translation.strings["result_checking_desc"] := isCzech ? "Kontrolovat výsledek a vrátit exit kód (1=Správně, 2=Špatně)" : "Check result and return exit code (1=Correct, 2=Wrong)"
            Translation.strings["debug_mode"] := isCzech ? "Režim ladění:" : "Debug Mode:"
            Translation.strings["debug_mode_desc"] := isCzech ? "Povolit režim ladění (zobrazit dodatečné informace)" : "Enable debug mode (show additional information)"
            Translation.strings["audio_feedback"] := isCzech ? "Zvuková odezva:" : "Audio Feedback:"
            Translation.strings["audio_feedback_desc"] := isCzech ? "Přehrát zvuk pro správné/nesprávné ověření" : "Play sound for correct/incorrect verification"
            Translation.strings["clipboard"] := isCzech ? "Schránka:" : "Clipboard:"
            Translation.strings["clipboard_desc"] := isCzech ? "Kopírovat zprávu autora do schránky" : "Copy owner's message to clipboard"
            Translation.strings["timeout"] := isCzech ? "Časový limit načítání stránky (sekundy):" : "Page Load Timeout (seconds):"
            Translation.strings["timeout_desc"] := isCzech ? "(prázdné = bez limitu)" : "(empty = no timeout)"
            Translation.strings["pgc_integration"] := isCzech ? "Integrace Project-GC:" : "Project-GC Integration:"
            Translation.strings["pgc_integration_desc"] := isCzech ? "Zkusit se přihlásit na project-gc.com pro challenge keše" : "Try to login to project-gc.com for challenge caches"
            Translation.strings["ok"] := isCzech ? "&OK" : "&OK"
            Translation.strings["cancel"] := isCzech ? "&Zrušit" : "&Cancel"

            ; About dialog
            Translation.strings["about_title"] := isCzech ? "O aplikaci Checker" : "About Checker"
            Translation.strings["about_version"] := isCzech ? "Verze 4.0.0 (AutoHotkey v2 + WebView2)" : "Version 4.0.0 (AutoHotkey v2 + WebView2)"
            Translation.strings["current_parameters"] := isCzech ? "Aktuální parametry:" : "Current Parameters:"
            Translation.strings["service"] := isCzech ? "Služba" : "Service"
            Translation.strings["latitude"] := isCzech ? "Zeměpisná šířka" : "Latitude"
            Translation.strings["longitude"] := isCzech ? "Zeměpisná délka" : "Longitude"
            Translation.strings["coordinates"] := isCzech ? "Souřadnice" : "Coordinates"
            Translation.strings["target_url"] := isCzech ? "Cílová URL:" : "Target URL:"
            Translation.strings["none"] := isCzech ? "(žádné)" : "(none)"
            Translation.strings["not_provided"] := isCzech ? "(neposkytnuty)" : "(not provided)"
            Translation.strings["no_url_provided"] := isCzech ? "(žádná URL poskytnuta)" : "(no URL provided)"
            Translation.strings["characters_total"] := isCzech ? "znaků celkem" : "characters total"

            ; Clipboard strings
            Translation.strings["clipboard_copied_title"] := isCzech ? "Zpráva autora zkopírována" : "Owner's Message Copied"
            Translation.strings["clipboard_success"] := isCzech ? "✓ Úspěšně zkopírováno do schránky:" : "✓ Successfully copied to clipboard:"
            Translation.strings["clipboard_failed"] := isCzech ? "✗ Ověření schránky selhalo - očekáváno:" : "✗ Clipboard verification failed - expected:"
            Translation.strings["clipboard_got"] := isCzech ? "získáno:" : "got:"
            Translation.strings["clipboard_copy_error"] := isCzech ? "Chyba kopírování do schránky:" : "Clipboard copy error:"
            Translation.strings["clipboard_not_supported"] := isCzech ? "Kopírování do schránky není podporováno pro službu" : "Clipboard copy not supported for"
            Translation.strings["clipboard_service"] := isCzech ? "služba" : "service"
            Translation.strings["attempting_clipboard"] := isCzech ? "Pokus o zkopírování zprávy autora..." : "Attempting to copy owner's message..."

            ; Error messages
            Translation.strings["error"] := isCzech ? "Chyba" : "Error"
            Translation.strings["webview_error"] := isCzech ? "Chyba WebView2:" : "WebView2 Error:"
            Translation.strings["webview_init_failed"] := isCzech ? "Inicializace WebView2 selhala:" : "Failed to initialize WebView2:"
            Translation.strings["navigation_failed"] := isCzech ? "Navigace selhala - WebNavigationKind:" : "Navigation failed - WebNavigationKind:"
            Translation.strings["loading_timeout"] := isCzech ? "Časový limit načítání - Zkontrolujte URL nebo síťové připojení" : "Loading timeout - Check URL or network connection"
            Translation.strings["unknown_service"] := isCzech ? "Neznámá služba:" : "Unknown service:"
            Translation.strings["see_documentation"] := isCzech ? "- Viz dokumentace pro podporované služby" : "- See documentation for supported services"
            Translation.strings["dead_service_warning"] := isCzech ? "Varování: Stránka" : "Warning: Site"
            Translation.strings["dead_service_desc"] := isCzech ? "je mrtvá. Nelze nic vyplnit/zkontrolovat. Kontaktujte autora keše pro změnu ověřovací služby." : "is dead. Cannot fill/check anything. Contact cache author to change verification service."
            Translation.strings["dead_since"] := isCzech ? "(mrtvá od" : "(dead since"
        }
    }

    static get(key) {
        Translation.init()
        return Translation.strings.Has(key) ? Translation.strings[key] : key
    }
}