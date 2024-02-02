; checker
; Www: http://geoget.ararat.cz/doku.php/user:skript:checker
; Forum: http://www.geocaching.cz/forum/viewthread.php?forum_id=20&thread_id=25822
; Author: mikrom, http://mikrom.cz
; Version: 0.0.1.5
;
; parameters  service     ns          dx          mx          sx          ew          dy          my          sy          url
; eg.         checker     N           50          15          123         E           015         54          123         http://checker.org/check?=a56sjg4678gdg
; $CmdLine[0] $CmdLine[1] $CmdLine[2] $CmdLine[3] $CmdLine[4] $CmdLine[5] $CmdLine[6] $CmdLine[7] $CmdLine[8] $CmdLine[9] $CmdLine[10]
;
;Opt("SendKeyDelay", 50)
;Opt("WinTitleMatchMode", 2)

If $CmdLine[0] <> 10 Then
  MsgBox(0, "Error", "Error: Invalid number of parameters!" & @CRLF & "Parameters are:" & @CRLF & "[service] [N|S] [Dx] [Mx] [Sx] [E|W] [Dy] [My] [Sy] [URL]")
  Exit
EndIf

;MsgBox(1,"",$CmdLine[10])

Switch $CmdLine[1]
  Case "geocheck"
    ShellExecute($CmdLine[10])
    If WinWaitActive("[REGEXPTITLE:Geo(Chec|Tje)k]", "", 30) Then
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
    ShellExecute($CmdLine[10])
    If WinWaitActive("GeoChecker ", "", 30) Then
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
      Sleep(2000)
      Send("{ENTER}")
    Else
      MsgBox(0, "Error", "Error: Timeout!")
    EndIf
    Exit
  Case "evince"
    ShellExecute($CmdLine[10])
    If WinWaitActive("evince - ", "", 30) Then
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
  Case "hermansky"
    ShellExecute($CmdLine[10])
    If WinWaitActive("GPS Pøevodník / Kontrolor", "", 30) Then
      Sleep(1000)
      Send("{TAB 7}")
      Send($CmdLine[2])
      Send("{TAB}")
      Send($CmdLine[3])
      Send("{TAB}")
      Send($CmdLine[4])
      Send(".")
      Send($CmdLine[5])
      Send("{TAB}")
      Send($CmdLine[6])
      Send("{TAB}")
      Send($CmdLine[7])
      Send("{TAB}")
      Send($CmdLine[8])
      Send(".")
      Send($CmdLine[9])
      Sleep(2000)
      Send("{ENTER}")
    Else
      MsgBox(0, "Error", "Error: Timeout!")
    EndIf
    Exit
  Case "komurka"
    ShellExecute($CmdLine[10])
    If WinWaitActive(".:: http://geo.komurka.cz ::.", "", 30) Then
      Sleep(1000)
      Send("{TAB 3}")
      Send($CmdLine[2])
      Send("{TAB}")
      Send($CmdLine[3])
      Send("{TAB}")
      Send($CmdLine[4])
      Send("{TAB}")
      Send($CmdLine[5])
      Send("{TAB}")
      Send($CmdLine[6])
      Send("{TAB}")
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
  Case "gccounter"
    ShellExecute($CmdLine[10])
    If WinWaitActive("GCCounter", "", 30) Then
      Sleep(1000)
      Send("{TAB 3}")
      Send($CmdLine[2])
      Send("{TAB}")
      Send($CmdLine[3])
      Send("{TAB}")
      Send($CmdLine[4])
      Send("{TAB}")
      Send($CmdLine[5])
      Send("{TAB}")
      Send($CmdLine[6])
      Send("{TAB}")
      Send($CmdLine[7])
      Send("{TAB}")
      Send($CmdLine[8])
      Send("{TAB}")
      Send($CmdLine[9])
      Send("{TAB}")
      Sleep(2000)
      Send("{ENTER}")
    Else
      MsgBox(0, "Error", "Error: Timeout!")
    EndIf
    Exit
  Case "certitudes"
    ShellExecute($CmdLine[10])
    If WinWaitActive("Certitude:", "", 30) Then
      Sleep(1000)
      Send("{ENTER}")
    Else
      MsgBox(0, "Error", "Error: Timeout!")
    EndIf
    Exit
  Case Else
    MsgBox(0, "Error", "Error: Invalid service selected!" & @CRLF & "Use only: geocheck, geochecker, evince")
    Exit
EndSwitch
