;
; Checker
; Www: http://geoget.ararat.cz/doku.php/user:skript:checker
; Forum: http://www.geocaching.cz/forum/viewthread.php?forum_id=20&thread_id=25822
; Author: mikrom, http://mikrom.cz
; Version: 0.1.3.0
;
; parameters  service     ns          dx          mx          sx          ew          dy          my          sy          url
; eg.         checker     N           50          15          123         E           015         54          123         http://checker.org/check?=a56sjg4678gdg
; $CmdLine[0] $CmdLine[1] $CmdLine[2] $CmdLine[3] $CmdLine[4] $CmdLine[5] $CmdLine[6] $CmdLine[7] $CmdLine[8] $CmdLine[9] $CmdLine[10]
;
; AutoIt3.3.10.0 - 3.3.10.2 has copy&paste not work: http://www.autoitscript.com/forum/topic/158186-embedded-ie-copying-content
; Trac: http://www.autoitscript.com/trac/autoit/ticket/2639
; To uz nas ale ted, kdyz si vytvarime vlastni prohlicez, netrapi :)
;
; https://www.autoitscript.com/wiki/Best_coding_practices
;
; _IENavigate ma u geocheck.org nejaky problem, ze zustane viset 5min a pak chcipne s chybou proroze si mysli, ze se stranka nenacetla
; asi se to da vyresit editaci IE.au3 dle https://www.autoitscript.com/forum/topic/164228-ie-object-lost-using-ienavigate/?do=findComment&comment=1213857
; kolem radku 472 jsem pridal kousek kodu
; ; ADD THIS 3 LINES
; ElseIf ($oObject.readyState = 3 and Not($oObject.busy)) Then
;   $iErrorStatusCode = 0
;   $bAbort = True

;Set AutoIt options
AutoItSetOption("TrayIconDebug", 0) ; Show debug info in tray icon
AutoItSetOption("TrayIconHide", 1)  ; 0 = do not hide, 1 = hide tray ic

; Include important libraries
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <IE.au3>

; Define global variables
Global $oIE, $oForm, $oDonate

; Add one useful hotkeys
HotKeySet("{ESC}", "Terminate")
HotKeySet("{F5}", "Refresh")

; Check correct number of parameters
If $CmdLine[0] <> 10 Then
  MsgBox(48, "Error", "Error: Invalid number of parameters!" & @CRLF & "Parameters are:" & @CRLF & "[service] [N|S] [Dx] [Mx] [Sx] [E|W] [Dy] [My] [Sy] [URL]" & @CRLF & $CmdLine)
  Exit
EndIf

; Call Main function
Browser()

; Main function which create window with embeded Internet Explorer core
Func Browser()
  ; Main window
  Local $hGUI = GUICreate("Checker Browser", 1000, 600, (@DesktopWidth - 1000) / 2, (@DesktopHeight - 600) / 2, $WS_OVERLAPPEDWINDOW + $WS_CLIPSIBLINGS + $WS_CLIPCHILDREN)

  $oIE = _IECreateEmbedded()
  Local $oContent = GUICtrlCreateObj($oIE, 0, 0, 1000, 580)                     ; Creates an ActiveX control in the GUI.

  ; Donate button
  Donate(860, 583)

  ; Changes the state of a GUI window. Show GUI
  GUISetState(@SW_SHOW, $hGUI)

  ; Call function that load webpage
  Content()

  ; Waiting for user to close the window
  While 1
    Local $iMsg = GUIGetMsg()
    Select
      Case $iMsg = $GUI_EVENT_RESIZED                                           ; Call when window resized
        Local $aPos = WinGetPos("[ACTIVE]")                                     ; Get size $aPos[0], $aPos[1], $aPos[2], $aPos[3] .. x-pos, y-pos, width, height
        ;MsgBox(64, "", "Width: " & $aPos[2] & @CRLF & "Height: " & $aPos[3])    ; For debug
        GUICtrlSetPos($oContent, 0, 0, $aPos[2] - 8, $aPos[3] - 50)              ; Dynamically change $oContent size
        ;GUICtrlSetPos($oDonate, $aPos[2] - 150, $aPos[3] - 47)                  ; Dynamically change $oDonate size - not work well, text wrapping
        ; This stupid way it works best - build it up, tear it down
        ;GUICtrlDelete($oDonate)                                                  ; Delete $oDonate
        Donate($aPos[2] - 150, $aPos[3] - 47)
        ;$oDonate = GUICtrlCreateLabel("Pøispìjte na vývoj Checkeru", $aPos[2] - 150, $aPos[3] - 47) ; Create new at new postiion
        ;GUICtrlSetColor($oDonate, 0x0000FF)                                      ; Set text color to blue - not work? why?!
        ;GUICtrlSetCursor($oDonate, 0)                                            ; Change mouse cursor to hand on hover
      Case $iMsg = $GUI_EVENT_CLOSE                                             ; Call when window closed
        ExitLoop
      Case $iMsg = $oDonate                                                      ; Call when $oDonate is clicked
        ShellExecute("http://goo.gl/dCKefD") ;_IENavigate($oIE, "http://paypal.com")
        ExitLoop
    EndSelect
  WEnd

  ;Cleanup
  GUIDelete($hGUI)
EndFunc ; ==> Browser

; Load webpage with given parameters
Func Content()
  Switch $CmdLine[1]
    ; ==========================================================================> GEOCHECK
    ; url: geocheck.org/geo_inputchkcoord.php?gid=61241961c72ab1d-b813-47da-bf03-07c67bb81ac9
    ; captcha: yes
    Case "geocheck"
      _IENavigate($oIE, $CmdLine[10])                                                   ; Open url
      If @error Then                                                                    ; IE Errors: 1-General, 2-COM, 3-InvalidData, 4-InvalidObject, 6-Loadwait, 8-AccessDenied, 9-ClientDisconnect
          MsgBox(48, "Error", "There was a problem opening webpage!" & @CRLF & "Error: " & @error)
      EndIf
      _IEAction($oIE, "stop")                                                           ; Cancels any pending navigation or download operation and stops any dynamic page elements, such as background sounds and animations.
      $oForm = _IEFormGetObjByName($oIE, "geoform")                                     ; Form name
      _IEFormElementRadioSelect($oForm, $CmdLine[2], "lat")                             ; Lat radio select
      _IEFormElementSetValue(_IEFormElementGetObjByName($oForm, "latdeg"), $CmdLine[3]) ; LatDeg
      _IEFormElementSetValue(_IEFormElementGetObjByName($oForm, "latmin"), $CmdLine[4]) ; LatMin
      _IEFormElementSetValue(_IEFormElementGetObjByName($oForm, "latdec"), $CmdLine[5]) ; LatDec
      _IEFormElementRadioSelect($oForm, $CmdLine[6], "lon")                             ; Lon radio select
      _IEFormElementSetValue(_IEFormElementGetObjByName($oForm, "londeg"), $CmdLine[7]) ; LonDec
      _IEFormElementSetValue(_IEFormElementGetObjByName($oForm, "lonmin"), $CmdLine[8]) ; LonMin
      _IEFormElementSetValue(_IEFormElementGetObjByName($oForm, "londec"), $CmdLine[9]) ; LonDec
      _IEAction(_IEFormElementGetObjByName($oForm, "usercaptcha"), "focus")             ; Captcha field - set focus

    ; ==========================================================================> GEOCHECKER
    ; url: http://www.geochecker.com/index.php?code=150e9c12665c476df9d1fcc30eeae605&action=check&wp=4743354e595a33&name=4d79646c6f
	 ; url: http://www.geochecker.com/index.php?code=150e9c12665c476df9d1fcc30eeae605&action=check&wp=4743354e595a33&name=4d79646c6f&CaptchaChoice=Recaptcha
    ; captcha: no
    Case "geochecker"
      _IENavigate($oIE, $CmdLine[10])                                                                ; Open url
      ;_IENavigate($oIE, $CmdLine[10] & "&CaptchaChoice=Recaptcha")                                   ; Open url, pridano &CaptchaChoice=Recaptcha pro alternativni captchu
      If @error Then                                                                                 ; IE Errors: 1-General, 2-COM, 3-InvalidData, 4-InvalidObject, 6-Loadwait, 8-AccessDenied, 9-ClientDisconnect
          MsgBox(48, "Error", "There was a problem opening webpage!" & @CRLF & "Error: " & @error)
      EndIf
      _IEAction($oIE, "stop")                                                                        ; Cancels any pending navigation or download operation and stops any dynamic page elements, such as background sounds and animations.
      $oForm = _IEFormGetObjByName($oIE, "form")                                                     ; Form name
      _IEFormElementSetValue(_IEFormElementGetObjByName($oForm, "LatString"), $CmdLine[2] & " " & _
                                                                              $CmdLine[3] & " " & _
                                                                              $CmdLine[4] & "." & _
                                                                              $CmdLine[5])           ; LatString
      _IEFormElementSetValue(_IEFormElementGetObjByName($oForm, "LonString"), $CmdLine[6] & " " & _
                                                                              $CmdLine[7] & " " & _
                                                                              $CmdLine[8] & "." & _
                                                                              $CmdLine[9])           ; LonString
      ;Sleep(1000)                                                                                    ; Wait a while
      ;_IEAction(_IEFormElementGetObjByName($oForm, "button"), "click")                               ; Submit, v 2015 pridali captchu, tak uz neni potreba :(
      ;_IEFormSubmit($oForm)                                                                          ; Submit 2nd version :)
      ;_IEAction($oIE, "stop")
      ;$oIE.document.parentwindow.scroll(0, 200)                                                      ; Scroll a little bit down :), taky uz od 2015 neni potreba

    ; ==========================================================================> EVINCE
    ; url: http://evince.locusprime.net/cgi-bin/index.cgi?q=d0ZNzQeHKReGKzr
    ; captcha: yes
    Case "evince"
      _IENavigate($oIE, $CmdLine[10])                                                             ; Open url
      If @error Then                                                                              ; IE Errors: 1-General, 2-COM, 3-InvalidData, 4-InvalidObject, 6-Loadwait, 8-AccessDenied, 9-ClientDisconnect
          MsgBox(48, "Error", "There was a problem opening webpage!" & @CRLF & "Error: " & @error)
      EndIf
      _IEAction($oIE, "stop")                                                                     ; Cancels any pending navigation or download operation and stops any dynamic page elements, such as background sounds and animations.
      $oForm = _IEFormGetObjByName($oIE, "ev_form01")                                             ; Form name
      _IEFormElementSetValue(_IEFormElementGetObjByName($oForm, "NorthSouth"), $CmdLine[2])       ; NorthSouth
      _IEFormElementSetValue(_IEFormElementGetObjByName($oForm, "LatDeg"), $CmdLine[3])           ; LatDeg
      _IEFormElementSetValue(_IEFormElementGetObjByName($oForm, "LatMin"), $CmdLine[4] & "." & _
                                                                           $CmdLine[5])           ; LatMin
      _IEFormElementSetValue(_IEFormElementGetObjByName($oForm, "EastWest"), $CmdLine[6])         ; EastWest
      _IEFormElementSetValue(_IEFormElementGetObjByName($oForm, "LonDeg"), $CmdLine[7])           ; LonDeg
      _IEFormElementSetValue(_IEFormElementGetObjByName($oForm, "LonMin"), $CmdLine[8] & "." & _
                                                                           $CmdLine[9])           ; LonMin
      _IEAction(_IEFormElementGetObjByName($oForm, "recaptcha_response_field"), "focus")          ; Captcha field - set focus

    ; ==========================================================================> HERMANSKY
    ; url: http://geo.hermansky.net/index.php?co=checker&code=2542e4245f80d4f7783e41ed7503fba6b3c8cc3188ff05
    ; captcha: no
    Case "hermansky"
      _IENavigate($oIE, $CmdLine[10])                                                  ; Open url
      If @error Then                                                                   ; IE Errors: 1-General, 2-COM, 3-InvalidData, 4-InvalidObject, 6-Loadwait, 8-AccessDenied, 9-ClientDisconnect
          MsgBox(48, "Error", "There was a problem opening webpage!" & @CRLF & "Error: " & @error)
      EndIf
      _IEAction($oIE, "stop")                                                          ; Cancels any pending navigation or download operation and stops any dynamic page elements, such as background sounds and animations.
      ;$oForm = _IEFormGetObjByName($oIE, "form1")                                     ; Form name - non exist!
      _IEFormElementSetValue(_IEGetObjByName($oIE, "vyska"), $CmdLine[2])              ; vyska
      _IEFormElementSetValue(_IEGetObjByName($oIE, "stupne21"), $CmdLine[3])           ; stupne21
      _IEFormElementSetValue(_IEGetObjByName($oIE, "minuty21"), $CmdLine[4] & "." & _
                                                                $CmdLine[5])           ; minuty21
      _IEFormElementSetValue(_IEGetObjByName($oIE, "sirka"), $CmdLine[6])              ; sirka
      _IEFormElementSetValue(_IEGetObjByName($oIE, "stupne22"), $CmdLine[7])           ; stupne22
      _IEFormElementSetValue(_IEGetObjByName($oIE, "minuty22"), $CmdLine[8] & "." & _
                                                                $CmdLine[9])           ; minuty22
      Sleep(1000)                                                                      ; Wait a while
      ; Because submit button has no NAME we must do it this stupid way
      $oButtons = _IETagNameGetCollection($oIE, "input")                               ; Search all inputs
      For $oButton In $oButtons
        If String($oButton.type) = "submit" Then                                       ; if input has type=submit
         _IEAction($oButton, "click")                                                  ; click on it
        EndIf
      Next
      Sleep(500)
      _IEAction($oIE, "stop")
      $oIE.document.parentwindow.scroll(0, 600)                                        ; Scroll a little bit down :)

    ; ==========================================================================> KOMURKA
    ; url: http://geo.komurka.cz/check.php?cache=GC2JCEQ
    ; captcha: yes
    Case "komurka"
      _IENavigate($oIE, $CmdLine[10])                                             ; Open url
      If @error Then                                                              ; IE Errors: 1-General, 2-COM, 3-InvalidData, 4-InvalidObject, 6-Loadwait, 8-AccessDenied, 9-ClientDisconnect
          MsgBox(48, "Error", "There was a problem opening webpage!" & @CRLF & "Error: " & @error)
      EndIf
      _IEAction($oIE, "stop")                                                     ; Cancels any pending navigation or download operation and stops any dynamic page elements, such as background sounds and animations.
      $oForm = _IEFormGetObjByName($oIE, "form1")                                 ; Form name
      _IEFormElementOptionSelect(_IEGetObjByName($oForm, "select1"), $CmdLine[2]) ; select1
      _IEFormElementSetValue(_IEGetObjByName($oForm, "sirka1"), $CmdLine[3])      ; sirka1
      _IEFormElementSetValue(_IEGetObjByName($oForm, "sirka2"), $CmdLine[4])      ; sirka2 (if two digit let it be)
      _IEFormElementSetValue(_IEGetObjByName($oForm, "sirka3"), $CmdLine[5])      ; sirka3
      _IEFormElementOptionSelect(_IEGetObjByName($oForm, "select2"), $CmdLine[6]) ; select2
      _IEFormElementSetValue(_IEGetObjByName($oForm, "delka1"), $CmdLine[7])      ; delka1
      _IEFormElementSetValue(_IEGetObjByName($oForm, "delka2"), $CmdLine[8])      ; delka2 (if two digit let it be)
      _IEFormElementSetValue(_IEGetObjByName($oForm, "delka3"), $CmdLine[9])      ; delka3
      _IEAction(_IEFormElementGetObjByName($oForm, "code"), "focus")              ; Captcha field - set focus

    ; ==========================================================================> GCCOUNTER
    ; url: http://gccounter.com/gcchecker.php?site=gcchecker_check&id=2076
    ; captcha: no
    Case "gccounter"
      _IENavigate($oIE, $CmdLine[10])                                         ; Open url
      If @error Then                                                          ; IE Errors: 1-General, 2-COM, 3-InvalidData, 4-InvalidObject, 6-Loadwait, 8-AccessDenied, 9-ClientDisconnect
          MsgBox(48, "Error", "There was a problem opening webpage!" & @CRLF & "Error: " & @error)
      EndIf
      _IEAction($oIE, "stop")                                                 ; Cancels any pending navigation or download operation and stops any dynamic page elements, such as background sounds and animations.
      ;$oForm = _IEFormGetObjByName($oIE, "form1")                            ; Form name - non exist!
      _IEFormElementOptionSelect(_IEGetObjByName($oIE, "Lat_R"), $CmdLine[2]) ; Lat_R
      _IEFormElementSetValue(_IEGetObjByName($oIE, "Lat_G"), $CmdLine[3])     ; Lat_G
      _IEFormElementSetValue(_IEGetObjByName($oIE, "Lat_M"), $CmdLine[4])     ; Lat_M
      _IEFormElementSetValue(_IEGetObjByName($oIE, "Lat_MM"), $CmdLine[5])    ; Lat_MM
      _IEFormElementOptionSelect(_IEGetObjByName($oIE, "Lon_R"), $CmdLine[6]) ; Lon_R
      _IEFormElementSetValue(_IEGetObjByName($oIE, "Lon_G"), $CmdLine[7])     ; Lon_G
      _IEFormElementSetValue(_IEGetObjByName($oIE, "Lon_M"), $CmdLine[8])     ; Lon_M
      _IEFormElementSetValue(_IEGetObjByName($oIE, "Lon_MM"), $CmdLine[9])    ; Lon_MM
      Sleep(1000)                                                             ; Wait a while
      ; Because submit button has no NAME we must do it this stupid way
      $oButtons = _IETagNameGetCollection($oIE, "input")                      ; Search all inputs
      For $oButton In $oButtons
        If String($oButton.type) = "submit" Then                              ; If input has type=submit
         _IEAction($oButton, "click")                                         ; Click on it
        EndIf
      Next

    ; ==========================================================================> CERTITUDES
    ; url: http://www.certitudes.org/certitude?wp=GC2QFYT
    ; captcha: no
    Case "certitudes"
      _IENavigate($oIE, $CmdLine[10])                                                     ; Open url
      If @error Then                                                                      ; IE Errors: 1-General, 2-COM, 3-InvalidData, 4-InvalidObject, 6-Loadwait, 8-AccessDenied, 9-ClientDisconnect
          MsgBox(48, "Error", "There was a problem opening webpage!" & @CRLF & "Error: " & @error)
      EndIf
      _IEAction($oIE, "stop")                                                             ; Cancels any pending navigation or download operation and stops any dynamic page elements, such as background sounds and animations.
      ;$oForm = _IEFormGetObjByName($oIE, "form")                                         ; Form name - non exist!
      _IEFormElementSetValue(_IEGetObjByName($oIE, "coordinates"), $CmdLine[2] & " " & _
                                                                   $CmdLine[3] & " " & _
                                                                   $CmdLine[4] & "." & _
                                                                   $CmdLine[5] & " " & _
                                                                   $CmdLine[6] & " " & _
                                                                   $CmdLine[7] & " " & _
                                                                   $CmdLine[8] & "." & _
                                                                   $CmdLine[9])           ; Lat_G
      Sleep(1000)                                                                         ; Wait a while
      ; Because submit button has no NAME we must do it this stupid way
      $oButtons = _IETagNameGetCollection($oIE, "input")                                  ; Search all inputs
      For $oButton In $oButtons
        If String($oButton.type) = "submit" Then                                          ; If input has type=submit
         _IEAction($oButton, "click")                                                     ; Click on it
        EndIf
      Next
      Sleep(500)
      _IEAction($oIE, "stop")
      $oIE.document.parentwindow.scroll(0, 100)                                           ; Scroll a little bit down :)

    ; ==========================================================================> FINAR
    ; url: http://gc.elanot.cz/index.php/data-final.html
    ; captcha: no
    Case "finar"
      _IENavigate($oIE, $CmdLine[10])                                                                    ; Open url
      If @error Then                                                                                     ; IE Errors: 1-General, 2-COM, 3-InvalidData, 4-InvalidObject, 6-Loadwait, 8-AccessDenied, 9-ClientDisconnect
          MsgBox(48, "Error", "There was a problem opening webpage!" & @CRLF & "Error: " & @error)
      EndIf
      _IEAction($oIE, "stop")                                                                            ; Cancels any pending navigation or download operation and stops any dynamic page elements, such as background sounds and animations.
      $oForm = _IEFormGetObjByName($oIE, "fabrikList")                                                   ; Form name
      _IEAction(_IEFormElementGetObjByName($oForm, "fabrik_list_filter_all_1_com_fabrik_1"), "focus")    ; Set focus
      _IEFormElementSetValue(_IEGetObjByName($oIE, "fabrik_list_filter_all_1_com_fabrik_1"), $CmdLine[2] & " " & _
                                                                                             $CmdLine[3] & "° " & _
                                                                                             $CmdLine[4] & "." & _
                                                                                             $CmdLine[5] & " " & _
                                                                                             $CmdLine[6] & " " & _
                                                                                             $CmdLine[7] & "° " & _
                                                                                             $CmdLine[8] & "." & _
                                                                                             $CmdLine[9]) ; coordinates in gc.com format
      Sleep(1000)                                                                                         ; Wait a while
      _IEAction(_IEFormElementGetObjByName($oForm, "filter"), "click")                                    ; Click on it!

    ; ==========================================================================> SERVICE ERROR
    Case Else                                                                   ; Show some error in case wrong service called
      MsgBox(48, "Error", "Error: Invalid service selected!" & @CRLF & "Use only: geocheck, geochecker, evince, hermansky, komurka, gccounter, certitudes!")
      Exit
  EndSwitch
EndFunc

; Endscript function
Func Terminate()
  Exit
EndFunc ; ==> Terminate

; Refrest content with webpage
Func Refresh()
  Content()
EndFunc ; ==> Refresh

; Destroy and make new donate button at new position
Func Donate($iTop, $iLeft)
  GUICtrlDelete($oDonate)                                                     ; Destroy old label - I know it's not pretty nice, but works well
  $oDonate = GUICtrlCreateLabel("Pøispìjte na vývoj Checkeru", $iTop, $iLeft) ; Create label
  GUICtrlSetCursor($oDonate, 0)                                               ; Change mouse cursor to hand on hover
  GUICtrlSetColor($oDonate, 0x0000FF)                                         ; Set text color to blue
  GUICtrlSetTip($oDonate, "Pokud mì chcete podpoøit pøes PayPal, staèí kliknout." & @CRLF & _
                          "Pokud se s PayPalem nekamarádíte, napište mi na mikrom@mikrom.cz a urèitì se dohodneme.", _
                          "Podpora vývoje", 1, 1)                             ; ToolTip
EndFunc ; ==> Donate
