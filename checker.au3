
; parameters  service     ns          dx          mx          sx          ew          dy          my          sy          url
; $CmdLine[0] $CmdLine[1] $CmdLine[2] $CmdLine[3] $CmdLine[4] $CmdLine[5] $CmdLine[6] $CmdLine[7] $CmdLine[8] $CmdLine[9] $CmdLine[10]

; ControlSend ( "title", "text", controlID, "string" [, flag] )
; WinWait ( "title" [, "text" [, timeout]] )

;Opt("SendKeyDelay", 50)
;Opt("WinTitleMatchMode", 2)

If $CmdLine[0] <> 10 Then
  MsgBox(0, "Error", "Error: Invalid number of parameters!" & @CRLF & "Parameters are:" & @CRLF & "service NS Dx Mx Sx EW Dy My Sy URL")
  Exit
EndIf

;MsgBox(1,"",$CmdLine[10])

Switch $CmdLine[1]
  Case "geocheck"
    $title = "GeoCheck - Check your coordinates"
    ShellExecute($CmdLine[10])
    If WinWaitActive($title, "", 15) Then
      Sleep(1000)
      Send("{TAB 37}")
      If($CmdLine[2] = "N") Then
        Send("{TAB}")
      ElseIf($CmdLine[2] = "S") Then
        Send("{RIGHT}")
        Send("{TAB}")
      EndIf
      Send($CmdLine[3])
      Send("{TAB}")
      Send($CmdLine[4])
      Send("{TAB}")
      Send($CmdLine[5])
      Send("{TAB}")
      If($CmdLine[6] = "E") Then
        Send("{TAB}")
      ElseIf($CmdLine[6] = "W") Then
        Send("{LEFT}")
        Send("{TAB}")
      EndIf
      Send($CmdLine[7])
      Send("{TAB}")
      Send($CmdLine[8])
      Send("{TAB}")
      Send($CmdLine[9])
      Send("{TAB 2}")
    Else
      MsgBox(0, "Error", "Error: Timeout!")
    EndIf
    Exit
  Case "geochecker"
    $title = "GeoChecker link for "
    ShellExecute($CmdLine[10])
    If WinWaitActive($title, "", 15) Then
      Sleep(1000)
      Send("{TAB 17}")
      Send($CmdLine[2])
      Send("{SPACE}")
      Send($CmdLine[3])
      Send("{SPACE}")
      Send($CmdLine[4])
      Send(".")
      Send($CmdLine[5])
      Send("{TAB}")
      Send($CmdLine[6])
      Send("{SPACE}")
      Send($CmdLine[7])
      Send("{SPACE}")
      Send($CmdLine[8])
      Send(".")
      Send($CmdLine[9])
      Send("{TAB 2}")
      Sleep(3000)
      Send("{ENTER}")
    Else
      MsgBox(0, "Error", "Error: Timeout!")
    EndIf
    Exit
  Case "evince"
    $title = "evince - coordinate verification"
    ShellExecute($CmdLine[10])
    If WinWaitActive($title, "", 5) Then
      Sleep(1000)
      Send("+{TAB}")
      Send($CmdLine[2])
      Send("{TAB}")
      Send($CmdLine[3])
      Send("{TAB}")
      Send($CmdLine[4])
      Send(".")
      Send($CmdLine[5])
      Send("{TAB 2}")
      Send($CmdLine[6])
      Send("{TAB}")
      Send($CmdLine[7])
      Send("{TAB}")
      Send($CmdLine[8])
      Send(".")
      Send($CmdLine[9])
      Send("{TAB 4}")
    Else
      MsgBox(0, "Error", "Error: Timeout!")
    EndIf
    Exit
  Case Else
    MsgBox(0, "Error", "Error: Invalid service selected!" & @CRLF & "Use only: geocheck, geochecker, evince")
    Exit
EndSwitch
