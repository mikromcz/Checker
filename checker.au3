;;
;; checker
;; Www: http://geoget.ararat.cz/doku.php/user:skript:checker
;; Forum: http://www.geocaching.cz/forum/viewthread.php?forum_id=20&thread_id=25822
;; Author: mikrom, http://mikrom.cz
;; Version: 0.1.0.1
;;
;; parameters  service     ns          dx          mx          sx          ew          dy          my          sy          url
;; eg.         checker     N           50          15          123         E           015         54          123         http://checker.org/check?=a56sjg4678gdg
;; $CmdLine[0] $CmdLine[1] $CmdLine[2] $CmdLine[3] $CmdLine[4] $CmdLine[5] $CmdLine[6] $CmdLine[7] $CmdLine[8] $CmdLine[9] $CmdLine[10]
;;

;; AutoIt3.3.10.0 - 3.3.10.2 has copy&paste not work: http://www.autoitscript.com/forum/topic/158186-embedded-ie-copying-content
;; Trac: http://www.autoitscript.com/trac/autoit/ticket/2639

;; Include important libraries
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <IE.au3>

;; Add one useful hotkeys
HotKeySet("{ESC}", "Terminate")
HotKeySet("{PAUSE}", "TogglePause")

;; Check correct number of parameters
If $CmdLine[0] <> 10 Then
  MsgBox(0, "Error", "Error: Invalid number of parameters!" & @CRLF & "Parameters are:" & @CRLF & "[service] [N|S] [Dx] [Mx] [Sx] [E|W] [Dy] [My] [Sy] [URL]")
  Exit
EndIf

;; Call Main function
Browser()

;; Main function which create window with embeded Internet Explorer core
Func Browser()
  $oIE = _IECreateEmbedded()
  GUICreate("Checker Browser", 1000, 600, (@DesktopWidth - 1000) / 2, (@DesktopHeight - 600) / 2, $WS_OVERLAPPEDWINDOW + $WS_CLIPSIBLINGS + $WS_CLIPCHILDREN)
  GUICtrlCreateObj($oIE, 0, 0, 1000, 600)                                       ;; Creates an ActiveX control in the GUI.
  $GUI_Error_Message = GUICtrlCreateLabel("", 100, 500, 500, 30)
  GUISetState(@SW_SHOW)                                                         ;; Changes the state of a GUI window. Show GUI

  Switch $CmdLine[1]
    ;; ==========================================================================> GEOCHECK
    ;; url: geocheck.org/geo_inputchkcoord.php?gid=61241961c72ab1d-b813-47da-bf03-07c67bb81ac9
    ;; captcha: yes
    Case "geocheck"
      _IENavigate($oIE, $CmdLine[10])                                                   ;; Open url
      $oForm = _IEFormGetObjByName($oIE, "geoform")                                     ;; Form name
      _IEFormElementRadioSelect($oForm, $CmdLine[2], "lat")                             ;; Lat radio select
      _IEFormElementSetValue(_IEFormElementGetObjByName($oForm, "latdeg"), $CmdLine[3]) ;; LatDeg
      _IEFormElementSetValue(_IEFormElementGetObjByName($oForm, "latmin"), $CmdLine[4]) ;; LatMin
      _IEFormElementSetValue(_IEFormElementGetObjByName($oForm, "latdec"), $CmdLine[5]) ;; LatDec
      _IEFormElementRadioSelect($oForm, $CmdLine[6], "lon")                             ;; Lon radio select
      _IEFormElementSetValue(_IEFormElementGetObjByName($oForm, "londeg"), $CmdLine[7]) ;; LonDec
      _IEFormElementSetValue(_IEFormElementGetObjByName($oForm, "lonmin"), $CmdLine[8]) ;; LonMin
      _IEFormElementSetValue(_IEFormElementGetObjByName($oForm, "londec"), $CmdLine[9]) ;; LonDec
      _IEAction(_IEFormElementGetObjByName($oForm, "usercaptcha"), "focus")             ;; Captcha field - set focus
      _IEAction($oIE, "stop")                                                           ;; Cancels any pending navigation or download operation and stops any dynamic page elements, such as background sounds and animations.
      _IELoadWait($oIE)                                                                 ;; Wait for a browser page load to complete before returning

    ;; ==========================================================================> GEOCHECKER
    ;; url: http://www.geochecker.com/index.php?code=e380cf72d82fa02a81bf71505e8c535c&action=check&wp=4743324457584d&name=536b6c656e696b202d20477265656e20486f757365
    ;; captcha: no
    Case "geochecker"
      _IENavigate($oIE, $CmdLine[10])                                           ;; Open url
      $oForm = _IEFormGetObjByName($oIE, "form")                                ;; Form name
      _IEFormElementSetValue(_IEFormElementGetObjByName($oForm, "LatString"), $CmdLine[2] & " " & $CmdLine[3] & " " & $CmdLine[4] & "." & $CmdLine[5]) ;; LatString
      _IEFormElementSetValue(_IEFormElementGetObjByName($oForm, "LonString"), $CmdLine[6] & " " & $CmdLine[7] & " " & $CmdLine[8] & "." & $CmdLine[9]) ;; LonString
      _IEAction($oIE, "stop")                                                   ;; Cancels any pending navigation or download operation and stops any dynamic page elements, such as background sounds and animations.
      Sleep(1000)                                                               ;; Wait a while
      ;_IEAction(_IEFormElementGetObjByName($oForm, "button"), "click")          ;; Submit
      _IEFormSubmit($oForm)                                                     ;; Submit 2nd version :)
      _IELoadWait($oIE)                                                         ;; Wait for a browser page load to complete before returning
      $oIE.document.parentwindow.scroll(0, 200)                                 ;; Scroll a little bit down :)

    ;; ==========================================================================> EVINCE
    ;; url: http://evince.locusprime.net/cgi-bin/index.cgi?q=d0ZNzQeHKReGKzr
    ;; captcha: yes
    Case "evince"
      _IENavigate($oIE, $CmdLine[10])                                                                       ;; Open url
      $oForm = _IEFormGetObjByName($oIE, "ev_form01")                                                       ;; Form name
      _IEFormElementSetValue(_IEFormElementGetObjByName($oForm, "NorthSouth"), $CmdLine[2])                 ;; NorthSouth
      _IEFormElementSetValue(_IEFormElementGetObjByName($oForm, "LatDeg"), $CmdLine[3])                     ;; LatDeg
      _IEFormElementSetValue(_IEFormElementGetObjByName($oForm, "LatMin"), $CmdLine[4] & "." & $CmdLine[5]) ;; LatMin
      _IEFormElementSetValue(_IEFormElementGetObjByName($oForm, "EastWest"), $CmdLine[6])                   ;; EastWest
      _IEFormElementSetValue(_IEFormElementGetObjByName($oForm, "LonDeg"), $CmdLine[7])                     ;; LonDeg
      _IEFormElementSetValue(_IEFormElementGetObjByName($oForm, "LonMin"), $CmdLine[8] & "." & $CmdLine[9]) ;; LonMin
      _IEAction(_IEFormElementGetObjByName($oForm, "recaptcha_response_field"), "focus")                    ;; Captcha field - set focus
      _IEAction($oIE, "stop")                                                                               ;; Cancels any pending navigation or download operation and stops any dynamic page elements, such as background sounds and animations.
      _IELoadWait($oIE)                                                                                     ;; Wait for a browser page load to complete before returning

    ;; ==========================================================================> HERMANSKY
    ;; url: http://geo.hermansky.net/index.php?co=checker&code=2542e4245f80d4f7783e41ed7503fba6b3c8cc3188ff05
    ;; captcha: no
    Case "hermansky"
      _IENavigate($oIE, $CmdLine[10])                                                            ;; Open url
      ;$oForm = _IEFormGetObjByName($oIE, "form1")                                               ;; Form name - non exist!
      _IEFormElementSetValue(_IEGetObjByName($oIE, "vyska"), $CmdLine[2])                        ;; vyska
      _IEFormElementSetValue(_IEGetObjByName($oIE, "stupne21"), $CmdLine[3])                     ;; stupne21
      _IEFormElementSetValue(_IEGetObjByName($oIE, "minuty21"), $CmdLine[4] & "." & $CmdLine[5]) ;; minuty21
      _IEFormElementSetValue(_IEGetObjByName($oIE, "sirka"), $CmdLine[6])                        ;; sirka
      _IEFormElementSetValue(_IEGetObjByName($oIE, "stupne22"), $CmdLine[7])                     ;; stupne22
      _IEFormElementSetValue(_IEGetObjByName($oIE, "minuty22"), $CmdLine[8] & "." & $CmdLine[9]) ;; minuty22
      _IEAction($oIE, "stop")                                                                    ;; Cancels any pending navigation or download operation and stops any dynamic page elements, such as background sounds and animations.
      Sleep(1000)                                                                                ;; Wait a while
      ;; Because submit button has no NAME we must do it this stupid way
      $oButtons = _IETagNameGetCollection($oIE, "input")                                         ;; Search all inputs
      For $oButton In $oButtons
        If String($oButton.type) = "submit" Then                                                 ;; if input has type=submit
         _IEAction($oButton, "click")                                                            ;; click on it
         _IELoadWait($oIE)                                                                       ;; Wait for a browser page load to complete before returning
        EndIf
      Next
      $oIE.document.parentwindow.scroll(0, 600)                                                  ;; Scroll a little bit down :)

    ;; ==========================================================================> KOMURKA
    ;; url: http://geo.komurka.cz/check.php?cache=GC2JCEQ
    ;; captcha: yes
    Case "komurka"
      _IENavigate($oIE, $CmdLine[10])                                                ;; Open url
      $oForm = _IEFormGetObjByName($oIE, "form1")                                    ;; Form name
      _IEFormElementOptionSelect(_IEGetObjByName($oForm, "select1"), $CmdLine[2])    ;; select1
      _IEFormElementSetValue(_IEGetObjByName($oForm, "sirka1"), $CmdLine[3])         ;; sirka1
      If StringLen($CmdLine[4]) <> 2 Then                                            ;; musi byt dvouciferne
        _IEFormElementSetValue(_IEGetObjByName($oForm, "sirka2"), "0" & $CmdLine[4]) ;; sirka2 (if one digit add leading zero)
      Else
        _IEFormElementSetValue(_IEGetObjByName($oForm, "sirka2"), $CmdLine[4])       ;; sirka2 (if two digit let it be)
      EndIf
      _IEFormElementSetValue(_IEGetObjByName($oForm, "sirka3"), $CmdLine[5])         ;; sirka3
      _IEFormElementOptionSelect(_IEGetObjByName($oForm, "select2"), $CmdLine[6])    ;; select2
      _IEFormElementSetValue(_IEGetObjByName($oForm, "delka1"), $CmdLine[7])         ;; delka1
      If StringLen($CmdLine[4]) <> 2 Then                                            ;; musi byt dvouciferne
        _IEFormElementSetValue(_IEGetObjByName($oForm, "delka2"), "0" & $CmdLine[4]) ;; delka2 (if one digit add leading zero)
      Else
        _IEFormElementSetValue(_IEGetObjByName($oForm, "delka2"), $CmdLine[4])       ;; delka2 (if two digit let it be)
      EndIf
      _IEFormElementSetValue(_IEGetObjByName($oForm, "delka3"), $CmdLine[9])         ;; delka3
      _IEAction(_IEFormElementGetObjByName($oForm, "code"), "focus")                 ;; Captcha field - set focus
      _IEAction($oIE, "stop")                                                        ;; Cancels any pending navigation or download operation and stops any dynamic page elements, such as background sounds and animations.
      _IELoadWait($oIE)                                                              ;; Wait for a browser page load to complete before returning

    ;; ==========================================================================> GCCOUNTER
    ;; url: http://gccounter.com/gcchecker.php?site=gcchecker_check&id=2076
    ;; captcha: no
    Case "gccounter"
      _IENavigate($oIE, $CmdLine[10])                                           ;; Open url
      ;$oForm = _IEFormGetObjByName($oIE, "form1")                              ;; Form name - non exist!
      _IEFormElementOptionSelect(_IEGetObjByName($oIE, "Lat_R"), $CmdLine[2])   ;; Lat_R
      _IEFormElementSetValue(_IEGetObjByName($oIE, "Lat_G"), $CmdLine[3])       ;; Lat_G
      _IEFormElementSetValue(_IEGetObjByName($oIE, "Lat_M"), $CmdLine[4])       ;; Lat_M
      _IEFormElementSetValue(_IEGetObjByName($oIE, "Lat_MM"), $CmdLine[5])      ;; Lat_MM
      _IEFormElementOptionSelect(_IEGetObjByName($oIE, "Lon_R"), $CmdLine[6])   ;; Lon_R
      _IEFormElementSetValue(_IEGetObjByName($oIE, "Lon_G"), $CmdLine[7])       ;; Lon_G
      _IEFormElementSetValue(_IEGetObjByName($oIE, "Lon_M"), $CmdLine[8])       ;; Lon_M
      _IEFormElementSetValue(_IEGetObjByName($oIE, "Lon_MM"), $CmdLine[9])      ;; Lon_MM
      _IEAction($oIE, "stop")                                                   ;; Cancels any pending navigation or download operation and stops any dynamic page elements, such as background sounds and animations.
      Sleep(1000)                                                               ;; Wait a while
      ;; Because submit button has no NAME we must do it this stupid way
      $oButtons = _IETagNameGetCollection($oIE, "input")                        ;; Search all inputs
      For $oButton In $oButtons
        If String($oButton.type) = "submit" Then                                ;; If input has type=submit
         _IEAction($oButton, "click")                                           ;; Click on it
         _IELoadWait($oIE)                                                      ;; Wait for a browser page load to complete before returning
        EndIf
      Next

    ;; ==========================================================================> CERTITUDES
    ;; url: http://www.certitudes.org/certitude?wp=GC2QFYT
    ;; captcha: no
    Case "certitudes" 
      _IENavigate($oIE, $CmdLine[10])                                           ;; Open url
      ;$oForm = _IEFormGetObjByName($oIE, "form")                               ;; Form name - non exist!
      _IEFormElementSetValue(_IEGetObjByName($oIE, "coordinates"), $CmdLine[2] & " " & $CmdLine[3] & " " & $CmdLine[4] & "." & $CmdLine[5] & " " & $CmdLine[6] & " " & $CmdLine[7] & " " & $CmdLine[8] & "." & $CmdLine[9]) ; Lat_G
      _IEAction($oIE, "stop")                                                   ;; Cancels any pending navigation or download operation and stops any dynamic page elements, such as background sounds and animations.
      Sleep(1000)                                                               ;; Wait a while
      ;; Because submit button has no NAME we must do it this stupid way
      $oButtons = _IETagNameGetCollection($oIE, "input")                        ;; Search all inputs
      For $oButton In $oButtons
        If String($oButton.type) = "submit" Then                                ;; If input has type=submit
         _IEAction($oButton, "click")                                           ;; Click on it
         _IELoadWait($oIE)                                                      ;; Wait for a browser page load to complete before returning
        EndIf
      Next
      $oIE.document.parentwindow.scroll(0, 100)                                 ;; Scroll a little bit down :)

    Case Else                                                                   ;; Show some error in case wrong service called
      MsgBox(0, "Error", "Error: Invalid service selected!" & @CRLF & "Use only: geocheck, geochecker, evince, hermansky, komurka, gccounter, certitudes!")
      Exit
  EndSwitch

  ;; Waiting for user to close the window
  While 1
    Local $msg = GUIGetMsg()
    If $msg = $GUI_EVENT_CLOSE Then
       ExitLoop
    EndIf
  WEnd

  GUIDelete()
  Exit
EndFunc ;; ==> Browser

Func CheckError($sMsg, $error, $extended)
  If $error Then
    $sMsg = "Error using " & $sMsg & " button (" & $extended & ")"
  Else
    $sMsg = ""
  EndIf
  GUICtrlSetData($GUI_Error_Message, $sMsg)
EndFunc ;; ==> CheckError

Func Terminate()
  Exit
EndFunc ;; ==> Terminate

Func TogglePause()
  $fPaused = Not $fPaused
  While $fPaused
    Sleep(100)
      ToolTip('Script is "Paused"', 0, 0)
  WEnd
  ToolTip("")
EndFunc ;; ==> TogglePause
