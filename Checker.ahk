/**
 * @description Checker - Coordinate verification tool for geocaching services
 * Automates coordinate submission and verification across multiple geocaching
 * coordinate checker websites using WebView2 technology.
 * @author mikrom, ClaudeAI
 * @version 4.2.0
 * @url https://www.geoget.cz/doku.php/user:skript:checker
 * @forum https://forum.geocaching.cz/t/checker-klikatko-na-overeni-souradnic/24502
 * @icon https://icons8.com/icon/18401/Thumb-Up
 */

#Requires AutoHotkey v2.0
#NoTrayIcon
#Include lib\WebView2\WebView2.ahk
#Include lib\Promise.ahk
#Include lib\ComVar.ahk
#Include lib\Checker\ServiceRegistry.ahk

/**
 * Application constants for consistent values across the codebase
 */
class CheckerConstants {
    ; Window dimensions
    static MIN_WIDTH := 1000
    static MIN_HEIGHT := 600
    static STATUS_BAR_HEIGHT := 20
    static WINDOW_BORDER_WIDTH := 16
    static WINDOW_DECORATION_HEIGHT := 59

    ; Exit codes
    static EXIT_NORMAL := 0
    static EXIT_CORRECT := 1
    static EXIT_WRONG := 2
    static EXIT_DEAD := 3
    static EXIT_INVALID_PARAMS := 4

    ; Timeouts (milliseconds)
    static DEFAULT_TIMEOUT_MS := 10000
    static RESULT_CHECK_INTERVAL_MS := 200
    static DOM_READY_DELAY_MS := 500
    static CAPTCHA_FOCUS_DELAY_MS := 100
}

/**
 * Settings manager for the Checker application
 * Handles loading and saving settings from/to INI file
 */
class CheckerSettings {
    /**
     * Constructor - initializes settings with defaults
     * @param {String} iniFile Path to INI file (default: "Checker.ini")
     */
    __New(iniFile := "Checker.ini") {
        this.iniFile := iniFile
        this.answer := 1
        this.debug := 0
        this.beep := 0
        this.copymsg := 1
        this.timeout := 10
        this.language := ""  ; Empty = auto-detect, otherwise language code (en, cs, sk)
        this.windowWidth := CheckerConstants.MIN_WIDTH
        this.windowHeight := CheckerConstants.MIN_HEIGHT
    }

    /**
     * Loads settings from INI file
     * Uses defaults if file doesn't exist or loading fails
     */
    load() {
        try {
            if (FileExist(this.iniFile)) {
                this.answer := IniRead(this.iniFile, "Checker", "answer", 1)
                this.copymsg := IniRead(this.iniFile, "Checker", "copymsg", 1)
                this.timeout := IniRead(this.iniFile, "Checker", "timeout", "")
                this.debug := IniRead(this.iniFile, "Checker", "debug", 0)
                this.beep := IniRead(this.iniFile, "Checker", "beep", 0)
                this.language := IniRead(this.iniFile, "Checker", "language", "")
                this.windowWidth := Integer(IniRead(this.iniFile, "Checker", "windowWidth", CheckerConstants.MIN_WIDTH))
                this.windowHeight := Integer(IniRead(this.iniFile, "Checker", "windowHeight", CheckerConstants.MIN_HEIGHT))

                ; Validate window size constraints
                this.validateWindowSize()
            }
        } catch {
            ; Use defaults if loading fails
        }
    }

    /**
     * Saves current settings to INI file
     * @returns {Boolean} True if save succeeded, false otherwise
     */
    save() {
        try {
            IniWrite(this.answer, this.iniFile, "Checker", "answer")
            IniWrite(this.copymsg, this.iniFile, "Checker", "copymsg")
            IniWrite(this.timeout, this.iniFile, "Checker", "timeout")
            IniWrite(this.debug, this.iniFile, "Checker", "debug")
            IniWrite(this.beep, this.iniFile, "Checker", "beep")
            IniWrite(this.language, this.iniFile, "Checker", "language")
            IniWrite(this.windowWidth, this.iniFile, "Checker", "windowWidth")
            IniWrite(this.windowHeight, this.iniFile, "Checker", "windowHeight")
            return true
        } catch as e {
            MsgBox("Failed to save settings: " . e.message, "Error", "OK Icon!")
            return false
        }
    }

    /**
     * Validates and constrains window size to acceptable range
     */
    validateWindowSize() {
        if (this.windowWidth < CheckerConstants.MIN_WIDTH)
            this.windowWidth := CheckerConstants.MIN_WIDTH
        if (this.windowHeight < CheckerConstants.MIN_HEIGHT)
            this.windowHeight := CheckerConstants.MIN_HEIGHT
        if (this.windowWidth > A_ScreenWidth)
            this.windowWidth := A_ScreenWidth
        if (this.windowHeight > A_ScreenHeight)
            this.windowHeight := A_ScreenHeight
    }
}

/**
 * Coordinate validator and command-line parser
 * Handles parsing and validation of coordinate parameters
 */
class CoordinateValidator {
    /**
     * Constructor - initializes coordinate fields
     */
    __New() {
        this.service := ""
        this.lat := ""
        this.latdeg := ""
        this.latmin := ""
        this.latdec := ""
        this.lon := ""
        this.londeg := ""
        this.lonmin := ""
        this.londec := ""
        this.url := ""
        this.isValid := false
        this.errorMessage := ""
    }

    /**
     * Parses command line arguments and validates them
     * Expected format: service lat latdeg latmin latdec lon londeg lonmin londec url
     * @returns {Boolean} True if parameters are valid, false otherwise
     */
    parseCommandLine() {
        this.isValid := false
        this.errorMessage := ""

        if (A_Args.Length >= 10) {
            this.service := A_Args[1]
            this.lat := A_Args[2]
            this.latdeg := A_Args[3]
            this.latmin := A_Args[4]
            this.latdec := A_Args[5]
            this.lon := A_Args[6]
            this.londeg := A_Args[7]
            this.lonmin := A_Args[8]
            this.londec := A_Args[9]
            this.url := A_Args[10]

            this.isValid := this.validate()
        } else {
            this.errorMessage := "Insufficient parameters provided (" . A_Args.Length . " received, 10 required)"
        }

        return this.isValid
    }

    /**
     * Validates coordinate parameters for correct format and ranges
     * @returns {Boolean} True if all parameters are valid, false otherwise
     */
    validate() {
        ; Validate coordinate directions
        if (this.lat != "N" && this.lat != "S") {
            this.errorMessage := "Invalid latitude direction '" . this.lat . "' (must be N or S)"
            return false
        }

        if (this.lon != "E" && this.lon != "W") {
            this.errorMessage := "Invalid longitude direction '" . this.lon . "' (must be E or W)"
            return false
        }

        ; Validate that coordinate numbers are numeric
        if (!IsNumber(this.latdeg) || !IsNumber(this.latmin) || !IsNumber(this.latdec)) {
            this.errorMessage := "Invalid latitude coordinates (latdeg='" . this.latdeg . "', latmin='" . this.latmin . "', latdec='" . this.latdec . "') - must be numbers"
            return false
        }

        if (!IsNumber(this.londeg) || !IsNumber(this.lonmin) || !IsNumber(this.londec)) {
            this.errorMessage := "Invalid longitude coordinates (londeg='" . this.londeg . "', lonmin='" . this.lonmin . "', londec='" . this.londec . "') - must be numbers"
            return false
        }

        ; Validate coordinate ranges
        latDeg := Integer(this.latdeg)
        lonDeg := Integer(this.londeg)
        latMin := Integer(this.latmin)
        lonMin := Integer(this.lonmin)

        if (latDeg < 0 || latDeg > 90) {
            this.errorMessage := "Invalid latitude degrees '" . this.latdeg . "' (must be 0-90)"
            return false
        }

        if (lonDeg < 0 || lonDeg > 180) {
            this.errorMessage := "Invalid longitude degrees '" . this.londeg . "' (must be 0-180)"
            return false
        }

        if (latMin < 0 || latMin >= 60) {
            this.errorMessage := "Invalid latitude minutes '" . this.latmin . "' (must be 0-59)"
            return false
        }

        if (lonMin < 0 || lonMin >= 60) {
            this.errorMessage := "Invalid longitude minutes '" . this.lonmin . "' (must be 0-59)"
            return false
        }

        return true
    }

    /**
     * Checks if all required coordinate parameters are present
     * @returns {Boolean} True if all coordinate fields have values
     */
    hasCoordinates() {
        return (this.lat != "" && this.latdeg != "" && this.latmin != "" && this.latdec != "" &&
            this.lon != "" && this.londeg != "" && this.lonmin != "" && this.londec != "")
    }
}

class CheckerApp {
    /**
     * Main application entry point
     * Initializes and runs the Checker application
     */
    static main() {
        app := CheckerApp()
        app.setupIcons()
        app.loadSettings()
        app.parseCommandLine()
        app.createGUI()
        app.gui.Show()
    }

    /**
     * Constructor for CheckerApp
     * Initializes application properties and default settings
     */
    __New() {
        ; Coordinate fields
        this.service := ""
        this.lat := ""
        this.latdeg := ""
        this.latmin := ""
        this.latdec := ""
        this.lon := ""
        this.londeg := ""
        this.lonmin := ""
        this.londec := ""
        this.url := ""

        ; WebView2 and state management
        this.webView := ""
        this.webViewController := ""
        this.isCheckingResults := false
        this.checkTimer := ""
        this.finalExitCode := 0
        this.coordinatesFilled := false
        this.clipboardCopied := false
        this.version := this.getVersionFromScript()

        ; Use CheckerSettings for settings management
        this.settingsManager := CheckerSettings()
        ; Create settings proxy for backwards compatibility
        this.settings := {
            answer: 1,
            debug: 0,
            beep: 0,
            copymsg: 1,
            timeout: 10,
            language: "",
            windowWidth: CheckerConstants.MIN_WIDTH,
            windowHeight: CheckerConstants.MIN_HEIGHT
        }

        ; Use CoordinateValidator for parameter validation
        this.validator := CoordinateValidator()
    }

    setupIcons() {
        ; Set application icon if available (AHK v2 equivalent of Menu, Tray, Icon)
        if (FileExist(A_ScriptDir "\Checker.ico")) {
            TraySetIcon(A_ScriptDir "\Checker.ico", , true)  ; true = freeze
        }
    }

    /**
     * Parses command line arguments and validates parameters
     * Delegates to CoordinateValidator for parsing and validation
     */
    parseCommandLine() {
        this.hasValidParameters := this.validator.parseCommandLine()
        this.parameterError := this.validator.errorMessage

        if (this.hasValidParameters) {
            ; Copy validated values to CheckerApp for compatibility
            this.service := this.validator.service
            this.lat := this.validator.lat
            this.latdeg := this.validator.latdeg
            this.latmin := this.validator.latmin
            this.latdec := this.validator.latdec
            this.lon := this.validator.lon
            this.londeg := this.validator.londeg
            this.lonmin := this.validator.lonmin
            this.londec := this.validator.londec
            this.url := this.validator.url
        } else {
            this.finalExitCode := CheckerConstants.EXIT_INVALID_PARAMS
        }
    }

    createGUI() {
        ; Calculate centered position based on saved client size
        ; Add approximate window decoration size for positioning
        approxWindowWidth := this.settings.windowWidth + CheckerConstants.WINDOW_BORDER_WIDTH
        approxWindowHeight := this.settings.windowHeight + CheckerConstants.WINDOW_DECORATION_HEIGHT
        centerX := (A_ScreenWidth - approxWindowWidth) // 2
        centerY := (A_ScreenHeight - approxWindowHeight) // 2

        ; Create main GUI window
        minSizeStr := "+Resize +MinSize" . CheckerConstants.MIN_WIDTH . "x" . CheckerConstants.MIN_HEIGHT
        this.gui := Gui(minSizeStr, Translation.get("app_title"))
        this.gui.OnEvent("Close", (*) => this.exitApp())
        this.gui.OnEvent("Size", (*) => this.onWindowResize())

        this.gui.MarginX := 0
        this.gui.MarginY := 0

        ; Create menu bar
        this.createMenuBar()

        ; Create WebView2 container area (starts from y0 since menu bar is native)
        containerHeight := this.settings.windowHeight - CheckerConstants.STATUS_BAR_HEIGHT
        this.webViewContainer := this.gui.AddText("x0 y0 w" . this.settings.windowWidth . " h" . containerHeight . " +Border")

        ; Create status bar at bottom
        this.createStatusBar()

        ; Set initial GUI client size (not window size) - this prevents size drift
        this.gui.Move(centerX, centerY)
        ; Use SetClientSize to set the exact client dimensions we want
        DllCall("SetWindowPos", "Ptr", this.gui.Hwnd, "Ptr", 0, "Int", centerX, "Int", centerY,
                "Int", this.settings.windowWidth + CheckerConstants.WINDOW_BORDER_WIDTH,
                "Int", this.settings.windowHeight + CheckerConstants.WINDOW_DECORATION_HEIGHT, "UInt", 0x0004)

        ; Initialize WebView2
        this.initializeWebView()

        ; Set up hotkeys
        this.setupHotkeys()
    }

    createMenuBar() {
        ; Create a proper menu bar using AutoHotkey's menu system
        this.mainMenu := MenuBar()

        ; Create File menu
        this.fileMenu := Menu()
        this.fileMenu.Add(Translation.get("menu_refresh"), (*) => this.refreshAndFill())
        this.fileMenu.Add()  ; Separator
        this.fileMenu.Add(Translation.get("menu_preferences"), (*) => this.showPreferences())
        this.fileMenu.Add()  ; Separator
        this.fileMenu.Add(Translation.get("menu_exit"), (*) => this.exitApp())

        ; Create Help menu
        this.helpMenu := Menu()
        this.helpMenu.Add(Translation.get("menu_about"), (*) => this.showAbout())

        ; Add menus to menu bar
        this.mainMenu.Add(Translation.get("menu_file"), this.fileMenu)
        this.mainMenu.Add(Translation.get("menu_help"), this.helpMenu)

        ; Attach menu bar to GUI
        this.gui.MenuBar := this.mainMenu
    }

    createStatusBar() {
        ; Create status bar area
        statusY := this.settings.windowHeight - CheckerConstants.STATUS_BAR_HEIGHT
        statusTextY := statusY + 2
        this.statusBar := this.gui.AddText("x0 y" . statusY . " w" . this.settings.windowWidth . " h" . CheckerConstants.STATUS_BAR_HEIGHT . " +0x1000")  ; SS_SUNKEN
        this.statusBar.BackColor := "0xF0F0F0"

        ; Left status text for loading/page messages (much wider for debug messages)
        leftTextWidth := this.settings.windowWidth - 120
        this.statusTextLeft := this.gui.AddText("x10 y" . statusTextY . " w" . leftTextWidth . " h16", Translation.get("ready"))

        ; Right status text for checking/results (adjusted position and width)
        rightTextX := this.settings.windowWidth - 100
        this.statusTextRight := this.gui.AddText("x" . rightTextX . " y" . statusTextY . " w90 h16 +Right", "")
    }

    /**
     * Loads application settings from INI file
     * Delegates to CheckerSettings and syncs to local settings object
     */
    loadSettings() {
        this.settingsManager.load()
        this.syncSettingsFromManager()
    }

    /**
     * Syncs settings from the settings manager to the local settings object
     * Maintains backwards compatibility with existing code
     */
    syncSettingsFromManager() {
        this.settings.answer := this.settingsManager.answer
        this.settings.copymsg := this.settingsManager.copymsg
        this.settings.timeout := this.settingsManager.timeout
        this.settings.debug := this.settingsManager.debug
        this.settings.beep := this.settingsManager.beep
        this.settings.language := this.settingsManager.language
        this.settings.windowWidth := this.settingsManager.windowWidth
        this.settings.windowHeight := this.settingsManager.windowHeight
    }

    /**
     * Syncs settings from the local settings object to the settings manager
     * Called before saving to ensure manager has latest values
     */
    syncSettingsToManager() {
        this.settingsManager.answer := this.settings.answer
        this.settingsManager.copymsg := this.settings.copymsg
        this.settingsManager.timeout := this.settings.timeout
        this.settingsManager.debug := this.settings.debug
        this.settingsManager.beep := this.settings.beep
        this.settingsManager.language := this.settings.language
        this.settingsManager.windowWidth := this.settings.windowWidth
        this.settingsManager.windowHeight := this.settings.windowHeight
    }

    saveSettings() {
        ; Sync local settings to manager and save
        this.syncSettingsToManager()
        this.settingsManager.save()
    }

    showPreferences() {
        ; Create preferences dialog
        prefGui := Gui("+ToolWindow", Translation.get("preferences_title"))
        prefGui.MarginX := 15
        prefGui.MarginY := 15

        ; Check result checkbox
        answerCb := prefGui.AddCheckbox("x15 y15 w300 Checked" . this.settings.answer,
            Translation.get("result_checking_desc"))

        ; Copy message checkbox
        copymsgCb := prefGui.AddCheckbox("x15 y45 w300 Checked" . this.settings.copymsg,
            Translation.get("clipboard_desc"))

        ; Timeout field (input first, then label)
        timeoutEdit := prefGui.AddEdit("x15 y75 w30", this.settings.timeout)
        prefGui.AddText("x50 y78", Translation.get("timeout_label"))

        ; Debug checkbox
        debugCb := prefGui.AddCheckbox("x15 y105 w300 Checked" . this.settings.debug,
            Translation.get("debug_mode_desc"))

        ; Play sound checkbox (disabled - not implemented)
        beepCb := prefGui.AddCheckbox("x15 y135 w300 Checked" . this.settings.beep . " +Disabled",
            Translation.get("audio_feedback_desc"))

        ; Language dropdown
        prefGui.AddText("x15 y168", Translation.get("language_label"))
        langDdl := prefGui.AddDropDownList("x80 y165 w80")

        ; Populate language dropdown
        availableLangs := Translation.getAvailableLanguages()
        langOptions := ["auto"]  ; First option is auto-detect
        for lang in availableLangs {
            langOptions.Push(lang)
        }
        langDdl.Add(langOptions)

        ; Select current language in dropdown
        if (this.settings.language == "") {
            langDdl.Choose(1)  ; "auto"
        } else {
            ; Find index of current language
            for i, lang in langOptions {
                if (lang == this.settings.language) {
                    langDdl.Choose(i)
                    break
                }
            }
        }

        ; Buttons
        okBtn := prefGui.AddButton("x85 y200 w75 h25", Translation.get("ok"))
        cancelBtn := prefGui.AddButton("x170 y200 w75 h25", Translation.get("cancel"))

        ; Button events
        okBtn.OnEvent("Click", (*) => this.savePreferences(answerCb, debugCb, beepCb, copymsgCb, timeoutEdit, langDdl, prefGui))
        cancelBtn.OnEvent("Click", (*) => prefGui.Destroy())
        prefGui.OnEvent("Escape", (*) => prefGui.Destroy())

        ; Show dialog
        prefGui.Show("w330 h240")
    }

    savePreferences(answerCb, debugCb, beepCb, copymsgCb, timeoutEdit, langDdl, prefGui) {
        ; Save settings from dialog controls
        this.settings.answer := answerCb.Value
        this.settings.debug := debugCb.Value
        this.settings.beep := beepCb.Value
        this.settings.copymsg := copymsgCb.Value
        this.settings.timeout := timeoutEdit.Text

        ; Save language (empty string for "auto")
        selectedLang := langDdl.Text
        this.settings.language := (selectedLang == "auto") ? "" : selectedLang

        this.saveSettings()
        prefGui.Destroy()
    }

    showAbout() {
        aboutText := Translation.get("app_title") . "`n"
        aboutText .= "Version " . this.version . " (AutoHotkey v2 + WebView2)" . "`n`n"

        ; Format parameters section with better alignment and readability
        aboutText .= Translation.get("current_parameters") . "`n"
        aboutText .= "═══════════════════════════════════════`n"
        aboutText .= Translation.get("service") . ":    " . (this.service != "" ? this.service : Translation.get("none")) . "`n"

        ; Format coordinates nicely if they exist
        if (this.hasValidCoordinates()) {
            aboutText .= Translation.get("latitude") . ":   " . this.lat . " " . this.latdeg . Chr(176) . " " . this.latmin . "." . this.latdec .
            "'" . "`n"
            aboutText .= Translation.get("longitude") . ":  " . this.lon . " " . Format("{:03d}", Integer(this.londeg)) . Chr(176) . " " .
            this.lonmin . "." . this.londec . "'" . "`n"
        } else {
            aboutText .= Translation.get("coordinates") . ": " . Translation.get("not_provided") . "`n"
        }

        aboutText .= "`n" . Translation.get("target_url") . "`n"
        aboutText .= "───────────────────────────────────────`n"
        if (this.url != "") {
            aboutText .= this.url
        } else {
            aboutText .= Translation.get("no_url_provided")
        }

        MsgBox(aboutText, Translation.get("about_title"), "OK")
    }

    initializeWebView() {
        try {
            ; Update status
            this.updateStatus(Translation.get("initializing_webview"))

            ; Create WebView2 controller
            WebView2.CreateControllerAsync(this.webViewContainer.Hwnd)
            .then((controller) => this.onWebViewCreated(controller))
            .catch((error) => this.onWebViewError(error))
        } catch as e {
            this.updateStatus("Failed to initialize WebView2: " . e.message)
        }
    }

    onWebViewCreated(controller) {
        this.webViewController := controller
        this.webView := controller.CoreWebView2

        ; Set up event handlers
        this.webView.add_NavigationCompleted(this.onNavigationCompleted.Bind(this))
        this.webView.add_DOMContentLoaded(this.onDOMContentLoaded.Bind(this))

        ; Navigate to URL if provided
        if (this.url != "") {
            ; Check if service is dead before navigating to potentially bad URL
            serviceInstance := ServiceRegistry.createService(this.service, this)
            if (serviceInstance.isDead) {
                ; Show custom dead service page instead of loading the dead URL
                this.webView.NavigateToString(this.generateDeadServicePage(serviceInstance))
                this.finalExitCode := 3
                this.updateStatus(Translation.get("dead_service_warning") . " " . serviceInstance.siteName . " " . Translation.get("dead_service_desc"))
                return
            }

            ; Apply service-specific URL transformations
            finalUrl := this.transformServiceUrl(this.url, this.service)

            this.updateStatus(Translation.get("loading_url"))
            this.webView.Navigate(finalUrl)

            ; Set a timeout to detect loading issues
            ; Use timeout setting from INI (convert seconds to milliseconds)
            timeoutMs := (this.settings.timeout && IsNumber(this.settings.timeout))
                ? this.settings.timeout * 1000
                : CheckerConstants.DEFAULT_TIMEOUT_MS
            SetTimer(() => this.checkLoadingTimeout(), timeoutMs)
        } else {
            this.updateStatus(Translation.get("ready") . " - " . Translation.get("no_url_provided"))
            ; Load usage information page
            this.webView.NavigateToString(this.generateUsagePage())
        }
    }

    onWebViewError(error) {
        this.updateStatus("WebView2 Error: " . error.message)
        MsgBox("Failed to initialize WebView2: " . error.message, "Error", "OK Icon!")
    }

    onNavigationCompleted(sender, args) {
        try {
            if (args.IsSuccess) {
                this.updateStatus(Translation.get("page_loaded"))
            } else {
                this.updateStatus(Translation.get("navigation_failed") . " " . args.WebErrorStatus)
            }
        } catch as e {
            this.updateStatus(Translation.get("error") . ": " . e.message)
        }
    }

    onDOMContentLoaded(sender, args) {
        try {
            this.updateStatus(Translation.get("dom_loaded"))
            ; Small delay to ensure DOM is fully ready
            SetTimer(() => this.fillCoordinateField(), CheckerConstants.DOM_READY_DELAY_MS)
        } catch as e {
            this.updateStatus(Translation.get("error") . ": " . e.message)
        }
    }

    /**
     * Fills coordinate field on the loaded webpage
     * Creates appropriate service instance and delegates coordinate filling
     */
    fillCoordinateField() {
        try {
            ; Create service instance using the registry
            serviceInstance := ServiceRegistry.createService(this.service, this)

            ; Fill coordinates using the service
            serviceInstance.fillFields()
        } catch as e {
            this.updateStatus("Error filling coordinates: " . e.message)
        }
    }

    /**
     * Checks if all required coordinate parameters are present
     * @returns {Boolean} True if all coordinate fields have values, false otherwise
     */
    hasValidCoordinates() {
        return (this.lat != "" && this.latdeg != "" && this.latmin != "" && this.latdec != "" &&
            this.lon != "" && this.londeg != "" && this.lonmin != "" && this.londec != "")
    }

    /**
     * Transforms URL based on service-specific requirements
     * Adds language parameters and fixes legacy URLs
     * @param {String} url The original URL
     * @param {String} service The service name
     * @returns {String} Transformed URL with service-specific modifications
     */
    transformServiceUrl(url, service) {
        finalUrl := url
        currentLang := Translation.getLanguage()

        switch StrLower(service) {
            case "geochecker":
                ; geochecker.com supports: English, German, French, Spanish, Swedish, Norwegian, Danish, Dutch, Quebec, Italian, Portuguese
                ; Map Checker language to geochecker language (fallback to English)
                geochecker_lang := "English"
                if (currentLang == "de")
                    geochecker_lang := "German"

                ; Check if language parameter already exists, replace or add
                if (RegExMatch(finalUrl, "i)[?&]language=\w+")) {
                    finalUrl := RegExReplace(finalUrl, "i)([?&]language=)\w+", "$1" . geochecker_lang)
                } else {
                    finalUrl .= InStr(url, "?") ? "&language=" . geochecker_lang : "?language=" . geochecker_lang
                }

            case "geocheck":
                ; geocheck.org uses changeLocale.php to set language via session cookie
                ; We need to navigate to changeLocale.php?lang=xx_XX&return=<encoded_path>
                ; Map Checker language to geocheck locale
                geocheck_locales := Map(
                    "cs", "cs_CZ",
                    "sk", "sk_SK",
                    "pl", "pl_PL",
                    "de", "de_DE",
                    "en", "en_US"
                )
                geocheck_lang := geocheck_locales.Has(currentLang) ? geocheck_locales[currentLang] : "en_US"

                ; Extract the path and query from the URL to use as return parameter
                ; URL format: https://geocheck.org/geo_inputchkcoord.php?gid=xxx
                if (RegExMatch(finalUrl, "i)https?://[^/]+(/.*)", &match)) {
                    pathAndQuery := match[1]  ; e.g., /geo_inputchkcoord.php?gid=xxx
                    ; URL-encode the path (replace special chars)
                    encodedPath := pathAndQuery
                    encodedPath := StrReplace(encodedPath, "%", "%25")  ; Must be first
                    encodedPath := StrReplace(encodedPath, "/", "%2F")
                    encodedPath := StrReplace(encodedPath, "?", "%3F")
                    encodedPath := StrReplace(encodedPath, "=", "%3D")
                    encodedPath := StrReplace(encodedPath, "&", "%26")
                    encodedPath := StrReplace(encodedPath, "-", "%2D")

                    ; Build changeLocale.php URL
                    finalUrl := "https://geocheck.org/changeLocale.php?lang=" . geocheck_lang . "&return=" . encodedPath
                }

            case "certitudes":
                ; certitudes.org supports: en_GB, en_US, cs_CZ, sk_SK, pl_PL, de_DE, fr_FR, it_IT, nl_NL, etc.
                ; Map Checker language to certitudes locale
                certitudes_locales := Map(
                    "cs", "cs_CZ",
                    "sk", "sk_SK",
                    "pl", "pl_PL",
                    "de", "de_DE",
                    "en", "en_GB"
                )
                certitudes_lang := certitudes_locales.Has(currentLang) ? certitudes_locales[currentLang] : "en_GB"

                ; Check if lang parameter already exists, replace or add
                if (RegExMatch(finalUrl, "i)[?&]lang=\w+")) {
                    finalUrl := RegExReplace(finalUrl, "i)([?&]lang=)\w+", "$1" . certitudes_lang)
                } else {
                    finalUrl .= InStr(url, "?") ? "&lang=" . certitudes_lang : "?lang=" . certitudes_lang
                }

            case "gcappsgeochecker", "gcappsmultichecker":
                ; gc-apps.com uses path prefix: /de/checker/ or /en/checker/
                ; Only German is natively supported, force English for others
                if (currentLang != "de") {
                    ; Handle multichecker URLs: /multichecker/show/HASH -> /en/checker/HASH/try
                    if (RegExMatch(finalUrl, "i)gc-apps\.com/multichecker/show/([a-f0-9]+)", &multiMatch)) {
                        hash := multiMatch[1]
                        finalUrl := RegExReplace(finalUrl, "i)(https?://[^/]*gc-apps\.com/).*", "$1en/checker/" . hash . "/try")
                    }
                    ; Handle geochecker URLs: /geochecker/show/HASH -> /en/checker/HASH/try
                    else if (RegExMatch(finalUrl, "i)gc-apps\.com/geochecker/show/([a-f0-9]+)", &geoMatch)) {
                        hash := geoMatch[1]
                        finalUrl := RegExReplace(finalUrl, "i)(https?://[^/]*gc-apps\.com/).*", "$1en/checker/" . hash . "/try")
                    }
                    ; Check if URL already has language prefix like /de/ and replace with /en/
                    else if (RegExMatch(finalUrl, "gc-apps\.com/[a-z]{2}/")) {
                        finalUrl := RegExReplace(finalUrl, "(gc-apps\.com/)[a-z]{2}/", "$1en/")
                    } else if (RegExMatch(finalUrl, "gc-apps\.com/(?!en/)")) {
                        ; No language prefix, add /en/ after domain
                        finalUrl := RegExReplace(finalUrl, "(gc-apps\.com/)", "$1en/")
                    }
                }

            case "gcm":
                ; Fix Gcm URL: change gc.gcm.cz/validator/ to validator.gcm.cz/
                finalUrl := StrReplace(finalUrl, "gc.gcm.cz/validator/", "validator.gcm.cz/")

            case "hermansky":
                ; Fix Hermansky URL: change speedygt.ic.cz/gps to geo.hermansky.net
                finalUrl := StrReplace(finalUrl, "speedygt.ic.cz/gps", "geo.hermansky.net")

            case "geocachefi":
                ; Add language parameter for geocache.fi (z=1 forces English interface)
                finalUrl .= InStr(finalUrl, "?") ? "&z=1" : "?z=1"

            case "puzzlechecker":
                ; puzzle-checker.com supports: en, cs, sk, sv (Swedish)
                ; Uses simple lang= parameter with short codes
                puzzlechecker_lang := "en"  ; Default to English
                if (currentLang == "cs" || currentLang == "sk")
                    puzzlechecker_lang := currentLang

                ; Check if lang parameter already exists, replace or add
                if (RegExMatch(finalUrl, "i)[?&]lang=\w+")) {
                    finalUrl := RegExReplace(finalUrl, "i)([?&]lang=)\w+", "$1" . puzzlechecker_lang)
                } else {
                    finalUrl .= InStr(finalUrl, "?") ? "&lang=" . puzzlechecker_lang : "?lang=" . puzzlechecker_lang
                }
        }
        return finalUrl
    }

    executeJavaScript(jsCode) {
        this.webView.ExecuteScriptAsync(jsCode)
        .then((result) => this.onCoordinatesFilled(result))
        .catch((error) => this.onCoordinatesError(error))
    }

    /**
     * Callback when coordinates are filled successfully
     * Starts result checking if enabled in settings
     * @param {String} result JavaScript execution result
     */
    onCoordinatesFilled(result) {
        try {
            resultStr := String(result)
            if (InStr(resultStr, "SUCCESS")) {
                this.coordinatesFilled := true ; Mark coordinates as filled

                ; Special message for geocheck about captcha
                if (StrLower(this.service) == "geocheck") {
                    this.updateStatusLeft(Translation.get("geocheck_captcha"))
                } else {
                    this.updateStatusLeft(Translation.get("coordinates_filled"))
                }

                ; Start checking for results after coordinates are filled (if enabled)
                if (this.settings.answer) {
                    this.startResultChecking()
                } else {
                    this.updateStatusRight(Translation.get("result_checking_disabled"))
                }
            } else {
                this.updateStatus(Translation.get("error") . ": " . resultStr)
            }
        } catch as e {
            this.updateStatus("Result processing error: " . e.message)
        }
    }

    onCoordinatesError(error) {
        this.updateStatus("JavaScript error: " . error.message)
    }

    checkLoadingTimeout() {
        if (this.statusTextLeft && this.statusTextLeft.Text == Translation.get("loading_url")) {
            this.updateStatus(Translation.get("loading_timeout"))
        }
    }

    setupHotkeys() {
        ; F5 to refresh page and refill coordinates
        HotKey("F5", (*) => this.refreshAndFill(), "On")
        HotKey("Esc", (*) => this.exitApp(), "On")
    }

    refreshAndFill() {
        try {
            if (this.webView && this.url != "") {
                this.updateStatus(Translation.get("refreshing"))

                ; Reset coordinate filling flag to allow refilling after refresh
                this.coordinatesFilled := false

                ; Apply service-specific URL transformations
                finalUrl := this.transformServiceUrl(this.url, this.service)

                this.webView.Navigate(finalUrl)
            } else {
                this.updateStatus(Translation.get("no_url_refresh"))
            }
        } catch as e {
            this.updateStatus(Translation.get("error") . ": " . e.message)
        }
    }

    /**
     * Initiates periodic result checking timer
     * Checks coordinate verification results every 200ms
     */
    startResultChecking() {
        if (!this.isCheckingResults) {
            this.isCheckingResults := true
            this.checkTimer := SetTimer(() => this.checkForResults(), CheckerConstants.RESULT_CHECK_INTERVAL_MS)
        }
    }

    checkForResults() {
        ; Toggle status between "Checking..." and "Checking..." with dots for blinking effect
        static dots := ""
        dots := (dots == "...") ? "" : dots . "."
        this.updateStatusRight(Translation.get("checking") . dots)

        ; Build service-specific result checking JavaScript
        jsCode := this.buildResultCheckingJS()

        this.webView.ExecuteScriptAsync(jsCode)
        .then((result) => this.onResultChecked(result))
        .catch((error) => this.onResultCheckError(error))
    }

    buildResultCheckingJS() {
        try {
            ; Create service instance using the registry
            serviceInstance := ServiceRegistry.createService(this.service, this)

            ; Get result checking JavaScript from the service
            return serviceInstance.buildResultCheckingJS()
        } catch as e {
            ; Fallback to default checking if service creation fails
            return "try { " .
            "var success = document.querySelector('div.success, .success, span#congrats'); " .
            "var wrong = document.querySelector('div.wrong, .wrong, span#nope'); " .
            "if (success && (success.textContent.includes('Success') || success.textContent.includes('Correct') || success.textContent.includes('congrats'))) { " .
            "'RESULT:SUCCESS'; " .
            "} else if (wrong && (wrong.textContent.includes('Incorrect') || wrong.textContent.includes('Wrong') || wrong.textContent.includes('nope'))) { " .
            "'RESULT:WRONG'; " .
            "} else { " .
            "'RESULT:NONE'; " .
            "} " .
            "} catch (e) { " .
            "'ERROR: ' + e.message; " .
            "}"
        }
    }

    onResultChecked(result) {
        try {
            resultStr := String(result)
            if (InStr(resultStr, "RESULT:SUCCESS")) {
                this.stopResultChecking()
                this.updateStatusRightWithColor(Translation.get("correct"), "0x008000") ; Dark green
                this.finalExitCode := CheckerConstants.EXIT_CORRECT

                ; Copy owner's message to clipboard if enabled and service supports it
                if (this.settings.copymsg) {
                    this.updateStatus(Translation.get("attempting_clipboard"))
                    this.copyOwnerMessage()
                }
            } else if (InStr(resultStr, "RESULT:WRONG")) {
                this.stopResultChecking()
                this.updateStatusRightWithColor(Translation.get("wrong"), "0xFF0000") ; Red
                this.finalExitCode := CheckerConstants.EXIT_WRONG
            }
            ; If RESULT:NONE, continue checking
        } catch as e {
            this.updateStatus("Result check error: " . e.message)
        }
    }

    copyOwnerMessage() {
        try {
            ; Create service instance using the registry
            serviceInstance := ServiceRegistry.createService(this.service, this)

            ; Try to copy owner's message if the service supports it
            if (!serviceInstance.copyOwnerMessage()) {
                this.updateStatus(Translation.get("clipboard_not_supported") . " " . this.service . " " . Translation.get("clipboard_service"))
            }
        } catch as e {
            this.updateStatus(Translation.get("clipboard_copy_error") . " " . e.message)
        }
    }

    onClipboardResult(result) {
        try {
            ; Prevent multiple clipboard operations
            if (this.clipboardCopied) {
                return
            }

            resultStr := String(result)
            this.updateStatus(Translation.get("clipboard_js_result") . " " . resultStr)

            ; Remove surrounding quotes if present
            cleanResultStr := resultStr
            if (SubStr(cleanResultStr, 1, 1) == '"' && SubStr(cleanResultStr, -1) == '"') {
                cleanResultStr := SubStr(cleanResultStr, 2, StrLen(cleanResultStr) - 2)
            }

            if (InStr(cleanResultStr, "CLIPBOARD:") == 1) {
                clipboardText := SubStr(cleanResultStr, 11) ; Remove "CLIPBOARD:" prefix
                this.updateStatus("Extracted text for clipboard: [" . clipboardText . "]")

                if (clipboardText != "" && clipboardText != "NO_ELEMENT" && clipboardText != "NO_TEXT") {
                    try {
                        ; Clear clipboard first
                        A_Clipboard := ""
                        Sleep(50)

                        ; Set clipboard content
                        A_Clipboard := clipboardText
                        Sleep(50)

                        ; Verify clipboard content
                        verifyText := A_Clipboard
                        if (verifyText == clipboardText) {
                            this.updateStatus(Translation.get("clipboard_success") . " " . SubStr(clipboardText, 1, 40) .
                            "...")
                            this.clipboardCopied := true ; Mark as copied to prevent multiple operations

                            ; Show message if debug mode is enabled
                            if (!this.settings.debug) {
                                MsgBox(clipboardText, Translation.get("clipboard_copied_title"), "OK")
                            }
                        } else {
                            this.updateStatus(Translation.get("clipboard_failed") . " " . SubStr(clipboardText, 1,
                                20) . "... " . Translation.get("clipboard_got") . " " . SubStr(verifyText, 1, 20) . "...")
                        }
                    } catch as e {
                        this.updateStatus("Clipboard assignment error: " . e.message)
                    }
                } else {
                    this.updateStatus(Translation.get("clipboard_invalid_text") . " [" . clipboardText . "]")
                    ; Debug information about why clipboard failed
                    if (this.settings.debug) {
                        MsgBox("Clipboard debug: " . clipboardText, "Clipboard Debug", "OK")
                    }
                }
            } else {
                this.updateStatus("Unexpected clipboard result format: " . cleanResultStr)
            }
        } catch as e {
            this.updateStatus("Clipboard result error: " . e.message)
        }
    }

    onClipboardError(error) {
        this.updateStatus(Translation.get("clipboard_js_error") . " " . error.message)
    }

    onResultCheckError(error) {
        this.updateStatus("Result check JavaScript error: " . error.message)
    }

    stopResultChecking() {
        if (this.checkTimer) {
            this.checkTimer.Delete()
            this.checkTimer := ""
        }
        this.isCheckingResults := false
    }

    exitApp(exitCode := "") {
        try {
            ; Save current window size before exiting
            this.saveSettings()

            ; Stop any running timers
            this.stopResultChecking()

            ; Clean up WebView2 resources
            if (this.webViewController) {
                this.webViewController.Close()
                this.webViewController := ""
            }
            this.webView := ""
        } catch {
            ; Ignore cleanup errors
        }

        ; Use the final exit code if no specific code provided
        finalCode := (exitCode == "") ? this.finalExitCode : exitCode
        ExitApp(finalCode)
    }

    /**
     * Updates status text (compatibility method for existing code)
     * @param {String} text Status message to display
     */
    updateStatus(text) {
        ; Update left status (for compatibility with existing code)
        this.updateStatusLeft(text)
    }

    /**
     * Updates left status text for loading/page messages
     * @param {String} text Status message to display
     */
    updateStatusLeft(text) {
        if (this.statusTextLeft)
            this.statusTextLeft.Text := text
    }

    /**
     * Updates right status text for result checking status
     * @param {String} text Status message to display
     */
    updateStatusRight(text) {
        if (this.statusTextRight)
            this.statusTextRight.Text := text
    }

    /**
     * Updates right status text with specific color and bold formatting
     * @param {String} text Status message to display
     * @param {String} color Color code (e.g. "0x008000" for green)
     */
    updateStatusRightWithColor(text, color) {
        if (this.statusTextRight) {
            this.statusTextRight.Text := text
            ; Change text color and make bold
            try {
                this.statusTextRight.Opt("+c" . color)
                this.statusTextRight.SetFont("Bold")
            } catch {
                ; Ignore color/font change errors
            }
        }
    }

    getVersionFromScript() {
        try {
            ; Read the script file to extract version from header comment
            scriptContent := FileRead(A_ScriptFullPath)

            ; Look for JSDoc @version format first
            if (RegExMatch(scriptContent, "im)@version\s+([\d\.]+)", &match)) {
                return match[1]
            }

            ; Fallback: Look for the old comment format
            if (RegExMatch(scriptContent, "im)^;\s*Version:\s*([\d\.]+)", &match)) {
                return match[1]
            }

            ; Fallback if version not found in expected format
            return "4.0.1"
        } catch {
            ; Fallback version if file reading fails
            return "4.0.1"
        }
    }

    /**
     * Generates HTML page for dead/discontinued services
     * Shows warning message instead of loading potentially bad URL with ads
     * @param {Object} serviceInstance The dead service instance with siteName and deadSince
     * @returns {String} HTML content for the dead service page
     */
    generateDeadServicePage(serviceInstance) {
        deadInfo := serviceInstance.deadSince ? " (" . Translation.get("dead_since") . " " . serviceInstance.deadSince . ")" : ""

        html := "<html><head><title>Checker - " . Translation.get("dead_service_warning") . "</title>"
        html .= "<meta charset='UTF-8'>"
        html .= "<style>body{font-family:Arial,sans-serif;margin:40px;background:#f5f5f5;text-align:center;}"
        html .= "h1{color:#cc0000;margin-bottom:30px;}"
        html .= ".container{max-width:600px;margin:0 auto;background:#fff;padding:40px;border-radius:10px;box-shadow:0 4px 15px rgba(0,0,0,0.1);}"
        html .= ".icon{font-size:80px;margin-bottom:20px;}"
        html .= ".site-name{font-size:24px;color:#333;font-weight:bold;margin:20px 0;}"
        html .= ".dead-info{color:#666;font-size:14px;margin-bottom:20px;}"
        html .= ".message{background:#fff3cd;padding:20px;border-radius:5px;border-left:4px solid #ffc107;text-align:left;margin:20px 0;}"
        html .= ".url{background:#f8f9fa;padding:15px;border-radius:5px;font-family:monospace;font-size:12px;word-break:break-all;text-align:left;margin-top:20px;}"
        html .= ".url-label{font-weight:bold;color:#666;margin-bottom:5px;}</style></head><body>"

        html .= "<div class='container'>"
        html .= "<div class='icon'>⚠️</div>"
        html .= "<h1>" . Translation.get("dead_service_warning") . "</h1>"
        html .= "<div class='site-name'>" . serviceInstance.siteName . "</div>"
        if (serviceInstance.deadSince != "")
            html .= "<div class='dead-info'>" . Translation.get("dead_since") . " " . serviceInstance.deadSince . ")</div>"
        html .= "<div class='message'>" . Translation.get("dead_service_desc") . "</div>"
        html .= "<div class='url'><div class='url-label'>URL:</div>" . this.url . "</div>"
        html .= "</div>"

        html .= "</body></html>"
        return html
    }

    generateUsagePage() {
        ; Generate HTML page with usage information and received parameters
        html := "<html><head><title>Checker - Usage Information</title>"
        html .= "<style>body{font-family:Arial,sans-serif;margin:20px;background:#f5f5f5;}"
        html .= "h1{color:#2d7d32;border-bottom:2px solid #2d7d32;padding-bottom:10px;}"
        html .= "h2{color:#4a4a4a;margin-top:25px;}"
        html .= ".description{background:#fff;padding:15px;border-radius:5px;box-shadow:0 2px 5px rgba(0,0,0,0.1);}"
        html .= ".usage{background:#e8f5e8;padding:15px;border-radius:5px;border-left:4px solid #2d7d32;margin:15px 0;}"
        html .= ".example{background:#f0f0f0;padding:10px;border-radius:3px;font-family:monospace;margin:10px 0;font-size:12px;}"
        html .= ".received{background:#ffe6e6;padding:15px;border-radius:5px;border-left:4px solid #cc0000;}"
        html .= ".error{color:#cc0000;font-weight:bold;}</style></head><body>"

        html .= "<h1>Checker</h1>"
        html .= "<div class='description'>A coordinate verification tool for geocaching services, built with AutoHotkey v2 and WebView2.</div>"

        if (!this.hasValidParameters) {
            ; Show specific error message if we have one
            if (this.parameterError != "") {
                html .= "<h2><span class='error'>Error: " . this.parameterError . "</span></h2>"
            } else {
                html .= "<h2><span class='error'>Error: Invalid Parameters</span></h2>"
            }

            html .= "<div class='usage'>"
            html .= "<p><strong>Checker needs to be called with 10 parameters:</strong></p>"
            html .= "<div class='example'>Checker.ahk service lat latdeg latmin latdec lon londeg lonmin londec url</div>"
            html .= "<p><strong>Examples:</strong></p>"
            html .= "<div class='example'>Checker.ahk gcm N 50 21 222 E 013 33 666 `"https://validator.gcm.cz/index.php?uuid=cad21d5c-9f00-4815-bd4c-431e3771fae4`"</div>"
            html .= "<div class='example'>Checker.ahk geocheck S 49 44 401 W 165 55 157 `"http://geocheck.org/geo_inputchkcoord.php?gid=6180167e5770830-5041-4959-aac1-c154a3d8a122`"</div>"
            html .= "</div>"

            html .= "<h2>Parameters Received (" . A_Args.Length . " total):</h2>"
            html .= "<div class='received'>"
            if (A_Args.Length == 0) {
                html .= "<p><em>No parameters provided</em></p>"
            } else {
                Loop A_Args.Length {
                    switch A_Index {
                        case 1: paramName := "service"
                        case 2: paramName := "lat"
                        case 3: paramName := "latdeg"
                        case 4: paramName := "latmin"
                        case 5: paramName := "latdec"
                        case 6: paramName := "lon"
                        case 7: paramName := "londeg"
                        case 8: paramName := "lonmin"
                        case 9: paramName := "londec"
                        case 10: paramName := "url"
                        default: paramName := "extra"
                    }

                    html .= "<p><strong>Parameter " . A_Index . " (" . paramName . "):</strong> " . A_Args[A_Index] . "</p>"
                }
            }
            html .= "</div>"
        } else {
            html .= "<h2>Parameters loaded successfully</h2>"
            html .= "<div class='usage'>"
            html .= "<p><strong>Service:</strong> " . this.service . "</p>"
            if (this.hasValidCoordinates()) {
                html .= "<p><strong>Coordinates:</strong> " . this.lat . " " . this.latdeg . "° " . this.latmin . "." . this.latdec . "' / "
                html .= this.lon . " " . Format("{:03d}", Integer(this.londeg)) . "° " . this.lonmin . "." . this.londec . "'</p>"
            }
            if (this.url != "") {
                html .= "<p><strong>URL:</strong> " . this.url . "</p>"
            } else {
                html .= "<p><strong>URL:</strong> <em>Not provided</em></p>"
            }
            html .= "</div>"
        }

        html .= "</body></html>"
        return html
    }

    onWindowResize() {
        try {
            ; Get current GUI client size for saving to INI
            this.gui.GetClientPos(, , &clientWidth, &clientHeight)

            ; Save client size to settings (ensure integers) - this prevents growth from window decorations
            this.settings.windowWidth := Integer(clientWidth)
            this.settings.windowHeight := Integer(clientHeight)

            ; Resize WebView container (leave space at bottom for status bar)
            if (this.webViewContainer) {
                this.webViewContainer.Move(0, 0, clientWidth, clientHeight - CheckerConstants.STATUS_BAR_HEIGHT)
            }

            ; Resize status bar to full width at bottom
            if (this.statusBar) {
                this.statusBar.Move(0, clientHeight - CheckerConstants.STATUS_BAR_HEIGHT, clientWidth, CheckerConstants.STATUS_BAR_HEIGHT)
            }

            ; Resize status text controls
            statusTextY := clientHeight - CheckerConstants.STATUS_BAR_HEIGHT + 2
            if (this.statusTextLeft) {
                this.statusTextLeft.Move(10, statusTextY, clientWidth - 110, 16)
            }

            if (this.statusTextRight) {
                this.statusTextRight.Move(clientWidth - 100, statusTextY, 90, 16)
            }

            ; Resize WebView2 if it exists
            if (this.webViewController) {
                try {
                    ; Use the client size we already calculated
                    w := clientWidth
                    h := clientHeight - CheckerConstants.STATUS_BAR_HEIGHT

                    ; Create a RECT structure for WebView2 bounds
                    rect := Buffer(16, 0)
                    NumPut("Int", 0, rect, 0)    ; left = 0 (relative to container)
                    NumPut("Int", 0, rect, 4)    ; top = 0 (relative to container)
                    NumPut("Int", w, rect, 8)    ; right = width
                    NumPut("Int", h, rect, 12)   ; bottom = height

                    ; Try different methods to update WebView2 bounds
                    try {
                        ; Method 1: Direct bounds setting
                        this.webViewController.Bounds := rect
                    } catch {
                        try {
                            ; Method 2: Using put_Bounds if available
                            if (this.webViewController.HasMethod("put_Bounds")) {
                                this.webViewController.put_Bounds(rect)
                            }
                        } catch {
                            try {
                                ; Method 3: Notify parent window position changed
                                this.webViewController.NotifyParentWindowPositionChanged()
                            } catch {
                                ; All methods failed, ignore
                            }
                        }
                    }
                } catch {
                    ; Ignore all WebView2 resize errors
                }
            }
        } catch as e {
            ; Ignore resize errors to prevent crashes
        }
    }
}

/**
 * Application entry point
 * Creates and starts the Checker application instance
 */
CheckerApp.main()