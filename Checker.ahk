; Checker
; Www: https://www.geoget.cz/doku.php/user:skript:checker
; Forum: http://www.geocaching.cz/forum/viewthread.php?forum_id=20&thread_id=25822
; Icon: https://icons8.com/icon/18401/Thumb-Up
; Author: mikrom, https://www.mikrom.cz
; Version: 4.0.0

#Requires AutoHotkey v2.0
#NoTrayIcon
#Include lib\WebView2\WebView2.ahk
#Include lib\Promise.ahk
#Include lib\ComVar.ahk
#Include lib\Checker\ServiceRegistry.ahk

class CheckerApp {
    static main() {
        app := CheckerApp()
        app.setupIcons()
        app.loadSettings()
        app.parseCommandLine()
        app.createGUI()
        app.gui.Show()
    }

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

        ; Settings with defaults
        this.settings := {
            answer: 1,      ; Check result and send exit code
            debug: 0,       ; Debug mode
            beep: 0,        ; Acoustic feedback
            copymsg: 1,     ; Copy owner's message to clipboard
            timeout: 10,     ; Page load timeout in seconds
            pgclogin: 0     ; Try to login to project-gc.com
        }
        this.iniFile := "Checker.ini"
    }

    setupIcons() {
        ; Set application icon if available (AHK v2 equivalent of Menu, Tray, Icon)
        if (FileExist(A_ScriptDir "\Checker.ico")) {
            TraySetIcon(A_ScriptDir "\Checker.ico", , true)  ; true = freeze
        }
    }

    parseCommandLine() {
        if (A_Args.Length >= 9) {
            this.service := A_Args[1]
            this.lat := A_Args[2]
            this.latdeg := A_Args[3]
            this.latmin := A_Args[4]
            this.latdec := A_Args[5]
            this.lon := A_Args[6]
            this.londeg := A_Args[7]
            this.lonmin := A_Args[8]
            this.londec := A_Args[9]
            if (A_Args.Length >= 10) {
                this.url := A_Args[10]
            }
        }
    }

    createGUI() {
        ; Calculate centered position
        centerX := (A_ScreenWidth - 1000) // 2
        centerY := (A_ScreenHeight - 600) // 2

        ; Create main GUI window
        this.gui := Gui("+Resize", Translation.get("app_title"))
        this.gui.OnEvent("Close", (*) => this.exitApp())

        this.gui.MarginX := 0
        this.gui.MarginY := 0

        ; Create menu bar
        this.createMenuBar()

        ; Create WebView2 container area (starts from y0 since menu bar is native)
        this.webViewContainer := this.gui.AddText("x0 y0 w1000 h580 +Border")

        ; Create status bar at bottom
        this.createStatusBar()

        ; Set GUI position and size
        this.gui.Move(centerX, centerY, 1000, 600)

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
        this.statusBar := this.gui.AddText("x0 y580 w1000 h20 +0x1000")  ; SS_SUNKEN
        this.statusBar.BackColor := "0xF0F0F0"

        ; Left status text for loading/page messages (much wider for debug messages)
        this.statusTextLeft := this.gui.AddText("x10 y582 w880 h16", Translation.get("ready"))

        ; Right status text for checking/results (adjusted position and width)
        this.statusTextRight := this.gui.AddText("x900 y582 w90 h16 +Right", "")
    }

    loadSettings() {
        ; Load settings from INI file
        try {
            if (FileExist(this.iniFile)) {
                this.settings.answer := IniRead(this.iniFile, "Checker", "answer", 1)
                this.settings.debug := IniRead(this.iniFile, "Checker", "debug", 0)
                this.settings.beep := IniRead(this.iniFile, "Checker", "beep", 0)
                this.settings.copymsg := IniRead(this.iniFile, "Checker", "copymsg", 1)
                this.settings.timeout := IniRead(this.iniFile, "Checker", "timeout", "")
                this.settings.pgclogin := IniRead(this.iniFile, "Checker", "pgclogin", 0)
            }
        } catch as e {
            ; Use defaults if loading fails
        }
    }

    saveSettings() {
        ; Save settings to INI file
        try {
            IniWrite(this.settings.answer, this.iniFile, "Checker", "answer")
            IniWrite(this.settings.debug, this.iniFile, "Checker", "debug")
            IniWrite(this.settings.beep, this.iniFile, "Checker", "beep")
            IniWrite(this.settings.copymsg, this.iniFile, "Checker", "copymsg")
            IniWrite(this.settings.timeout, this.iniFile, "Checker", "timeout")
            IniWrite(this.settings.pgclogin, this.iniFile, "Checker", "pgclogin")
        } catch as e {
            MsgBox("Failed to save settings: " . e.message, "Error", "OK Icon!")
        }
    }

    showPreferences() {
        ; Create preferences dialog
        prefGui := Gui("+ToolWindow", Translation.get("preferences_title"))
        prefGui.MarginX := 15
        prefGui.MarginY := 15

        ; Answer checkbox
        prefGui.AddText("x15 y15", Translation.get("result_checking"))
        answerCb := prefGui.AddCheckbox("x30 y35 w300 Checked" . this.settings.answer,
            Translation.get("result_checking_desc"))

        ; Debug checkbox
        prefGui.AddText("x15 y65", Translation.get("debug_mode"))
        debugCb := prefGui.AddCheckbox("x30 y85 w300 Checked" . this.settings.debug,
            Translation.get("debug_mode_desc"))

        ; Beep checkbox
        prefGui.AddText("x15 y115", Translation.get("audio_feedback"))
        beepCb := prefGui.AddCheckbox("x30 y135 w300 Checked" . this.settings.beep,
            Translation.get("audio_feedback_desc"))

        ; Copy message checkbox
        prefGui.AddText("x15 y165", Translation.get("clipboard"))
        copymsgCb := prefGui.AddCheckbox("x30 y185 w300 Checked" . this.settings.copymsg,
            Translation.get("clipboard_desc"))

        ; Timeout field
        prefGui.AddText("x15 y215", Translation.get("timeout"))
        timeoutEdit := prefGui.AddEdit("x30 y235 w100", this.settings.timeout)
        prefGui.AddText("x140 y238", Translation.get("timeout_desc"))

        ; Project-GC login checkbox
        prefGui.AddText("x15 y265", Translation.get("pgc_integration"))
        pgcloginCb := prefGui.AddCheckbox("x30 y285 w300 Checked" . this.settings.pgclogin,
            Translation.get("pgc_integration_desc"))

        ; Buttons
        okBtn := prefGui.AddButton("x120 y325 w75 h25", Translation.get("ok"))
        cancelBtn := prefGui.AddButton("x205 y325 w75 h25", Translation.get("cancel"))

        ; Button events
        okBtn.OnEvent("Click", (*) => this.savePreferences(answerCb, debugCb, beepCb, copymsgCb, timeoutEdit,
            pgcloginCb, prefGui))
        cancelBtn.OnEvent("Click", (*) => prefGui.Destroy())
        prefGui.OnEvent("Escape", (*) => prefGui.Destroy())

        ; Show dialog
        prefGui.Show("w350 h370")
    }

    savePreferences(answerCb, debugCb, beepCb, copymsgCb, timeoutEdit, pgcloginCb, prefGui) {
        ; Save settings from dialog controls
        this.settings.answer := answerCb.Value
        this.settings.debug := debugCb.Value
        this.settings.beep := beepCb.Value
        this.settings.copymsg := copymsgCb.Value
        this.settings.timeout := timeoutEdit.Text
        this.settings.pgclogin := pgcloginCb.Value

        this.saveSettings()
        prefGui.Destroy()
    }

    showAbout() {
        aboutText := Translation.get("app_title") . "`n"
        aboutText .= Translation.get("about_version") . "`n`n"

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
                finalUrl := StrReplace(finalUrl, "https://gc.gcm.cz/validator/", "https://validator.gcm.cz/")
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
            ; Load a simple test page to verify WebView2 is working
            this.webView.NavigateToString(
                "<html><body><h1>WebView2 is working!</h1><p>No URL provided in parameters.</p></body></html>")
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

    hasValidCoordinates() {
        return (this.lat != "" && this.latdeg != "" && this.latmin != "" && this.latdec != "" &&
            this.lon != "" && this.londeg != "" && this.lonmin != "" && this.londec != "")
    }

    executeJavaScript(jsCode) {
        this.webView.ExecuteScriptAsync(jsCode)
        .then((result) => this.onCoordinatesFilled(result))
        .catch((error) => this.onCoordinatesError(error))
    }

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
                this.webView.Navigate(this.url)
            } else {
                this.updateStatus("No URL to refresh")
            }
        } catch as e {
            this.updateStatus("Refresh error: " . e.message)
        }
    }

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
                this.updateStatusRightWithColor(Translation.get("correct"), "0x00FF00") ; Green
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

    updateStatus(text) {
        ; Update left status (for compatibility with existing code)
        this.updateStatusLeft(text)
    }

    updateStatusLeft(text) {
        if (this.statusTextLeft)
            this.statusTextLeft.Text := text
    }

    updateStatusRight(text) {
        if (this.statusTextRight)
            this.statusTextRight.Text := text
    }

    updateStatusRightWithColor(text, color) {
        if (this.statusTextRight) {
            this.statusTextRight.Text := text
            ; Change text color
            try {
                this.statusTextRight.Opt("+c" . color)
            } catch {
                ; Ignore color change errors
            }
        }
    }
}

; Start the application
CheckerApp.main()