; Checker AHK
; Www: http://geoget.ararat.cz/doku.php/user:skript:checker
; Forum: http://www.geocaching.cz/forum/viewthread.php?forum_id=20&thread_id=25822
; Author: mikrom, http://mikrom.cz
; Version: 0.2.0.1
;
; Documentation: http://ahkscript.org/docs/AutoHotkey.htm
; FAQ: http://www.autohotkey.com/docs/FAQ.htm
;
; parameters  service   ns      dx      mx      sx      ew      dy      my      sy      url
; param       param1    param2  param3  param4  param5  param6  param7  param8  param9  param10
; eg.         checker   N       50      15      123     E       015     54      123     http://checker.org/check?=a56sjg4678gdg

; Special commands
#SingleInstance, Force ; http://ahkscript.org/docs/commands/_SingleInstance.htm
#NoTrayIcon ; http://ahkscript.org/docs/commands/_NoTrayIcon.htm
#NoEnv ; http://ahkscript.org/docs/commands/_NoEnv.htm

Menu, Tray, Icon, %A_ScriptDir%\Checker.ico,,1 ; Change icon of GUI title, tray, ...

; Language switch,
If (A_Language = "0405") { ; Czech
  textError := "Chyba"
  textErrorParam := "Chyba: Neplatný poèet parametrù!`n`nPovolené parametry jsou:`n[service] [N|S] [Dx] [Mx] [Sx] [E|W] [Dy] [My] [Sy] [URL]`n`nPoužity byly tyto:`n"
  textErrorService := "Chyba: Použita nepodporovaná služba!`nPodporovány jsou: geocheck, geochecker, evince, hermansky, komurka, gccounter, certitudes! (možná i finar)"
  textDonate := "Zvažte podporu pluginu pøes <a href=""http://goo.gl/dCKefD"">PayPal</a>, nebo mi napište <a href=""mailto:mikrom@mikrom.cz"">email</a>"
  textHint := "Pro ukonèení mùžete použít ESC a pro obnovení stránky F5"
} Else { ; Other = English
  textError := "Error"
  textErrorParam := "Error: Invalid number of parameters!`n`nAllowed parameters are:`n[service] [N|S] [Dx] [Mx] [Sx] [E|W] [Dy] [My] [Sy] [URL]`n`nReceived parameters are:`n"
  textErrorService := "Error: Invalid service selected!`nUse only: geocheck, geochecker, evince, hermansky, komurka, gccounter, certitudes! (maybe finar)"
  textDonate := "You can donate plugin by <a href=""http://goo.gl/dCKefD"">PayPal</a>, or send me an <a href=""mailto:mikrom@mikrom.cz"">email</a>"
  textHint := "You can use ESC for quit and F5 for page reload"
}

; Add CMD paremeters to array
param := Object() ; Each array must be initialized before use, http://ahkscript.org/docs/misc/Arrays.htm
paramCount := 0
Loop, %0% {
  paramCount += 1
  param%paramCount% := %A_Index%
  paramList := paramList . "[" . A_Index . "] " . %A_Index% . "`n" ; Make list of parameters for next error MagBox => [n] Param
}

; Parameter count check. The left side of a non-expression if-statement is always the name of a variable.
If 0 <> 10
{
  MsgBox 16, % textError, % textErrorParam . paramList
  ExitApp
}

; Function for URL load, it also handle waiting for page load
; http://www.autohotkey.com/docs/FAQ.htm#load
; http://www.autohotkey.com/board/topic/17715-determine-if-a-webpage-is-completely-loaded-in-ie/
; http://ahkscript.org/boards/viewtopic.php?t=7367
; http://www.autohotkey.com/board/topic/77243-need-help-for-a-custom-browser/
; ReadyState 0=uninitialized (Has not started loading yet)
;            1=loading (Is loading)
;            2=loaded (Has been loaded)
;            3=interactive (Has loaded enough and the user can interact with it)
;            4=complete (Fully loaded)
LoadURL(wb,url) {
  wb.Silent := True ; Turn Off all IE warnings, such as "if JS can run on page etc."
  wb.Navigate(url) ; Navigate to webpage

  ;While wb.Busy or wb.ReadyState != 4 or wb.Document.ReadyState != "complete" ; Not work well, hang on some websites
  ;While wb.Busy or wb.ReadyState != 4 ; Not work well, hang on some websites
  ;While wb.Busy ; Not work well, hang on some websites
  ;While (wb.Busy or wb.ReadyState != 3) ; or wb.ReadyState != 4) ; ! Some webpages (geocheck, geochecker, ..) return readystate 3 and not 4 !
  ;While (wb.ReadyState != 3) ; Even this is not 100% errorless
  passCount := 0
  While (wb.Busy or wb.ReadyState != 4) {
    Sleep, 500
    passCount += 1
    If (passCount >= 10) { ; Sleep 500ms x 10 = 5s timeout
      ;MsgBox 16, % "Timeout", % "Timeout! Browser.ReadyState="wb.ReadyState . " and not 4, we wait " . passCount . "x 500ms"
      Break
    }
  }
  ;MsgBox, % "Succesfully loaded!"

  Sleep, 500 ; Just for sure :)
}

;ListVars

; Create GUI
; http://www.autohotkey.com/docs/commands/Gui.htm
Gui, +Resize +OwnDialogs +MinSize640x480 ; Allow change GUI size, MsgBoxes is owned by main window, Set minimal window size
Gui, Add, Link, x5 y+0 vHint, % textHint . ". " . textDonate . "."
Gui, Add, ActiveX, x0 y0 w1000 h580 vWB, Shell.Explorer ; The final parameter is the name of the ActiveX component.
Gui, Show, Center w1000 h600, % "Checker"

; Implement Tabstop for ActiveX > Shell.Explorer
; Because without this TAB, ESC, maybe Ctrl+C, Ctrl+V not work in Shell.Browser
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
      r := DllCall(TranslateAccelerator, UInt,pipa, UInt,&MSG)
    Until wParam != 9 || WB.document.activeElement != ""

    IfEqual, R, 0, Return, 0 ; S_OK: the message was translated to an accelerator.
  }
}
; /Implement Tabstop for ActiveX > Shell.Explorer

; Call main function
GoSub, Browser ; http://www.autohotkey.com/docs/commands/Gosub.htm
Return

; F5 for reload page (and fill form again)
F5:: ; http://ahkscript.org/docs/KeyList.htm
  GoSub, Browser
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
  ExitApp
Return

; Run when ESC is pressed with GUI active
GuiEscape: ; http://ahkscript.org/docs/commands/Gui.htm#GuiEscape
  ExitApp
Return

; Main function. Switch, based by first parameter "service"
; http://www.autohotkey.com/board/topic/47052-basic-webpage-controls-with-javascript-com-tutorial/
; http://www.autohotkey.com/board/topic/64563-basic-ahk-l-com-tutorial-for-webpages/
Browser:
If (param1 = "geocheck") { ; ==================================================> GEOCHECK (1)
  ; URL: geocheck.org/geo_inputchkcoord.php?gid=61241961c72ab1d-b813-47da-bf03-07c67bb81ac9
  ; Captcha: yes
  Gui, Show,, % "Checker - " . param1 ; Change title

  LoadURL(wb,param10) ; Load URL

  ; Page can be switched to two versions of form, standard or one field
  If (wb.Document.getElementsByName("coordOneField").Length = 0) {
    ; Checking radiobuttons is little bit difficult
    Loop, % (lat := wb.Document.getElementsByName("lat")).Length ; Get elements named "lat"
      if (lat[A_index-1].Value = param2) ; If some of them is equal param2
        lat[A_index-1].Checked := True ; Check it

    wb.Document.All.latdeg.Value := param3
    wb.Document.All.latmin.Value := param4
    wb.Document.All.latdec.Value := param5

    ; Checking radiobuttons is little bit difficult
    Loop, % (lon := wb.Document.getElementsByName("lon")).Length ; Get elements named "lon"
      if (lon[A_index-1].Value = param6) ; If some of them is equal param6
        lon[A_index-1].Checked := True ; Check it

    wb.Document.All.londeg.Value := param7
    wb.Document.All.lonmin.Value := param8
    wb.Document.All.londec.Value := param9
  } Else {
    wb.Document.All.coordOneField.Value := param2 . param3 . " " . param4 . "." . param5 . " " . param6 . param7 . " " . param8 . "." . param9
  }
  Sleep, 500
  wb.Document.All.usercaptcha.Focus() ; Focus on captcha field

} Else If (param1 = "geochecker") { ; ==========================================> GEOCHECKER (2)
  ; URL: http://www.geochecker.com/index.php?code=150e9c12665c476df9d1fcc30eeae605&action=check&wp=4743354e595a33&name=4d79646c6f   ...   &CaptchaChoice=Recaptcha
  ; Captcha: no
  Gui, Show,, % "Checker - " . param1 ; Change title

  LoadURL(wb,param10) ; Load URL

  wb.Document.All.LatString.Value := param2 . " " . param3 . "° " . param4 . "." . param5
  wb.Document.All.LonString.Value := param6 . " " . param7 . "° " . param8 . "." . param9
  Sleep, 500
  wb.Document.All.button.Click()

} Else If (param1 = "evince") { ; ==============================================> EVINCE (3)
  ; URL: http://evince.locusprime.net/cgi-bin/index.cgi?q=d0ZNzQeHKReGKzr
  ; Captcha: yes
  Gui, Show,, % "Checker - " . param1 ; Change title

  LoadURL(wb,param10) ; Load URL

  wb.Document.All.NorthSouth.Value := param2
  wb.Document.All.LatDeg.Value := param3
  wb.Document.All.LatMin.Value := param4 . "." . param5
  wb.Document.All.EastWest.Value := param6
  wb.Document.All.LonDeg.Value := param7
  wb.Document.All.LonMin.Value := param8 . "." . param9
  Sleep, 500
  wb.Document.All.recaptcha_response_field.Focus()

} Else If (param1 = "hermansky") { ; ===========================================> HERMANSKY (4)
  ; URL: http://geo.hermansky.net/index.php?co=checker&code=22377facb3ee0fbbf6e5e2b7dee042ee8687a55cd
  ; Captcha: no
  Gui, Show,, % "Checker - " . param1 ; Change title

  LoadURL(wb,param10) ; Load URL

  wb.Document.ParentWindow.ScrollTo(0,370) ; Scroll down because page has a huge picture in header

  wb.Document.All.vyska.Value := param2
  wb.Document.All.stupne21.Value := param3
  wb.Document.All.minuty21.Value := param4 . "." . param5
  wb.Document.All.sirka.Value := param6
  wb.Document.All.stupne22.Value := param7
  wb.Document.All.minuty22.Value := param8 . "." . param9
  Sleep, 500
  wb.Document.Forms[0].Submit()

  Sleep, 1000
  wb.Document.ParentWindow.ScrollTo(0,370) ; Scroll again after page reload

} Else If (param1 = "komurka") { ; =============================================> KOMURKA (5)
  ; URL: http://geo.komurka.cz/check.php?cache=GC2JCEQ
  ; Captcha: yes
  Gui, Show,, % "Checker - " . param1 ; Change title

  LoadURL(wb,param10) ; Load URL

  If (param2 = "N")
    wb.Document.All.select1.SelectedIndex := 0
  If (param2 = "S")
    wb.Document.All.select1.SelectedIndex := 1
  wb.Document.All.sirka1.Value := param3
  wb.Document.All.sirka2.Value := param4
  wb.Document.All.sirka3.Value := param5
  If (param6 = "E")
    wb.Document.All.select2.SelectedIndex := 0
  If (param6 = "W")
    wb.Document.All.select2.SelectedIndex := 1
  wb.Document.All.delka1.Value := param7
  wb.Document.All.delka2.Value := param8
  wb.Document.All.delka3.Value := param9
  Sleep, 500
  wb.Document.All.code.Focus()

} Else If (param1 = "gccounter") { ; ===========================================> GCCOUNTER (5)
  ; URL: http://gccounter.com/gcchecker.php?site=gcchecker_check&id=2076
  ; Captcha: no
  Gui, Show,, % "Checker - " . param1 ; Change title

  LoadURL(wb,param10) ; Load URL

  If (param2 = "N")
    wb.Document.All.Lat_R.SelectedIndex := 0
  If (param2 = "S")
    wb.Document.All.Lat_R.SelectedIndex := 1
  wb.Document.All.Lat_G.Value := param3
  wb.Document.All.Lat_M.Value := param4
  wb.Document.All.Lat_MM.Value := param5
  If (param6 = "E")
    wb.Document.All.Lon_R.SelectedIndex := 0
  If (param6 = "W")
    wb.Document.All.Lon_R.SelectedIndex := 1
  wb.Document.All.Lon_G.Value := param7
  wb.Document.All.Lon_M.Value := param8
  wb.Document.All.Lon_MM.Value := param9
  Sleep, 500
  wb.Document.Forms[0].Submit()

} Else If (param1 = "certitudes") { ; ==========================================> CERTITUDES (6)
  ; URL: http://www.certitudes.org/certitude?wp=GC2QFYT
  ; Captcha: no
  Gui, Show,, % "Checker - " . param1 ; Change title

  LoadURL(wb,param10) ; Load URL

  wb.Document.All.coordinates.Value := param2 . " " . param3 . " " . param4 . "." . param5 . " " . param6 . " " . param7 . " " . param8 . "." . param9
  Sleep, 500

  ; This form is difficult submit, so we must do it by this unclean way
  Loop, % (inputs := wb.Document.getElementsByTagName("input")).Length ; For all tags <input>
    if (inputs[A_index-1].Type = "submit") ; If some of them is type="submit"
      inputs[A_index-1].Click() ; Click on it

} Else If (param1 = "finar") { ; ===============================================> FINAR (7)
  ; URL: http://gc.elanot.cz/index.php/data-final.html
  ; Captcha: no
  Gui, Show,, % "Checker - " . param1 ; Change title

  LoadURL(wb,param10) ; Load URL

  wb.Document.All.fabrik_list_filter_all_1_com_fabrik_1.Value := param2 . " " . param3 . "° " . param4 . "." . param5 . " " . param6 . " " . param7 . "° " . param8 . "." . param9
  Sleep, 500
  wb.Document.All.filter.Click()

} Else { ; =====================================================================> SERVICE ERROR
  MsgBox 16, % textError, % textErrorService
  ExitApp
}
Return
