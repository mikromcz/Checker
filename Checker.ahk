; Checker AHK
; Www: http://geoget.ararat.cz/doku.php/user:skript:checker
; Forum: http://www.geocaching.cz/forum/viewthread.php?forum_id=20&thread_id=25822
; Author: mikrom, http://mikrom.cz
; Version: 0.2.2.1
;
; Documentation: http://ahkscript.org/docs/AutoHotkey.htm
; FAQ: http://www.autohotkey.com/docs/FAQ.htm
;
; parameters  service  ns       dx       mx       sx       ew       dy       my       sy       url
; param       args[1]  args[2]  args[3]  args[4]  args[5]  args[6]  args[7]  args[8]  args[9]  args[10]
; eg.         checker  N        50       15       123      E        015      54       123      http://checker.org/check?=a56sjg4678gdg
;
; ToDo:
; After load page with result check if check was "success!" then change return value (ExitApp, 1)
; In GeoGet use something like this: ret := RunExec(ahk); if ret=1 then set final waypoint tag to{?}
; after page load, STOP
; after page load, check if valid formm is present (or if there is some messga about exceeded limit)

; Special commands
; #Warn  ; Enable warnings to assist with detecting common errors.
#SingleInstance, Force ; Determines whether a script is allowed to run again when it is already running.
#NoTrayIcon ; Disables the showing of a tray icon.
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode, Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir%  ; Ensures a consistent starting directory.

; Variables
global errorLvl := 0 ; For sure set default error level, (0 - without error (default), 1 - success, 2 - wrong)
global returnResult := 0 ; Define if return check result

; Read setting from INI ^
IniRead, proxy, %A_ScriptDir%\Checker.ini, % "Checker", % "proxy"
IniRead, debug, %A_ScriptDir%\Checker.ini, % "Checker", % "debug" ; For enabling debug mode, show some infos, ListVars, ..

; Change icon of GUI title, tray, ...
; Icon from: http://www.iconarchive.com/show/colorful-long-shadow-icons-by-graphicloads/Hand-thumbs-up-like-2-icon.html
Menu, Tray, Icon, %A_ScriptDir%\Checker.ico,,1

; Language switch
If (A_Language = "0405") { ; Czech
  global textError := "Chyba"
  global textErrorParam := "Chyba: Neplatný poèet parametrù!`n`nPovolené parametry jsou:`n[service] [N|S] [Dx] [Mx] [Sx] [E|W] [Dy] [My] [Sy] [URL]`n`nPoužity byly tyto:`n"
  global textErrorService := "Chyba: Použita nepodporovaná služba!`nPodporovány jsou: geocheck, geochecker, evince, hermansky, komurka, gccounter, certitudes! (možná i finar)."
  global textErrorTimeout := "Chyba: Vypršel èasový limit naèítání stránky.`nZkuste F5 pro obnovení."
  global textDonate := "Zvažte podporu pluginu pøes <a href=""http://goo.gl/dCKefD"">PayPal</a>, nebo mi napište <a href=""mailto:mikrom@mikrom.cz"">email</a>"
  global textHint := "Pro ukonèení mùžete použít ESC a pro obnovení stránky F5"
} Else { ; Other = English
  global textError := "Error"
  global textErrorParam := "Error: Invalid number of parameters!`n`nAllowed parameters are:`n[service] [N|S] [Dx] [Mx] [Sx] [E|W] [Dy] [My] [Sy] [URL]`n`nReceived parameters are:`n"
  global textErrorService := "Error: Invalid service selected!`nUse only: geocheck, geochecker, evince, hermansky, komurka, gccounter, certitudes! (maybe finar)."
  global textErrorTimeout := "Error: Timeout while page load.`nTry press F5 for reload."
  global textDonate := "You can donate plugin by <a href=""http://goo.gl/dCKefD"">PayPal</a>, or send me an <a href=""mailto:mikrom@mikrom.cz"">email</a>"
  global textHint := "You can use ESC for quit and F5 for page reload"
}

; Add CMD paremeters to (pseudo) array. It's not necessary, parameters are in variables %1%, %2%, .. but seems not to work in my case.
; http://www.autohotkey.com/docs/Tutorial.htm#s7
; http://ahkscript.org/docs/misc/Arrays.htm#pseudo
global args := []
Loop, %0% {
  args[A_Index] := %A_Index%
  paramList := paramList . "[" . A_Index . "] " . args[A_Index] . "`n" ; Make list of parameters for next error MsgBox => [n] Param
}

; Parameter count check. There must be 10 parameters.
If (args.MaxIndex() != 10) {
  MsgBox 16, % textError, % textErrorParam . paramList
  ExitApp, errorLvl
}

; Create GUI
; http://www.autohotkey.com/docs/commands/Gui.htm
Gui, +Resize +OwnDialogs +MinSize640x480 ; Allow change GUI size, MsgBoxes is owned by main window, Set minimal window size
Gui, Add, Link, x5 y+0 vHint, % textHint . ". " . textDonate . "."
Gui, Add, ActiveX, x0 y0 w1000 h580 vWB, Shell.Explorer ; The final parameter is the name of the ActiveX component.
Gui, Show, Center w1000 h600, % "Checker"

; Implement Tabstop for ActiveX > Shell.Explorer
; Because without this TAB, ESC, maybe Ctrl+C, Ctrl+V not work in Shell.Explorer
; http://ahkscript.org/boards/viewtopic.php?f=7&t=879
pipa := ComObjQuery(wb, "{00000117-0000-0000-C000-000000000046}")
TranslateAccelerator := NumGet(NumGet(pipa+0) + 20)

OnMessage(0x0100, "WM_KeyPress") ; WM_KEYDOWN
OnMessage(0x0101, "WM_KeyPress") ; WM_KEYUP

WM_KeyPress(wParam, lParam, nMsg, hWnd) {
  Global WB, pipa, TranslateAccelerator
  Static Vars := "hWnd | nMsg | wParam | lParam | A_EventInfo | A_GuiX | A_GuiY"

  WinGetClass, ClassName, ahk_id %hWnd%
  If (ClassName = "Shell DocObject View" && wParam = 0x09) {
    WinGet, hIES, ControlListHwnd, ahk_id %hWnd% ; Find child of 'Shell DocObject View'
    ControlFocus,, ahk_id %hIES%
    Return 0
  }
  If (ClassName = "Internet Explorer_Server") {
    VarSetCapacity(MSG, 28, 0) ; MSG STructure http://goo.gl/4bHD9Z
    Loop, Parse, Vars, |, %A_Space%
      NumPut(%A_LoopField%, MSG, (A_Index-1) * 4)
    Loop 2 ; IOleInPlaceActiveObject::TranslateAccelerator method http://goo.gl/XkGZYt
      r := DllCall(TranslateAccelerator, UInt, pipa, UInt,&MSG)
    Until wParam != 9 || WB.document.activeElement != ""

    IfEqual, R, 0, Return, 0 ; S_OK: the message was translated to an accelerator.
  }
} ; => WM_KeyPress => Implement Tabstop for ActiveX > Shell.Explorer

; Function for URL load, it also handle waiting for page load
; http://www.autohotkey.com/docs/FAQ.htm#load
; http://www.autohotkey.com/board/topic/17715-determine-if-a-webpage-is-completely-loaded-in-ie/
; http://www.autohotkey.com/board/topic/77243-need-help-for-a-custom-browser/
; http://p.ahkscript.org/?p=90e74d
LoadWait(ByRef wb) {
  passCount := 0
  While (wb.Busy) { ; Seems to work perfect! Any variants with wb.ReadyState != 4 (or !="complete") hangs on some websites. geocheck, geochecker, hang on readystate 3
    Sleep, 100
    passCount += 1
    If (passCount >= 100) { ; Sleep 100ms x 100 = 10s timeout
      MsgBox 64, % textError, % textErrorTimeout
      Break
    }
  }
  Sleep, 500 ; Just for sure :)
} ; => LoadWait()

; Main function. Switch, based by first parameter "service"
; http://www.autohotkey.com/board/topic/47052-basic-webpage-controls-with-javascript-com-tutorial/
; http://www.autohotkey.com/board/topic/64563-basic-ahk-l-com-tutorial-for-webpages/
Browser(ByRef wb) {
  wb.Silent := True ; Turn Off all IE warnings, such as "if JS can run on page etc."

  If (args[1] = "geocheck") { ; ==================================================> GEOCHECK (1)
    ; URL: geocheck.org/geo_inputchkcoord.php?gid=61241961c72ab1d-b813-47da-bf03-07c67bb81ac9
    ; Captcha: YES
    Gui, Show,, % "Checker - " . args[1] ; Change title

    wb.Navigate(args[10]) ; Navigate to webpage
    LoadWait(wb) ; Wait for page load

    ; Page can be switched to two versions of form, standard or one field
    If (wb.Document.getElementsByName("coordOneField").Length = 0) { ; For classic six field version
  
      ; Determine if page has fillable element - right page
      If (wb.Document.getElementsByName("latdeg").Length <> 0) {
        ; Checking radiobuttons is little bit difficult
        Loop, % (lat := wb.Document.getElementsByName("lat")).Length ; Get elements named "lat"
        if (lat[A_index-1].Value = args[2]) ; If some of them is equal args[2]
          lat[A_index-1].Checked := True ; Check it

        wb.Document.All.latdeg.Value := args[3]
        wb.Document.All.latmin.Value := args[4]
        wb.Document.All.latdec.Value := args[5]

        ; Checking radiobuttons is little bit difficult
        Loop, % (lon := wb.Document.getElementsByName("lon")).Length ; Get elements named "lon"
        if (lon[A_index-1].Value = args[6]) ; If some of them is equal args[6]
          lon[A_index-1].Checked := True ; Check it

        wb.Document.All.londeg.Value := args[7]
        wb.Document.All.lonmin.Value := args[8]
        wb.Document.All.londec.Value := args[9]
      } 
    } Else If (wb.Document.getElementsByName("coordOneField").Length <> 0) { ; For one field version
      wb.Document.All.coordOneField.Value := args[2] . args[3] . " " . args[4] . "." . args[5] . " " . args[6] . args[7] . " " . args[8] . "." . args[9]
    } Else If (proxy = 1) {
        ; Proxy
        ; If there is no "onefield" and no "latdeg" input there is probably warning about reach max tries
        ; then, we try reload page with proxy server!
        Sleep, 1000
        wb.Navigate("http://datp.de/proxy2/index.php?q=" . args[10] . "&hl=1e7") ; Navigate to webpage
        LoadWait(wb) ; Wait for page load

        ; Checking radiobuttons is little bit difficult
        Loop, % (lat := wb.Document.getElementsByName("lat")).Length ; Get elements named "lat"
        if (lat[A_index-1].Value = args[2]) ; If some of them is equal args[2]
          lat[A_index-1].Checked := True ; Check it

        wb.Document.All.latdeg.Value := args[3]
        wb.Document.All.latmin.Value := args[4]
        wb.Document.All.latdec.Value := args[5]

        ; Checking radiobuttons is little bit difficult
        Loop, % (lon := wb.Document.getElementsByName("lon")).Length ; Get elements named "lon"
        if (lon[A_index-1].Value = args[6]) ; If some of them is equal args[6]
          lon[A_index-1].Checked := True ; Check it

        wb.Document.All.londeg.Value := args[7]
        wb.Document.All.lonmin.Value := args[8]
        wb.Document.All.londec.Value := args[9]
      } ; <= Proxy
    wb.Document.All.usercaptcha.Focus() ; Focus on captcha field

    ; Check result after page reload
    ; YES: <th colspan="2">Výborn&#283; - Tvé &#345;ešení je správné!!!</th>
    ; NO:  <td colspan="2" class="alert">Bohužel, zadaná odpov&#283;&#271; není správná. Zkuste to prosím znovu:</td>
    If (returnResult = 1) {
      LoadWait(wb) ; Wait for page load
      MsgBox, % "jedem - xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
      If RegExMatch(wb.Document.body.innerHTML, "m)Výborn&#283; - Tvé &#345;ešení je správné!!!") {
        If (debug = 1)
          MsgBox, % "correct :)"
        errorLvl := 1
      }
      If RegExMatch(wb.Document.body.innerHTML, "m)Bohužel, zadaná odpov&#283;&#271; není správná. Zkuste to prosím znovu:") {
        If (debug = 1)
          MsgBox, % "incorrect :("
        errorLvl := 2
      }
    }
  } Else If (args[1] = "geochecker") { ; ==========================================> GEOCHECKER (2)
    ; URL: geochecker.com/index.php?code=150e9c12665c476df9d1fcc30eeae605&action=check&wp=4743354e595a33&name=4d79646c6f   ...   &CaptchaChoice=Recaptcha
    ; Captcha: NO
    Gui, Show,, % "Checker - " . args[1] ; Change title

    wb.Navigate(args[10]) ; Navigate to webpage
    LoadWait(wb) ; Wait for page load

    wb.Document.All.LatString.Value := args[2] . " " . args[3] . "° " . args[4] . "." . args[5]
    wb.Document.All.LonString.Value := args[6] . " " . args[7] . "° " . args[8] . "." . args[9]
    Sleep, 500
    wb.Document.All.button.Click()

    ; Check result after page reload
    ; YES: <div class="success">Success!</div>
    ; NO:  <div class="wrong">Incorrect</div> (ES: <div class="wrong">Incorrecto</div>)
    If (returnResult = 1) {
      LoadWait(wb) ; Wait for page load
      If RegExMatch(wb.Document.body.innerHTML, "m)Success!") {
        If (debug = 1)
          MsgBox, % "correct :)"
        errorLvl := 1
      }
      If RegExMatch(wb.Document.body.innerHTML, "m)Incorrect") {
        If (debug = 1)
          MsgBox, % "incorrect :("
        errorLvl := 2
      }
    }
  } Else If (args[1] = "evince") { ; ==============================================> EVINCE (3)
    ; URL: http://evince.locusprime.net/cgi-bin/index.cgi?q=d0ZNzQeHKReGKzr
    ; Captcha: YES
    Gui, Show,, % "Checker - " . args[1] ; Change title

    wb.Navigate(args[10]) ; Navigate to webpage
    LoadWait(wb) ; Wait for page load

    wb.Document.All.NorthSouth.Value := args[2]
    wb.Document.All.LatDeg.Value := args[3]
    wb.Document.All.LatMin.Value := args[4] . "." . args[5]
    wb.Document.All.EastWest.Value := args[6]
    wb.Document.All.LonDeg.Value := args[7]
    wb.Document.All.LonMin.Value := args[8] . "." . args[9]
    wb.Document.All.recaptcha_response_field.Focus()

    ; Check result after page reload
    ; YES: <span style="font-size: large; font-weight: bold; color: rgb(206, 0, 0);">Congratulations!</span>
    ; NO:  <span style="font-size: large; font-weight: bold; color: rgb(206, 0, 0);">Sorry!</span>
    If (returnResult = 1) {
      LoadWait(wb) ; Wait for page load
      MsgBox, % "jedem - xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
      If RegExMatch(wb.Document.body.innerHTML, "m)Congratulations!") {
        If (debug = 1)
          MsgBox, % "correct :)"
        errorLvl := 1
      }
      If RegExMatch(wb.Document.body.innerHTML, "m)Sorry!") {
        If (debug = 1)
          MsgBox, % "incorrect :("
        errorLvl := 2
      }
    }
  } Else If (args[1] = "hermansky") { ; ===========================================> HERMANSKY (4)
    ; URL: http://geo.hermansky.net/index.php?co=checker&code=22377facb3ee0fbbf6e5e2b7dee042ee8687a55cd
    ; Captcha: NO
    Gui, Show,, % "Checker - " . args[1] ; Change title

    wb.Navigate(args[10]) ; Navigate to webpage
    LoadWait(wb) ; Wait for page load
    wb.Document.ParentWindow.ScrollTo(0,370) ; Scroll down because page has a huge picture in header

    wb.Document.All.vyska.Value := args[2]
    wb.Document.All.stupne21.Value := args[3]
    wb.Document.All.minuty21.Value := args[4] . "." . args[5]
    wb.Document.All.sirka.Value := args[6]
    wb.Document.All.stupne22.Value := args[7]
    wb.Document.All.minuty22.Value := args[8] . "." . args[9]
    Sleep, 500
    wb.Document.Forms[0].Submit()

    ; Check result after page reload
    ; YES: <div style='background: #77db7a; border: 1px solid black;'>Vaše souøadnice jsou spravnì, mùžete vyrazit na lov!
    ; NO:  <div style="background: #db7777; border: 1px solid black;">Vaše souøadnice jsou špatnì, poèítejte znovu.
    If (returnResult = 1) {
      LoadWait(wb) ; Wait for page load
      If RegExMatch(wb.Document.body.innerHTML, "m)Vaše souøadnice jsou spravnì, mùžete vyrazit na lov!") {
        If (debug = 1)
          MsgBox, % "correct :)"
        errorLvl := 1
      }
      If RegExMatch(wb.Document.body.innerHTML, "m)Vaše souøadnice jsou špatnì, poèítejte znovu.") {
        If (debug = 1)
          MsgBox, % "incorrect :("
        errorLvl := 2
      }
    }
    wb.Document.ParentWindow.ScrollTo(0,370) ; Scroll again after page reload
  } Else If (args[1] = "komurka") { ; =============================================> KOMURKA (5)
    ; URL: http://geo.komurka.cz/check.php?cache=GC2JCEQ
    ; Captcha: YES
    Gui, Show,, % "Checker - " . args[1] ; Change title

    wb.Navigate(args[10]) ; Navigate to webpage
    LoadWait(wb) ; Wait for page load

    If (args[2] = "N")
      wb.Document.All.select1.SelectedIndex := 0
    If (args[2] = "S")
      wb.Document.All.select1.SelectedIndex := 1
    wb.Document.All.sirka1.Value := args[3]
    wb.Document.All.sirka2.Value := args[4]
    wb.Document.All.sirka3.Value := args[5]
    If (args[6] = "E")
      wb.Document.All.select2.SelectedIndex := 0
    If (args[6] = "W")
      wb.Document.All.select2.SelectedIndex := 1
    wb.Document.All.delka1.Value := args[7]
    wb.Document.All.delka2.Value := args[8]
    wb.Document.All.delka3.Value := args[9]
    wb.Document.All.code.Focus()

    ; Check result after page reload
    ; YES: <img src="images/smile_green.jpg">
    ; NO:  <img src="images/smile_red.jpg">
    If (returnResult = 1) {
      LoadWait(wb) ; Wait for page load
      msgbox, % "jedem - xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
      If RegExMatch(wb.Document.body.innerHTML, "m)images/smile_green\.jpg") {
        If (debug = 1)
          MsgBox, % "correct :)"
        errorLvl := 1
      }
      If RegExMatch(wb.Document.body.innerHTML, "m)images/smile_red\.jpg") {
        If (debug = 1)
          MsgBox, % "incorrect :("
        errorLvl := 2
      }
    }
  } Else If (args[1] = "gccounter") { ; ===========================================> GCCOUNTER (5)
    ; URL: http://gccounter.com/gcchecker.php?site=gcchecker_check&id=2076
    ; Captcha: NO
    Gui, Show,, % "Checker - " . args[1] ; Change title

    wb.Navigate(args[10]) ; Navigate to webpage
    LoadWait(wb) ; Wait for page load

    If (args[2] = "N")
      wb.Document.All.Lat_R.SelectedIndex := 0
    If (args[2] = "S")
      wb.Document.All.Lat_R.SelectedIndex := 1
    wb.Document.All.Lat_G.Value := args[3]
    wb.Document.All.Lat_M.Value := args[4]
    wb.Document.All.Lat_MM.Value := args[5]
    If (args[6] = "E")
      wb.Document.All.Lon_R.SelectedIndex := 0
    If (args[6] = "W")
      wb.Document.All.Lon_R.SelectedIndex := 1
    wb.Document.All.Lon_G.Value := args[7]
    wb.Document.All.Lon_M.Value := args[8]
    wb.Document.All.Lon_MM.Value := args[9]
    Sleep, 500
    wb.Document.Forms[0].Submit()

    ; Check result after page reload
    ; YES: <h2 align="center" style="color:green">Herzlichen Glückwunsch!</h2>
    ; NO:  <h2 align="center" style="color:red">Schade!</h2>
    If (returnResult = 1) {
      LoadWait(wb) ; Wait for page load
      If RegExMatch(wb.Document.body.innerHTML, "m)Herzlichen Glückwunsch!") {
        If (debug = 1)
          MsgBox, % "correct :)"
        errorLvl := 1
      }
      If RegExMatch(wb.Document.body.innerHTML, "m)Schade!") {
        If (debug = 1)
          MsgBox, % "incorrect :("
        errorLvl := 2
      }
    }
  } Else If (args[1] = "certitudes") { ; ==========================================> CERTITUDES (6)
    ; URL: http://www.certitudes.org/certitude?wp=GC2QFYT
    ; Captcha: NO
    Gui, Show,, % "Checker - " . args[1] ; Change title

    wb.Navigate(args[10]) ; Navigate to webpage
    LoadWait(wb) ; Wait for page load

    wb.Document.All.coordinates.Value := args[2] . " " . args[3] . " " . args[4] . "." . args[5] . " " . args[6] . " " . args[7] . " " . args[8] . "." . args[9]
    Sleep, 500

    ; This form is difficult submit, so we must do it by this unclean way
    Loop, % (inputs := wb.Document.getElementsByTagName("input")).Length ; For all tags <input>
      if (inputs[A_index-1].Type = "submit") ; If some of them is type="submit"
        inputs[A_index-1].Click() ; Click on it

    ; Check result after page reload
    ; YES: <img src="/images/woohoo.jpg">
    ; NO:  <img src="/images/doh.jpg" align="middle">
    If (returnResult = 1) {
      LoadWait(wb) ; Wait for page load
      If (debug = 2)
        MsgBox, % wb.Document.body.innerHTML
      If RegExMatch(wb.Document.body.innerHTML, "m)/images/woohoo\.jpg") {
        If (debug = 1)
          MsgBox, % "correct :)"
        errorLvl := 1
      }
      If RegExMatch(wb.Document.body.innerHTML, "m)/images/doh\.jpg") {
        If (debug = 1)
          MsgBox, % "incorrect :("
        errorLvl := 2
      }
    }
  } Else If (args[1] = "gpscache") { ; ==========================================> GPS-CACHE (7)
    ; URL: http://geochecker.gps-cache.de/check.aspx?id=7c52d196-b9d2-4b23-ad99-5d6e1bece187
    ; Captcha: YES
    Gui, Show,, % "Checker - " . args[1] ; Change title

    wb.Navigate(args[10]) ; Navigate to webpage
    LoadWait(wb) ; Wait for page load

    wb.Document.ParentWindow.ScrollTo(0,240) ; Scroll down because page has a huge picture in header
    wb.Document.All.ListView1_txtKoords_0.Value := args[2] . args[3] . " " . args[4] . "." . args[5] . " " . args[6] . args[7] . " " . args[8] . "." . args[9]
    wb.Document.All.ListView1_txtCaptchaCode_0.Focus()
    Sleep, 500

    ; Check result after page reload
    ; YES: <img src="/images/woohoo.jpg">
    ; NO:  <table><td><img alt=":)" src="http://cool-web.de/images/smiley-weird-80.png"></td><td style="font-weight:bold;color:grey;font-size:17pt;padding-left:20px;width:500px;">Sie haben eine besondere Koordinate eingegeben, zu der der Owner eine Nachricht hinterlegt hat!<br><br></td></tr></table><b>Die Mitteilung des Owners lautet:</b><br><br>Gratuliere,  du hast die Header Koordinaten richtig eingegeben! Hier findest du jedoch leider nichts!<br><br><br /><br /></td></tr>
    ;If (returnResult = 1) {
    ;  LoadWait(wb) ; Wait for page load
    ;  If (debug = 2)
    ;    MsgBox, % wb.Document.body.innerHTML
    ;  If RegExMatch(wb.Document.body.innerHTML, "m)/images/woohoo\.jpg") {
    ;    If (debug = 1)
    ;      MsgBox, % "correct :)"
    ;    errorLvl := 1
    ;  }
    ;  If RegExMatch(wb.Document.body.innerHTML, "m)/images/doh\.jpg") {
    ;    If (debug = 1)
    ;      MsgBox, % "incorrect :("
    ;    errorLvl := 2
    ;  }
    ;}
  } Else If (args[1] = "finar") { ; ===============================================> FINAR (7)
    ; URL: http://gc.elanot.cz/index.php/data-final.html
    ; Captcha: NO
    Gui, Show,, % "Checker - " . args[1] ; Change title

    wb.Navigate(args[10]) ; Navigate to webpage
    LoadWait(wb) ; Wait for page load

    wb.Document.All.fabrik_list_filter_all_1_com_fabrik_1.Value := args[2] . " " . args[3] . "° " . args[4] . "." . args[5] . " " . args[6] . " " . args[7] . "° " . args[8] . "." . args[9]
    Sleep, 500
    wb.Document.All.filter.Click()

    ; Check result after page reload
    ; YES: <div class="emptyDataMessage" style="">Žádná data nenalezena</div> display:none by CSS
    ; NO:  <div class="emptyDataMessage" style="">Žádná data nenalezena</div>
    If (returnResult = 1) {
      LoadWait(wb) ; Wait for page load
      If RegExMatch(wb.Document.body.innerHTML, "m)Žádná data nenalezena") {
        If (debug = 1)
          MsgBox, % "correct :)"
        errorLvl := 1
      }
      If RegExMatch(wb.Document.body.innerHTML, "m)Žádná data nenalezena") {
        If (debug = 1)
          MsgBox, % "incorrect :("
        errorLvl := 2
      }
    }
  } Else { ; =====================================================================> SERVICE ERROR
    MsgBox 16, % textError, % textErrorService
    ExitApp, errorLvl
  }
} ; => Browser()

; Just for debugging
If (debug = 1)
  ListVars

; Call main function
Browser(wb) ;GoSub, Browser ; http://www.autohotkey.com/docs/commands/Gosub.htm
Return

; F5 for reload page (and fill form again)
F5:: ; http://ahkscript.org/docs/KeyList.htm
  Browser(wb) ;GoSub, Browser
Return

; Run when GUI is resized
GuiSize: ; http://ahkscript.org/docs/commands/Gui.htm#GuiSize
  ; http://www.autohotkey.com/docs/commands/GuiControl.htm
  GuiControl, Move, wb, % "w" A_GuiWidth "h" A_GuiHeight - 20
  GuiControl, Move, hint, % "x" 5 "y" A_GuiHeight - 15
Return

; Run when GUI is closed
GuiClose: ; http://ahkscript.org/docs/commands/Gui.htm#GuiClose
  ObjRelease(pipa) ; Implement Tabstop for ActiveX > Shell.Explorer
  Gui Destroy
  ExitApp, errorLvl
Return

; Run when ESC is pressed with GUI active
GuiEscape: ; http://ahkscript.org/docs/commands/Gui.htm#GuiEscape
  ObjRelease(pipa) ; Implement Tabstop for ActiveX > Shell.Explorer
  ExitApp, errorLvl
Return
