; Trap COM errors so that 'Back' and 'Forward'
; outside of history bounds does not abort script
; (expect COM errors to be sent to the console)
;
; checker
; Www: http://geoget.ararat.cz/doku.php/user:skript:checker
; Forum: http://www.geocaching.cz/forum/viewthread.php?forum_id=20&thread_id=25822
; Author: mikrom, http://mikrom.cz
; Version: 0.1.0.0
;
; parameters  service     ns          dx          mx          sx          ew          dy          my          sy          url
; eg.         checker     N           50          15          123         E           015         54          123         http://checker.org/check?=a56sjg4678gdg
; $CmdLine[0] $CmdLine[1] $CmdLine[2] $CmdLine[3] $CmdLine[4] $CmdLine[5] $CmdLine[6] $CmdLine[7] $CmdLine[8] $CmdLine[9] $CmdLine[10]
;

#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <IE.au3>

If $CmdLine[0] <> 10 Then
  MsgBox(0, "Error", "Error: Invalid number of parameters!" & @CRLF & "Parameters are:" & @CRLF & "[service] [N|S] [Dx] [Mx] [Sx] [E|W] [Dy] [My] [Sy] [URL]")
  Exit
EndIf

Browser() ;Browser("http://geocheck.org/geo_inputchkcoord.php?gid=61241961c72ab1d-b813-47da-bf03-07c67bb81ac9")

Func Browser() ;Func Browser($churl)
  Local $oIE = _IECreateEmbedded()
  GUICreate("Checker Browser", 1000, 600, (@DesktopWidth - 1000) / 2, (@DesktopHeight - 600) / 2, $WS_OVERLAPPEDWINDOW + $WS_CLIPSIBLINGS + $WS_CLIPCHILDREN)
  GUICtrlCreateObj($oIE, 0, 0, 1000, 600)
  Global $GUI_Error_Message = GUICtrlCreateLabel("", 100, 500, 500, 30)
  GUICtrlSetColor(-1, 0xff0000)
  GUISetState(@SW_SHOW) ;Show GUI

Switch $CmdLine[1]
  Case "geocheck" ; ==============================================================================================
    _IENavigate($oIE, $CmdLine[10]) ; url
    $oForm = _IEFormGetObjByName($oIE, "geoform") ; form name
    _IEFormElementRadioSelect($oForm, $CmdLine[2], "lat") ; Lat radio select
    _IEFormElementSetValue(_IEFormElementGetObjByName($oForm, "latdeg"), $CmdLine[3]) ; LatDeg
    _IEFormElementSetValue(_IEFormElementGetObjByName($oForm, "latmin"), $CmdLine[4]) ; LatMin
    _IEFormElementSetValue(_IEFormElementGetObjByName($oForm, "latdec"), $CmdLine[5]) ; LatDec
    _IEFormElementRadioSelect($oForm, $CmdLine[6], "lon") ; Lon radio select
    _IEFormElementSetValue(_IEFormElementGetObjByName($oForm, "londeg"), $CmdLine[7]) ; LonDec
    _IEFormElementSetValue(_IEFormElementGetObjByName($oForm, "lonmin"), $CmdLine[8]) ; LonMin
    _IEFormElementSetValue(_IEFormElementGetObjByName($oForm, "londec"), $CmdLine[9]) ; LonDec
    _IEAction(_IEFormElementGetObjByName($oForm, "usercaptcha"), "focus") ; Captcha field - set focus
    _IEAction($oIE, "stop")
  Case "geochecker" ; ============================================================================================
    _IENavigate($oIE, $CmdLine[10]) ; url
    $oForm = _IEFormGetObjByName($oIE, "form") ; form name
    _IEFormElementSetValue(_IEFormElementGetObjByName($oForm, "LatString"), $CmdLine[2] & " " & $CmdLine[3] & " " & $CmdLine[4] & "." & $CmdLine[5]) ; LatString
    _IEFormElementSetValue(_IEFormElementGetObjByName($oForm, "LonString"), $CmdLine[6] & " " & $CmdLine[7] & " " & $CmdLine[8] & "." & $CmdLine[9]) ; LonString
    _IEAction($oIE, "stop")
    Sleep(1000)
    _IEAction(_IEFormElementGetObjByName($oForm, "button"), "click") ; Submit
  Case "evince" ; ================================================================================================
    _IENavigate($oIE, $CmdLine[10]) ; url
    $oForm = _IEFormGetObjByName($oIE, "ev_form01") ; form name
    _IEFormElementSetValue(_IEFormElementGetObjByName($oForm, "NorthSouth"), $CmdLine[2]) ; NorthSouth
    _IEFormElementSetValue(_IEFormElementGetObjByName($oForm, "LatDeg"), $CmdLine[3]) ; LatDeg
    _IEFormElementSetValue(_IEFormElementGetObjByName($oForm, "LatMin"), $CmdLine[4] & "." & $CmdLine[5]) ; LatMin
    _IEFormElementSetValue(_IEFormElementGetObjByName($oForm, "EastWest"), $CmdLine[6]) ; EastWest
    _IEFormElementSetValue(_IEFormElementGetObjByName($oForm, "LonDeg"), $CmdLine[7]) ; LonDeg
    _IEFormElementSetValue(_IEFormElementGetObjByName($oForm, "LonMin"), $CmdLine[8] & "." & $CmdLine[9]) ; LonMin
    _IEAction(_IEFormElementGetObjByName($oForm, "recaptcha_response_field"), "focus") ; Captcha field - set focus
  Case "hermansky" ; =============================================================================================
    _IENavigate($oIE, $CmdLine[10]) ; url
    ;$oForm = _IEFormGetObjByName($oIE, "form1") ; form name - non exist
    _IEFormElementSetValue(_IEGetObjByName($oIE, "vyska"), $CmdLine[2]) ; vyska
    _IEFormElementSetValue(_IEGetObjByName($oIE, "stupne21"), $CmdLine[3]) ; stupne21
    _IEFormElementSetValue(_IEGetObjByName($oIE, "minuty21"), $CmdLine[4] & "." & $CmdLine[5]) ; minuty21
    _IEFormElementSetValue(_IEGetObjByName($oIE, "sirka"), $CmdLine[6]) ; sirka
    _IEFormElementSetValue(_IEGetObjByName($oIE, "stupne22"), $CmdLine[7]) ; stupne22
    _IEFormElementSetValue(_IEGetObjByName($oIE, "minuty22"), $CmdLine[8] & "." & $CmdLine[9]) ; minuty22
    Sleep(1000)
    ; tady proste jeste nevim no..
    $oButtons = _IETagNameAllGetCollection($oIE, "input")
    For $oButton in $oButtons
      If String($oButton.value) = " Zkontrolovat " Then $test = $oButtons
      _IEAction($test, "click")
    Next
  Case "komurka" ; ===============================================================================================
    _IENavigate($oIE, $CmdLine[10]) ; url
    $oForm = _IEFormGetObjByName($oIE, "form1") ; form name
    _IEFormElementOptionSelect(_IEGetObjByName($oForm, "select1"), $CmdLine[2]) ; select1
    _IEFormElementSetValue(_IEGetObjByName($oForm, "sirka1"), $CmdLine[3]) ; sirka1
    If StringLen($CmdLine[4]) <> 2 Then ; musi byt dvouciferne
      _IEFormElementSetValue(_IEGetObjByName($oForm, "sirka2"), "0" & $CmdLine[4]) ; sirka2
    Else
      _IEFormElementSetValue(_IEGetObjByName($oForm, "sirka2"), $CmdLine[4]) ; sirka2
    EndIf
    _IEFormElementSetValue(_IEGetObjByName($oForm, "sirka2"), $CmdLine[4]) ; sirka2
    _IEFormElementSetValue(_IEGetObjByName($oForm, "sirka3"), $CmdLine[5]) ; sirka3
    _IEFormElementOptionSelect(_IEGetObjByName($oForm, "select2"), $CmdLine[6]) ; select2
    _IEFormElementSetValue(_IEGetObjByName($oForm, "delka1"), $CmdLine[7]) ; delka1
    If StringLen($CmdLine[4]) <> 2 Then ; musi byt dvouciferne
      _IEFormElementSetValue(_IEGetObjByName($oForm, "sirka2"), "0" & $CmdLine[4]) ; sirka2
    Else
      _IEFormElementSetValue(_IEGetObjByName($oForm, "sirka2"), $CmdLine[4]) ; sirka2
    EndIf
    _IEFormElementSetValue(_IEGetObjByName($oForm, "delka2"), $CmdLine[8]) ; delka2
    _IEFormElementSetValue(_IEGetObjByName($oForm, "delka3"), $CmdLine[9]) ; delka3
    _IEAction(_IEFormElementGetObjByName($oForm, "code"), "focus") ; Captcha field - set focus
  Case "gccounter" ; =============================================================================================
    _IENavigate($oIE, $CmdLine[10]) ; url
    ;$oForm = _IEFormGetObjByName($oIE, "form1") ; form name - non exist
    _IEFormElementOptionSelect(_IEGetObjByName($oIE, "Lat_R"), $CmdLine[2]) ; Lat_R
    _IEFormElementSetValue(_IEGetObjByName($oIE, "Lat_G"), $CmdLine[3]) ; Lat_G
    _IEFormElementSetValue(_IEGetObjByName($oIE, "Lat_M"), $CmdLine[4]) ; Lat_M
    _IEFormElementSetValue(_IEGetObjByName($oIE, "Lat_MM"), $CmdLine[5]) ; Lat_MM
    _IEFormElementOptionSelect(_IEGetObjByName($oIE, "Lon_R"), $CmdLine[6]) ; Lon_R
    _IEFormElementSetValue(_IEGetObjByName($oIE, "Lon_G"), $CmdLine[7]) ; Lon_G
    _IEFormElementSetValue(_IEGetObjByName($oIE, "Lon_M"), $CmdLine[8]) ; Lon_M
    _IEFormElementSetValue(_IEGetObjByName($oIE, "Lon_MM"), $CmdLine[9]) ; Lon_MM
    ; submit zase bez name - <input type="submit" value="Absenden">
  Case "certitudes" ; ============================================================================================
    _IENavigate($oIE, $CmdLine[10]) ; url
    ;$oForm = _IEFormGetObjByName($oIE, "form") ; form name
    _IEFormElementSetValue(_IEGetObjByName($oIE, "coordinates"), $CmdLine[2] & " " & $CmdLine[3] & " " & $CmdLine[4] & "." & $CmdLine[5] & " " & $CmdLine[6] & " " & $CmdLine[7] & " " & $CmdLine[8] & "." & $CmdLine[9]) ; Lat_G
    ; submit bez name - <input type="submit" value="Ov&#283;&#345; m&eacute; &#345;e&scaron;en&iacute;" onclick="this.disabled=true;this.form.submit();">
  Case Else
    MsgBox(0, "Error", "Error: Invalid service selected!" & @CRLF & "Use only: geocheck, geochecker, evince")
    Exit
EndSwitch

  ; Waiting for user to close the window
  While 1
    Local $msg = GUIGetMsg()
    If $msg = $GUI_EVENT_CLOSE Then
      ExitLoop
    EndIf
  WEnd

  GUIDelete()
  Exit
EndFunc ;==>Browser

Func CheckError($sMsg, $error, $extended)
  If $error Then
    $sMsg = "Error using " & $sMsg & " button (" & $extended & ")"
  Else
    $sMsg = ""
  EndIf
  GUICtrlSetData($GUI_Error_Message, $sMsg)
EndFunc ;==>CheckError
