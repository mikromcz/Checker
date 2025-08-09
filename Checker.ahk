/**
 * @description Checker - Coordinate verification tool for geocaching services
 * Automates coordinate submission and verification across multiple geocaching
 * coordinate checker websites using WebView2 technology.
 * @author mikrom, ClaudeAI
 * @version 4.0.1
 * @url https://www.geoget.cz/doku.php/user:skript:checker
 * @forum http://www.geocaching.cz/forum/viewthread.php?forum_id=20&thread_id=25822
 * @icon https://icons8.com/icon/18401/Thumb-Up
 */

#Requires AutoHotkey v2.0
#NoTrayIcon
#Include lib\WebView2\WebView2.ahk
#Include lib\Promise.ahk
#Include lib\ComVar.ahk
#Include lib\Checker\ServiceRegistry.ahk

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
        this.webView := ""
        this.webViewController := ""
        this.isCheckingResults := false
        this.checkTimer := ""
        this.finalExitCode := 0
        this.coordinatesFilled := false
        this.clipboardCopied := false
        this.version := this.getVersionFromScript()

        ; Settings with defaults
        this.settings := {
            answer: 1,      ; Check result and send exit code
            debug: 0,       ; Debug mode
            beep: 0,        ; Acoustic feedback
            copymsg: 1,     ; Copy owner's message to clipboard
            timeout: 10,    ; Page load timeout in seconds
            windowWidth: 1000,  ; Window width
            windowHeight: 600   ; Window height
        }
        this.iniFile := "Checker.ini"
    }

    setupIcons() {
        ; Set application icon if available (AHK v2 equivalent of Menu, Tray, Icon)
        if (FileExist(A_ScriptDir "\Checker.ico")) {
            TraySetIcon(A_ScriptDir "\Checker.ico", , true)  ; true = freeze
        }
    }

    /**
     * Parses command line arguments and validates parameters
     * Expected format: service lat latdeg latmin latdec lon londeg lonmin londec url
     */
    parseCommandLine() {
        this.hasValidParameters := false
        this.parameterError := ""

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

            ; Validate parameter types and values
            if (!this.validateParameters()) {
                this.hasValidParameters := false
                this.finalExitCode := 4  ; Set exit code for invalid parameters
                return
            }

            this.hasValidParameters := true
        } else {
            this.parameterError := "Insufficient parameters provided (" . A_Args.Length . " received, 10 required)"
            this.finalExitCode := 4  ; Set exit code for invalid parameters
        }
    }

    /**
     * Validates coordinate parameters for correct format and ranges
     * @returns {Boolean} True if all parameters are valid, false otherwise
     */
    validateParameters() {
        ; Validate coordinate directions
        if (this.lat != "N" && this.lat != "S") {
            this.parameterError := "Invalid latitude direction '" . this.lat . "' (must be N or S)"
            return false
        }

        if (this.lon != "E" && this.lon != "W") {
            this.parameterError := "Invalid longitude direction '" . this.lon . "' (must be E or W)"
            return false
        }

        ; Validate that coordinate numbers are numeric
        if (!IsNumber(this.latdeg) || !IsNumber(this.latmin) || !IsNumber(this.latdec)) {
            this.parameterError := "Invalid latitude coordinates (latdeg='" . this.latdeg . "', latmin='" . this.latmin . "', latdec='" . this.latdec . "') - must be numbers"
            return false
        }

        if (!IsNumber(this.londeg) || !IsNumber(this.lonmin) || !IsNumber(this.londec)) {
            this.parameterError := "Invalid longitude coordinates (londeg='" . this.londeg . "', lonmin='" . this.lonmin . "', londec='" . this.londec . "') - must be numbers"
            return false
        }

        ; Validate coordinate ranges
        latDeg := Integer(this.latdeg)
        lonDeg := Integer(this.londeg)
        latMin := Integer(this.latmin)
        lonMin := Integer(this.lonmin)

        if (latDeg < 0 || latDeg > 90) {
            this.parameterError := "Invalid latitude degrees '" . this.latdeg . "' (must be 0-90)"
            return false
        }

        if (lonDeg < 0 || lonDeg > 180) {
            this.parameterError := "Invalid longitude degrees '" . this.londeg . "' (must be 0-180)"
            return false
        }

        if (latMin < 0 || latMin >= 60) {
            this.parameterError := "Invalid latitude minutes '" . this.latmin . "' (must be 0-59)"
            return false
        }

        if (lonMin < 0 || lonMin >= 60) {
            this.parameterError := "Invalid longitude minutes '" . this.lonmin . "' (must be 0-59)"
            return false
        }

        return true
    }

    createGUI() {
        ; Calculate centered position based on saved client size
        ; Add approximate window decoration size for positioning
        approxWindowWidth := this.settings.windowWidth + 16   ; Add border width
        approxWindowHeight := this.settings.windowHeight + 59  ; Add title bar + border height
        centerX := (A_ScreenWidth - approxWindowWidth) // 2
        centerY := (A_ScreenHeight - approxWindowHeight) // 2

        ; Create main GUI window
        this.gui := Gui("+Resize +MinSize1000x600", Translation.get("app_title"))
        this.gui.OnEvent("Close", (*) => this.exitApp())
        this.gui.OnEvent("Size", (*) => this.onWindowResize())

        this.gui.MarginX := 0
        this.gui.MarginY := 0

        ; Create menu bar
        this.createMenuBar()

        ; Create WebView2 container area (starts from y0 since menu bar is native)
        containerHeight := this.settings.windowHeight - 20  ; Leave 20px for status bar
        this.webViewContainer := this.gui.AddText("x0 y0 w" . this.settings.windowWidth . " h" . containerHeight . " +Border")

        ; Create status bar at bottom
        this.createStatusBar()

        ; Set initial GUI client size (not window size) - this prevents size drift
        this.gui.Move(centerX, centerY)
        ; Use SetClientSize to set the exact client dimensions we want
        DllCall("SetWindowPos", "Ptr", this.gui.Hwnd, "Ptr", 0, "Int", centerX, "Int", centerY,
                "Int", this.settings.windowWidth + 16, "Int", this.settings.windowHeight + 59, "UInt", 0x0004)

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
        ; Create status bar area (thinner - reduced height from 30 to 20)
        statusY := this.settings.windowHeight - 20
        statusTextY := statusY + 2
        this.statusBar := this.gui.AddText("x0 y" . statusY . " w" . this.settings.windowWidth . " h20 +0x1000")  ; SS_SUNKEN
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
     * Creates default settings file if it doesn't exist
     */
    loadSettings() {
        ; Load settings from INI file
        try {
            if (FileExist(this.iniFile)) {
                this.settings.answer := IniRead(this.iniFile, "Checker", "answer", 1)
                this.settings.copymsg := IniRead(this.iniFile, "Checker", "copymsg", 1)
                this.settings.timeout := IniRead(this.iniFile, "Checker", "timeout", "")
                this.settings.debug := IniRead(this.iniFile, "Checker", "debug", 0)
                this.settings.beep := IniRead(this.iniFile, "Checker", "beep", 0)
                this.settings.windowWidth := Integer(IniRead(this.iniFile, "Checker", "windowWidth", 1000))
                this.settings.windowHeight := Integer(IniRead(this.iniFile, "Checker", "windowHeight", 600))

                ; Debug: Show loaded values
                ; MsgBox("Loaded from INI: " . this.settings.windowWidth . "x" . this.settings.windowHeight)

                ; Validate window size (minimum 1000x600, maximum screen size)
                if (this.settings.windowWidth < 1000)
                    this.settings.windowWidth := 1000
                if (this.settings.windowHeight < 600)
                    this.settings.windowHeight := 600
                if (this.settings.windowWidth > A_ScreenWidth)
                    this.settings.windowWidth := A_ScreenWidth
                if (this.settings.windowHeight > A_ScreenHeight)
                    this.settings.windowHeight := A_ScreenHeight
            }
        } catch as e {
            ; Use defaults if loading fails
        }
    }

    saveSettings() {
        ; Save settings to INI file
        try {
            IniWrite(this.settings.answer, this.iniFile, "Checker", "answer")
            IniWrite(this.settings.copymsg, this.iniFile, "Checker", "copymsg")
            IniWrite(this.settings.timeout, this.iniFile, "Checker", "timeout")
            IniWrite(this.settings.debug, this.iniFile, "Checker", "debug")
            IniWrite(this.settings.beep, this.iniFile, "Checker", "beep")
            IniWrite(this.settings.windowWidth, this.iniFile, "Checker", "windowWidth")
            IniWrite(this.settings.windowHeight, this.iniFile, "Checker", "windowHeight")
        } catch as e {
            MsgBox("Failed to save settings: " . e.message, "Error", "OK Icon!")
        }
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

        ; Timeout field (inline)
        prefGui.AddText("x15 y78", Translation.get("timeout"))
        timeoutEdit := prefGui.AddEdit("x160 y75 w30", this.settings.timeout)
        prefGui.AddText("x195 y78", Translation.get("timeout_desc"))

        ; Debug checkbox
        debugCb := prefGui.AddCheckbox("x15 y105 w300 Checked" . this.settings.debug,
            Translation.get("debug_mode_desc"))

        ; Play sound checkbox (disabled - not implemented)
        beepCb := prefGui.AddCheckbox("x15 y135 w300 Checked" . this.settings.beep . " +Disabled",
            Translation.get("audio_feedback_desc"))


        ; Buttons
        okBtn := prefGui.AddButton("x85 y170 w75 h25", Translation.get("ok"))
        cancelBtn := prefGui.AddButton("x170 y170 w75 h25", Translation.get("cancel"))

        ; Button events
        okBtn.OnEvent("Click", (*) => this.savePreferences(answerCb, debugCb, beepCb, copymsgCb, timeoutEdit, prefGui))
        cancelBtn.OnEvent("Click", (*) => prefGui.Destroy())
        prefGui.OnEvent("Escape", (*) => prefGui.Destroy())

        ; Show dialog
        prefGui.Show("w330 h210")
    }

    savePreferences(answerCb, debugCb, beepCb, copymsgCb, timeoutEdit, prefGui) {
        ; Save settings from dialog controls
        this.settings.answer := answerCb.Value
        this.settings.debug := debugCb.Value
        this.settings.beep := beepCb.Value
        this.settings.copymsg := copymsgCb.Value
        this.settings.timeout := timeoutEdit.Text

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
            ; Wrap long URLs for better display
            if (StrLen(this.url) > 50) {
                aboutText .= SubStr(this.url, 1, 47) . "...`n"
                aboutText .= "(" . StrLen(this.url) . " " . Translation.get("characters_total") . ")"
            } else {
                aboutText .= this.url
            }
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
            ; Add language parameters for different services
            finalUrl := this.url
            if (StrLower(this.service) == "geochecker") {
                if (InStr(this.url, "?")) {
                    finalUrl .= "&language=English"
                } else {
                    finalUrl .= "?language=English"
                }
            } else if (StrLower(this.service) == "geocheck") {
                if (InStr(this.url, "?")) {
                    finalUrl .= "&lang=en_US"
                } else {
                    finalUrl .= "?lang=en_US"
                }
            } else if (StrLower(this.service) == "gcm") {
                ; Fix Gcm URL: change gc.gcm.cz/validator/ to validator.gcm.cz/
                finalUrl := StrReplace(finalUrl, "gc.gcm.cz/validator/", "validator.gcm.cz/")
            } else if (StrLower(this.service) == "hermansky") {
                ; Fix Hermansky URL: change speedygt.ic.cz/gps to geo.hermansky.net
                finalUrl := StrReplace(finalUrl, "speedygt.ic.cz/gps", "geo.hermansky.net")
            } else if (StrLower(this.service) == "geocachefi") {
                ; Add English language parameter for geocache.fi
                if (InStr(finalUrl, "?")) {
                    finalUrl .= "&z=1"
                } else {
                    finalUrl .= "?z=1"
                }
            }

            this.updateStatus(Translation.get("loading_url"))
            this.webView.Navigate(finalUrl)

            ; Set a timeout to detect loading issues
            ; Use timeout setting from INI (convert seconds to milliseconds)
            timeoutMs := (this.settings.timeout && IsNumber(this.settings.timeout)) ? this.settings.timeout * 1000 :
                10000
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
                this.updateStatus("Page loaded successfully")
            } else {
                this.updateStatus("Navigation failed - WebNavigationKind: " . args.WebErrorStatus)
            }
        } catch as e {
            this.updateStatus("Navigation event error: " . e.message)
        }
    }

    onDOMContentLoaded(sender, args) {
        try {
            this.updateStatus("DOM loaded - Filling coordinates...")
            ; Small delay to ensure DOM is fully ready
            SetTimer(() => this.fillCoordinateField(), 500)
        } catch as e {
            this.updateStatus("DOM event error: " . e.message)
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
                    this.updateStatusLeft("Coordinates filled successfully - Please solve captcha and submit form")
                } else {
                    this.updateStatusLeft("Coordinates filled successfully - Submit form and wait...")
                }

                ; Start checking for results after coordinates are filled (if enabled)
                if (this.settings.answer) {
                    this.startResultChecking()
                } else {
                    this.updateStatusRight("Result checking disabled")
                }
            } else {
                this.updateStatus("Failed to fill coordinates: " . resultStr)
            }
        } catch as e {
            this.updateStatus("Result processing error: " . e.message)
        }
    }

    onCoordinatesError(error) {
        this.updateStatus("JavaScript error: " . error.message)
    }

    checkLoadingTimeout() {
        if (this.statusTextLeft && this.statusTextLeft.Text == "Loading URL...") {
            this.updateStatus("Loading timeout - Check URL or network connection")
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
                this.updateStatus("Refreshing page...")

                ; Reset coordinate filling flag to allow refilling after refresh
                this.coordinatesFilled := false

                ; Apply service-specific URL transformations (same as in onWebViewCreated)
                finalUrl := this.url
                if (StrLower(this.service) == "geochecker") {
                    if (InStr(this.url, "?")) {
                        finalUrl .= "&language=English"
                    } else {
                        finalUrl .= "?language=English"
                    }
                } else if (StrLower(this.service) == "geocheck") {
                    if (InStr(this.url, "?")) {
                        finalUrl .= "&lang=en_US"
                    } else {
                        finalUrl .= "?lang=en_US"
                    }
                } else if (StrLower(this.service) == "gcm") {
                    ; Fix Gcm URL: change gc.gcm.cz/validator/ to validator.gcm.cz/
                    finalUrl := StrReplace(finalUrl, "gc.gcm.cz/validator/", "validator.gcm.cz/")
                } else if (StrLower(this.service) == "hermansky") {
                    ; Fix Hermansky URL: change speedygt.ic.cz/gps to geo.hermansky.net
                    finalUrl := StrReplace(finalUrl, "speedygt.ic.cz/gps", "geo.hermansky.net")
                } else if (StrLower(this.service) == "geocachefi") {
                    ; Add English language parameter for geocache.fi
                    if (InStr(finalUrl, "?")) {
                        finalUrl .= "&z=1"
                    } else {
                        finalUrl .= "?z=1"
                    }
                }

                this.webView.Navigate(finalUrl)
            } else {
                this.updateStatus("No URL to refresh")
            }
        } catch as e {
            this.updateStatus("Refresh error: " . e.message)
        }
    }

    /**
     * Initiates periodic result checking timer
     * Checks coordinate verification results every 200ms
     */
    startResultChecking() {
        if (!this.isCheckingResults) {
            this.isCheckingResults := true
            this.checkTimer := SetTimer(() => this.checkForResults(), 200)
        }
    }

    checkForResults() {
        ; Toggle status between "Checking..." and "Checking..." with dots for blinking effect
        static dots := ""
        dots := (dots == "...") ? "" : dots . "."
        this.updateStatusRight("Checking" . dots)

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
                this.finalExitCode := 1 ; Set exit code for success

                ; Copy owner's message to clipboard if enabled and service supports it
                if (this.settings.copymsg) {
                    this.updateStatus(Translation.get("attempting_clipboard"))
                    this.copyOwnerMessage()
                }
            } else if (InStr(resultStr, "RESULT:WRONG")) {
                this.stopResultChecking()
                this.updateStatusRightWithColor(Translation.get("wrong"), "0xFF0000") ; Red
                this.finalExitCode := 2 ; Set exit code for incorrect
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
            this.updateStatus("Clipboard JavaScript result: " . resultStr)

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
                    this.updateStatus("Clipboard copy failed - invalid text: [" . clipboardText . "]")
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
        this.updateStatus("Clipboard JavaScript error: " . error.message)
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

            ; Resize WebView container (leave 20px at bottom for status bar)
            if (this.webViewContainer) {
                this.webViewContainer.Move(0, 0, clientWidth, clientHeight - 20)
            }

            ; Resize status bar to full width at bottom
            if (this.statusBar) {
                this.statusBar.Move(0, clientHeight - 20, clientWidth, 20)
            }

            ; Resize status text controls
            if (this.statusTextLeft) {
                this.statusTextLeft.Move(10, clientHeight - 18, clientWidth - 110, 16)
            }

            if (this.statusTextRight) {
                this.statusTextRight.Move(clientWidth - 100, clientHeight - 18, 90, 16)
            }

            ; Resize WebView2 if it exists
            if (this.webViewController) {
                try {
                    ; Use the client size we already calculated
                    w := clientWidth
                    h := clientHeight - 20

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