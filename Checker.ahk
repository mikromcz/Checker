; Checker AHK
; Www: http://geoget.ararat.cz/doku.php/user:skript:checker
; Forum: http://www.geocaching.cz/forum/viewthread.php?forum_id=20&thread_id=25822
; Author: mikrom, http://mikrom.cz
; Version: 2.12.0
;
; Documentation: http://ahkscript.org/docs/AutoHotkey.htm
; FAQ: http://www.autohotkey.com/docs/FAQ.htm
;
; parameters  service  ns       dx       mx       sx       ew       dy       my       sy       url
; param       args[1]  args[2]  args[3]  args[4]  args[5]  args[6]  args[7]  args[8]  args[9]  args[10]
; eg.         checker  N        50       15       123      E        015      54       123      http://checker.org/check?=a56sjg4678gdg
;
; @phaleth, èech, https://kiwiirc.com/client/irc.freenode.net/#ahk
; https://autohotkey.com/board/topic/64563-basic-ahk-v11-com-tutorial-for-webpages/
; https://msdn.microsoft.com/en-us/library/aa752084%28v=vs.85%29.aspx
; wb.Navigate("http://detectmybrowser.com/")

; Special commands
#Warn                        ; Enable warnings to assist with detecting common errors.
#SingleInstance, Force       ; Determines whether a script is allowed to run again when it is already running.
#NoTrayIcon                  ; Disables the showing of a tray icon.
#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

; Global variables
global args := []    ; Commandline parameters array
global errorLvl := 0 ; For sure set default error level, (0 - without error (default), 1 - success, 2 - wrong)
global debug := 0    ; INI: Debugging mode, change it in the INI!
global proxy := 0    ; INI: Use proxy if you are banned for many tries, change in the INI!
global answer := 0   ; INI: Check if verification was successful or not, change in the INI!
global iefix :=0     ; INI: Try to fix IE render engine to latest by changing registry, change in the INI!
global cnt := 0      ; Only counter that we increment while we are waiting for verification page

; Read setting from INI ^
IniRead, debug, %A_ScriptDir%\Checker.ini, % "Checker", % "debug"   ; For enabling debug mode, show some infos, ListVars, ..
IniRead, proxy, %A_ScriptDir%\Checker.ini, % "Checker", % "proxy"   ; If user is banned for many tries in short time, we try load page with proxyserver
IniRead, iefix, %A_ScriptDir%\Checker.ini, % "Checker", % "iefix"   ; Try to fix IE render engine to latest by changing registry
IniRead, answer, %A_ScriptDir%\Checker.ini, % "Checker", % "answer" ; Define return check result

; Change icon of GUI title, tray, ...
; Icon from: http://www.iconarchive.com/show/colorful-long-shadow-icons-by-graphicloads/Hand-thumbs-up-like-2-icon.html
Menu, Tray, Icon, %A_ScriptDir%\Checker.ico,,1

; Language switch
; https://autohotkey.com/docs/misc/Languages.htm
If (A_Language = "0405") { ; Czech
  global textError           := "Chyba"
  global textErrorFill       := "Chyba: Nelze vyplnit souøadnice!`n`nPravdìpodobnì se naèetla špatná stránka, napøíklad oznámení o pøekroèení limitu."
  global textErrorException  := "Ajaj, tohle se nemìlo stát.`n`nVýjimka: "
  global textErrorParam      := "Chyba: Neplatný poèet parametrù!`n`nPovolené parametry jsou:`n[service] [N|S] [Dx] [Mx] [Sx] [E|W] [Dy] [My] [Sy] [URL]`n`nPoužity byly tyto:`n"
  global textErrorService    := "Chyba: Použita nepodporovaná služba!`nPodporovány jsou: geocheck, geochecker, evince, hermansky, komurka, gccounter, gccounter2, certitudes, gpscache, gccheck, challenge!."
  global textErrorTimeout    := "Chyba: Vypršel èasový limit naèítání stránky.`nZkuste F5 pro obnovení."
  global textDonate          := "Zvažte podporu pluginu pøes <a href=""http://goo.gl/dCKefD"">PayPal</a>, nebo mi napište <a href=""mailto:mikrom@mikrom.cz"">email</a>"
  global textHint            := "Pro ukonèení mùžete použít ESC a pro obnovení stránky F5"
  global textLoading         := "Naèítám..."
  global textAnswerChecking  := "Kontroluji..."
  global textAnswerCorrect   := "Správnì!"
  global textAnswerIncorrect := "Špatnì!"
  global textEvince          := "Upozornìní: Web http://evince.locusprime.net je mrtev. Nelze nic vyplnit/ovìøit."
} Else { ; Other = English
  global textError           := "Error"
  global textErrorFill       := "Error: Can't fill coordinates!`n`nProbably wrong page loaded, like limit exceeded."
  global textErrorException  := "Oops, this should not happen.`n`nException: "
  global textErrorParam      := "Error: Invalid number of parameters!`n`nAllowed parameters are:`n[service] [N|S] [Dx] [Mx] [Sx] [E|W] [Dy] [My] [Sy] [URL]`n`nReceived parameters are:`n"
  global textErrorService    := "Error: Invalid service selected!`nUse only: geocheck, geochecker, evince, hermansky, komurka, gccounter, gccounter2, certitudes, gpscache, gccheck, challenge!."
  global textErrorTimeout    := "Error: Timeout while page load.`nTry press F5 for reload."
  global textDonate          := "You can donate plugin by <a href=""http://goo.gl/dCKefD"">PayPal</a>, or send me an <a href=""mailto:mikrom@mikrom.cz"">email</a>"
  global textHint            := "You can use ESC for quit and F5 for page reload"
  global textLoading         := "Loading..."
  global textAnswerChecking  := "Checking..."
  global textAnswerCorrect   := "Correct!"
  global textAnswerIncorrect := "Incorrect!"
  global textEvince          := "Warning: Site http://evince.locusprime.net is dead. It is not possible to fill/check anything."
}

; Add CMD paremeters to (pseudo) array. It's not necessary, parameters are in variables %1%, %2%, .. but seems not to work in my case.
; http://www.autohotkey.com/docs/Tutorial.htm#s7
; http://ahkscript.org/docs/misc/Arrays.htm#pseudo
paramList := ""
Loop, %0% {
  args[A_Index] := %A_Index%
  paramList := paramList . "[" . A_Index . "] " . args[A_Index] . "`n" ; Make list of parameters for next error MsgBox => [n] Param
}

; Parameter count check. There must be exactly 10 parameters!
If (args.MaxIndex() != 10) {
  MsgBox 16, % textError, % textErrorParam . paramList
  ExitApp, errorLvl
}

; Apply registry hack for latest rendering engine
If iefix
  Prev := FixIE()

; Create GUI
; http://www.autohotkey.com/docs/commands/Gui.htm
Gui, +Resize +OwnDialogs +MinSize640x480                           ; Allow change GUI size, MsgBoxes is owned by main window, Set minimal window size
Gui, Add, ActiveX, x0 y0 w1000 h580 vWB, Shell.Explorer            ; The final parameter is the name of the ActiveX component.
Gui, Add, Link, x5 y+0 vHint, % textHint . ". " . textDonate . "." ; Hint and donate text at the bottom
Gui, Add, Text, x940 w60 vLabelAnswer, % " "                       ; Label for showing verification status Success|Error
;ComObjConnect(WB, WB_events)
Gui, Show, Center w1000 h600, % "Checker"                          ; Show the main window (with title Checker)

; Force embedded IE (shell.explorer) to use the latest installed render engine (and not default IE7)
; https://autohotkey.com/board/topic/93660-embedded-ie-shellexplorer-render-issues-fix-force-it-to-use-a-newer-render-engine/
; based on: https://weblog.west-wind.com/posts/2011/May/21/Web-Browser-Control-Specifying-the-IE-Version
; Or maybe somehow add this tag in HTML: <meta http-equiv="X-UA-Compatible" content="IE=Edge">
FixIE(Version=0, ExeName="") {
	static Key := "Software\Microsoft\Internet Explorer\MAIN\FeatureControl\FEATURE_BROWSER_EMULATION"
	, Versions := {7:7000, 8:8888, 9:9999, 10:10001, 11:11001}

	if Versions.HasKey(Version)
		Version := Versions[Version]

	if !ExeName
	{
		if A_IsCompiled
			ExeName := A_ScriptName
		else
			SplitPath, A_AhkPath, ExeName
	}

	RegRead, PreviousValue, HKCU, %Key%, %ExeName%
	if (Version = "")
		RegDelete, HKCU, %Key%, %ExeName%
	else
		RegWrite, REG_DWORD, HKCU, %Key%, %ExeName%, %Version%
	return PreviousValue
}

; Encode special characters to URI (for ex. "space" is %20)
; https://autohotkey.com/board/topic/75390-ahk-l-unicode-uri-encode-url-encode-function/
UriEncode(Uri) {
    oSC := ComObjCreate("ScriptControl")
    oSC.Language := "JScript"
    Script := "var Encoded = encodeURIComponent(""" . Uri . """)"
    oSC.ExecuteStatement(Script)
    Return, oSC.Eval("Encoded")
}

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
; http://p.ahkscript.org/?p=21044572
LoadWait(ByRef wb) {
  If !wb                                      ; If wb is not a valid pointer then quit
    Return False

  cnt := 0                                    ; Reset variable to zero
  Loop {                                      ; Otherwise sleep for .1 seconds untill the page starts loading
    Sleep, 100

    cnt++                                     ; Incremet counter
    If (mod(cnt, 2) = 0)                      ; Modulo divide to determine if counter is Even or Odd
      GuiControl,, labelanswer, % textLoading ; Flashing sign "Loading..."
    Else
      GuiControl,, labelanswer, % cnt . "_1"

    If cnt >= 50                              ; Timeout .1 x 10 = 1000ms, so 5 seconds?
      Return ;wb.Stop                         ; Cancels a pending navigation or download, and stops dynamic page elements, such as background sounds and animations.
  } Until (wb.Busy)

  cnt := 0                                    ; Reset variable to zero
  Loop {                                      ; Once it starts loading wait until completes
    Sleep, 100

    cnt++                                     ; Incremet counter
    If (mod(cnt, 2) = 0)                      ; Modulo divide to determine if counter is Even or Odd
      GuiControl,, labelanswer, % textLoading ; Flashing sign "Loading..."
    Else
      GuiControl,, labelanswer, % cnt . "_2"

    If cnt >= 50                              ; Timeout .1 x 10 = 1000ms, so 5 seconds?
      Return ;wb.Stop                         ; Cancels a pending navigation or download, and stops dynamic page elements, such as background sounds and animations.
  } Until (!wb.Busy)

  ;Loop                                       ; Optional check to wait for the page to completely load - NOT WORK FOR ME, hangs at some pages
  ;  Sleep, 100
  ;Until (wb.Document.Readystate = "Complete")

  Return True

  Sleep, 500                                  ; Just for sure
} ; => LoadWait()

; Function for check returned page for the information if verification was successful or not
CheckAnwser(ByRef wb, correct, incorrect) {
  If (debug = 1)
    FileAppend, % "Correct: " . correct . "`nIncorrect: " . incorrect . "`n`n" . wb.Document.body.innerHTML, %A_ScriptDir%/debug.html

  Try {
    cnt := 0                                            ; Reset variable to zero
    Loop {
      Sleep, 200

      cnt++                                             ; Incremet counter
      If (mod(cnt, 2) = 0)                              ; Modulo divide to determine if counter is Even or Odd
        GuiControl,, labelanswer, % textAnswerChecking  ; Flashing sign "Checking..."
      Else
        GuiControl,, labelanswer, % " "

      ; https://autohotkey.com/docs/commands/RegExMatch.htm
      If RegExMatch(wb.Document.body.innerHTML, correct) {
        If (debug = 1)
          MsgBox, % "Correct :)"

        Gui, Font, cGreen Bold                          ; Set color to GREEN
        GuiControl, Font, labelanswer                   ; Apply color to labelanswer
        GuiControl,, labelanswer, % textAnswerCorrect   ; Show the TEXT

        errorLvl := 1                                   ; Change errorlevel for geoget script
      } Else If RegExMatch(wb.Document.body.innerHTML, incorrect) {
        If (debug = 1)
          MsgBox, % "Incorrect :("

        Gui, Font, cRed Bold                            ; Set color to RED
        GuiControl, Font, labelanswer                   ; Apply color to labelanswer
        GuiControl,, labelanswer, % textAnswerIncorrect ; Show the TEXT

        errorLvl := 2                                   ; Change errorlevel for geoget script
      } ;Else {                                         ; I think we don't even need it
        ;If (debug = 1)
        ;  MsgBox, % "error"

        ;Gui, Font, cBlue Bold                          ; Set color to RED
        ;GuiControl, Font, labelanswer                  ; Apply color to labelanswer
        ;GuiControl,, labelanswer, % textError          ; Show the TEXT

        ;errorLvl := 3
      ;}
    } Until (errorLvl != 0)                             ; Loop again and again until errorlevel is changed
  } Catch e {
    If (debug = 0) 
      MsgBox 16, % textError, % textErrorException . e.extra
    Else
      MsgBox 16, % textError, % textErrorException . "`n`nwhat: " e.what "`nfile: " e.file . "`nline: " e.line "`nmessage: " e.message "`nextra: " e.extra
  }
} ;=> CheckAnwser()

; Main function. Switch, based by first parameter "service"
; http://www.autohotkey.com/board/topic/47052-basic-webpage-controls-with-javascript-com-tutorial/
; http://www.autohotkey.com/board/topic/64563-basic-ahk-l-com-tutorial-for-webpages/
Browser(ByRef wb) {
  If (debug = 0)
    wb.Silent := True ; Turn Off all IE warnings, such as "if JS can run on page etc."

  If (args[1] = "geocheck") { ; ==================================================> GEOCHECK (1)
    ; URL: http://geocheck.org/geo_inputchkcoord.php?gid=61241961c72ab1d-b813-47da-bf03-07c67bb81ac9
    ; Captcha: YES
    Gui, Show,, % "Checker - " . args[1] ; Change title

    wb.Navigate(args[10]) ; Navigate to webpage
    LoadWait(wb)          ; Wait for page load

    ; Try to fill the webpage form
    Try {
      ; Page can be switched to two versions of form, standard or one field
      If (wb.Document.getElementsByName("coordOneField").Length = 0) { ; For classic six field version
        If (debug = 1)
          MsgBox, % "Six field version"

        ; Determine if page has fillable element - right page
        If (wb.Document.getElementsByName("latdeg").Length <> 0) {
          ; Checking radiobuttons is little bit difficult
          Loop, % (lat := wb.Document.getElementsByName("lat")).Length ; Get elements named "lat"
            If (lat[A_index-1].Value = args[2])                        ; If some of them is equal args[2]
              lat[A_index-1].Checked := True                           ; Check it

          wb.Document.All.latdeg.Value := args[3]
          wb.Document.All.latmin.Value := args[4]
          wb.Document.All.latdec.Value := args[5]

          ; Checking radiobuttons is little bit difficult
          Loop, % (lon := wb.Document.getElementsByName("lon")).Length ; Get elements named "lon"
            If (lon[A_index-1].Value = args[6])                        ; If some of them is equal args[6]
              lon[A_index-1].Checked := True                           ; Check it

          wb.Document.All.londeg.Value := args[7]
          wb.Document.All.lonmin.Value := args[8]
          wb.Document.All.londec.Value := args[9]
        }
      } Else If (wb.Document.getElementsByName("coordOneField").Length <> 0) { ; For one field version
        If (debug = 1)
          MsgBox, % "One field version"
        wb.Document.All.coordOneField.Value := args[2] . args[3] . " " . args[4] . "." . args[5] . " " . args[6] . args[7] . " " . args[8] . "." . args[9]
      } Else If (proxy = 1) {
        ; Proxy
        ; If there is no "onefield" and no "latdeg" input there is probably warning about reach max tries
        ; then, we try reload page with proxy server!
        ; <tr><th colspan="2">P&#345;íli? mnoho pokus&#367;</th></tr>

        Sleep, 1000

        Gui, Show,, % "Checker - " . args[1] . " - PROXY" ; Change title
        If (debug = 1)
          wb.Navigate("https://geocaching.mikrom.cz/proxy/index.php?q=" . args[10] . "")        ; Navigate to webpage
        Else
          wb.Navigate("https://geocaching.mikrom.cz/proxy/index.php?q=" . args[10] . "&hl=1e7") ; Navigate to webpage
        LoadWait(wb)                                                                      ; Wait for page load

        ; Checking radiobuttons is little bit difficult
        Loop, % (lat := wb.Document.getElementsByName("lat")).Length ; Get elements named "lat"
          If (lat[A_index-1].Value = args[2])                        ; If some of them is equal args[2]
            lat[A_index-1].Checked := True                           ; Check it

        wb.Document.All.latdeg.Value := args[3]
        wb.Document.All.latmin.Value := args[4]
        wb.Document.All.latdec.Value := args[5]

        ; Checking radiobuttons is little bit difficult
        Loop, % (lon := wb.Document.getElementsByName("lon")).Length ; Get elements named "lon"
          If (lon[A_index-1].Value = args[6])                        ; If some of them is equal args[6]
            lon[A_index-1].Checked := True                           ; Check it

        wb.Document.All.londeg.Value := args[7]
        wb.Document.All.lonmin.Value := args[8]
        wb.Document.All.londec.Value := args[9]
      } ; <= Proxy
      wb.Document.All.usercaptcha.Focus() ; Focus on captcha field
    } Catch e {
      MsgBox 16, % textError, % textErrorFill
      If (debug = 0)
        ExitApp, errorLvl
    }

    ; Check result after page reload
    ; YES CZ:    <th colspan="2">Výborn&#283; - Tvé &#345;e?ení je správné!!!</th> # -
    ; NO CZ:     <td colspan="2" class="alert">Bohu?el, zadaná odpov&#283;&#271; není správná. Zkuste to prosím znovu:</td> # -
    ; YES EN:    <th colspan="2">Congratulations - your solution is correct!!!</th>
    ; NO EN:     <td colspan="2" class="alert">Sorry, that answer is incorrect. Do try again:</td>
    ; YES DE:    <th colspan="2">Herzlichen Glückwunsch! Deine Lösung ist korrekt!!!</th>
    ; NO DE:     <td colspan="2" class="alert">Schade, die Lösung ist falsch. Versuche es erneut:</td>
    ; YES FR:    <th colspan="2">Félicitations, vous avez trouvé la solution!!!</th>
    ; NO FR:     <td colspan="2" class="alert">Désolé, il ne s'agit pas des bonnes coordonnées. Essayez de nouveau:</td>
    ; YES ES:    <th colspan="2">Enhorabuena - tu solución es correcta!!!</th>
    ; NO ES:     <td colspan="2" class="alert">Lo sentimos, la respuesta no es correcta. Prueba otra vez:</td>
    ; YES CA-ES: <th colspan="2">Enhorabona - La teva solució és correcta!!!</th>
    ; NO CA-ES:  <td colspan="2" class="alert">Ho sentim, la resposta és incorrecta. Intenta-ho de nou:</td>
    ; YES IT:    <th colspan="2">Congratulazione - la tua risposta e corretta!!!</th>
    ; NO IT:     <td colspan="2" class="alert">Spiacente, questa risposta non e corretta. Riprova:</td>
    ; YES PT:    <th colspan="2">Parabéns - a a sua soluçao está correcta!!!</th>
    ; NO PT:     <td colspan="2" class="alert">Peço desculpa, essa resposta é incorrecta. Tente novamente:</td>
    ; YES PT-BR: <th colspan="2">A sua soluçao está correta!!!!!!
    ; NO PT-BR:  <td colspan="2" class="alert">Infelizmente a sua soluçao está incorreta. Tente novamente:</td>
    ; YES PL:    <th colspan="2">Gratulacje! Twoje rozwi&#261;zanie jest poprawne!!!</th>
    ; NO PL:     <td colspan="2" class="alert">Niestety Twoja odpowied&#378; jest niepoprawna. Spróbuj ponownie.:</td>
    ; YES NL:    <th colspan="2">Proficiat - Je oplossing is juist!!!</th>
    ; NO NL:     <td colspan="2" class="alert">Sorry, dat antwoord is niet juist. Probeer het nog eens:</td>
    ; YES DA-DK: <th colspan="2">Tillykke - din losning er korrekt!!!</th>
    ; NO DA-DK:  <td colspan="2" class="alert">Beklager, det svar er forkert. Prov venligst igen:</td>
    ; YES NO:    <th colspan="2">Gratulerer ? losningen er korrekt!!!</th>
    ; NO NO:     <td colspan="2" class="alert">Beklager, det svaret er feil. Prov gjerne igjen.:</td>
    ; YES SV-SE: <th colspan="2">Grattis - din lösning är rätt!!!</th>
    ; NO SV-SE:  <td colspan="2" class="alert">Tyvärr, svaret är fel. Försök igen:</td>
    If (answer = 1) {
      okay :=
      (LTrim Join
        "Smi)
        (your solution is correct!!!)|
        (Deine L.+sung ist korrekt!!!)|
        (vous avez trouvé la solution!!!)|
        (tu solución es correcta!!!)|
        (La teva solució és correcta!!!)|
        (la tua risposta e corretta!!!)|
        (a a sua solu.+ao está correcta!!!)|
        (A sua soluçao está correta!!!!!!)|
        (Twoje rozwi.+zanie jest poprawne!!!)|
        (Je oplossing is juist!!!)|
        (din losning er korrekt!!!)|
        (l.+sningen er korrekt!!!)|
        (din l.+sning .+r r.+tt!!!)|
        (Tvé .+e.+ení je správné!!!)"
      )
      notokay :=
      (LTrim Join
        "Smi)
        (Sorry, that answer is incorrect)|
        (Schade, die L.+sung ist falsch)|
        (Désolé, il ne s.+agit pas des bonnes coordonnées)|
        (Lo sentimos, la respuesta no es correcta)|
        (Ho sentim, la resposta és incorrecta)|
        (Spiacente, questa risposta non e corretta)|
        (Pe.+o desculpa, essa resposta é incorrecta)|
        (Infelizmente a sua solu.+ao está incorreta)|
        (Niestety Twoja odpowied.+ jest niepoprawna)|
        (Sorry, dat antwoord is niet juist)|
        (Beklager, det svar er forkert)|
        (Beklager, det svaret er feil)|
        (Tyv.+rr, svaret .+r fel)|
        (Bohu.+el, zadaná odpov.+ není správná)"
      )
      CheckAnwser(wb, okay, notokay)
      ;CheckAnwser(wb, "Smi)správné", "Smi)správná")
    }
  } Else If (args[1] = "geochecker") { ; ==========================================> GEOCHECKER (2)
    ; URL: http://geochecker.com/index.php?code=150e9c12665c476df9d1fcc30eeae605&action=check&wp=4743354e595a33&name=4d79646c6f   ...   &CaptchaChoice=Recaptcha
    ; Captcha: NO
    Gui, Show,, % "Checker - " . args[1] ; Change title

    wb.Navigate(args[10] . "&language=English") ; Navigate to webpage
    LoadWait(wb)          ; Wait for page load

    ; Try to fill the webpage form
    Try {
      wb.Document.All.LatString.Value := args[2] . " " . args[3] . "° " . args[4] . "." . args[5]
      wb.Document.All.LonString.Value := args[6] . " " . args[7] . "° " . args[8] . "." . args[9]
      Sleep, 500
      wb.Document.All.button.Click()
    } Catch e {
      If (debug = 0) {
        MsgBox 16, % textError, % textErrorFill
        ExitApp, errorLvl
      } Else
        MsgBox 16, % textError, % textErrorFill . "`n`nwhat: " e.what "`nfile: " e.file . "`nline: " e.line "`nmessage: " e.message "`nextra: " e.extra
    }

    ; Check result after page reload
    ; YES: <div class="success">Success!</div> # <DIV class=success>Success!</DIV>
    ; NO:  <div class="wrong">Incorrect</div> | (ES: <div class="wrong">Incorrecto</div>) # <DIV class=wrong>Incorrect</DIV>
    If (answer = 1)
      CheckAnwser(wb, "Smi)<div class=.?success.?>", "Smi)<div class=.?wrong.?>")

  } Else If (args[1] = "evince") { ; ==============================================> EVINCE (3)
    ; URL: http://evince.locusprime.net/cgi-bin/index.cgi?q=d0ZNzQeHKReGKzr
    ; Captcha: YES
    ;Gui, Show,, % "Checker - " . args[1] ; Change title

    ;wb.Navigate(args[10]) ; Navigate to webpage
    ;LoadWait(wb)          ; Wait for page load

    ; Try to fill the webpage form
    ;Try {
    ;  wb.Document.All.NorthSouth.Value := args[2]
    ;  wb.Document.All.LatDeg.Value := args[3]
    ;  wb.Document.All.LatMin.Value := args[4] . "." . args[5]
    ;  wb.Document.All.EastWest.Value := args[6]
    ;  wb.Document.All.LonDeg.Value := args[7]
    ;  wb.Document.All.LonMin.Value := args[8] . "." . args[9]
    ;  wb.Document.All.recaptcha_response_field.Focus()
    ;} Catch e {
    ;  MsgBox 16, % textError, % textErrorFill
    ;  If (debug = 0)
    ;    ExitApp, errorLvl
    ;}

    ; Check result after page reload
    ; YES: <span style="font-size: large; font-weight: bold; color: rgb(206, 0, 0);">Congratulations!</span> # <SPAN style="FONT-SIZE: large; FONT-WEIGHT: bold; COLOR: rgb(206,0,0)"><BR>Congratulations! </SPAN>
    ; NO:  <span style="font-size: large; font-weight: bold; color: rgb(206, 0, 0);">Sorry!</span> # <SPAN style="FONT-SIZE: large; FONT-WEIGHT: bold; COLOR: rgb(206,0,0)">Sorry! </SPAN>
    ;If (answer = 1)
    ;  CheckAnwser(wb, "Smi)Congratulations!", "Smi)Sorry!")

    ; Since 2017 website looks dead
    MsgBox, 48, % textError, % textEvince
    ExitApp, errorLvl
    
  } Else If (args[1] = "hermansky") { ; ===========================================> HERMANSKY (4)
    ; URL: http://geo.hermansky.net/index.php?co=checker&code=22377facb3ee0fbbf6e5e2b7dee042ee8687a55cd
    ; Captcha: NO
    Gui, Show,, % "Checker - " . args[1] ; Change title

    wb.Navigate(args[10])                    ; Navigate to webpage
    LoadWait(wb)                             ; Wait for page load

    wb.Document.ParentWindow.ScrollTo(0,370) ; Scroll down because page has a huge picture in header

    ; Try to fill the webpage form
    Try {
      ; Page is somehow in two different versions (DegMin vs. DegMinSec)
      If (wb.Document.getElementsByName("vteriny11").Length = 0) { ; For classic old DegMin version
        If (debug = 1)
          MsgBox, % "Deg Min version"
          
        wb.Document.All.vyska.Value := args[2]
        wb.Document.All.stupne21.Value := args[3]
        wb.Document.All.minuty21.Value := args[4] . "." . args[5]
        wb.Document.All.sirka.Value := args[6]
        wb.Document.All.stupne22.Value := args[7]
        wb.Document.All.minuty22.Value := args[8] . "." . args[9]
      } Else If (wb.Document.getElementsByName("vteriny11").Length <> 0) { ; For new DegMinSec version
        If (debug = 1)
          MsgBox, % "Deg Min Sec version"
          
        wb.Document.All.vyska.Value := args[2]
        wb.Document.All.stupne11.Value := args[3]
        wb.Document.All.minuty11.Value := args[4]
        wb.Document.All.vteriny11.Value := args[5]
        wb.Document.All.sirka.Value := args[6]
        wb.Document.All.stupne12.Value := args[7]
        wb.Document.All.minuty12.Value := args[8]
        wb.Document.All.vteriny12.Value := args[9]
      }
      Sleep, 500
      wb.Document.Forms[0].Submit()
    } Catch e {
      If (debug = 0) {
        MsgBox 16, % textError, % textErrorFill
        ExitApp, errorLvl
      } Else
        MsgBox 16, % textError, % textErrorFill . "`n`nwhat: " e.what "`nfile: " e.file . "`nline: " e.line "`nmessage: " e.message "`nextra: " e.extra
    }

    Sleep, 1000
    wb.Document.ParentWindow.ScrollTo(0,370) ; Scroll again after page reload

    ; Check result after page reload
    ; YES: <div style='background: #77db7a; border: 1px solid black;'><br />Vaše souøadnice jsou spravnì, mùžete vyrazit na lov!<br /> # <DIV style="BORDER-TOP: black 1px solid; BORDER-RIGHT: black 1px solid; BACKGROUND: #77db7a; BORDER-BOTTOM: black 1px solid; BORDER-LEFT: black 1px solid"><BR>Vaše souøadnice jsou spravnì, mùžete vyrazit na lov!<BR>
    ; NO:  <div style="background: #db7777; border: 1px solid black;">Vaše souøadnice jsou špatnì, poèítejte znovu. # <DIV style="BORDER-TOP: black 1px solid; BORDER-RIGHT: black 1px solid; BACKGROUND: #db7777; BORDER-BOTTOM: black 1px solid; BORDER-LEFT: black 1px solid"><BR>Vaše souøadnice jsou špatnì, poèítejte znovu.<BR>
    If (answer = 1)
      CheckAnwser(wb, "Smi)>Vaše souøadnice jsou spravnì, mùžete vyrazit na lov!<", "Smi)>Vaše souøadnice jsou špatnì, poèítejte znovu.<")

  } Else If (args[1] = "komurka") { ; =============================================> KOMURKA (5)
    ; URL: http://geo.komurka.cz/check.php?cache=GC2JCEQ
    ; Captcha: YES
    Gui, Show,, % "Checker - " . args[1] ; Change title

    wb.Navigate(args[10]) ; Navigate to webpage
    LoadWait(wb)          ; Wait for page load

    ; Try to fill the webpage form
    Try {
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
    } Catch e {
      If (debug = 0) {
        MsgBox 16, % textError, % textErrorFill
        ExitApp, errorLvl
      } Else
        MsgBox 16, % textError, % textErrorFill . "`n`nwhat: " e.what "`nfile: " e.file . "`nline: " e.line "`nmessage: " e.message "`nextra: " e.extra
    }

    ; Check result after page reload
    ; YES: <img src="images/smile_green.jpg"> # <IMG src="images/smile_green.jpg">
    ; NO:  <img src="images/smile_red.jpg"> # <IMG src="images/smile_red.jpg">
    If (answer = 1)
      CheckAnwser(wb, "Smi)src=.?images\/smile_green\.jpg.?", "Smi)src=.?images\/smile_red\.jpg.?")

  } Else If (args[1] = "gccounter") { ; ===========================================> GCCOUNTER (5)
    ; URL: http://gccounter.com/gcchecker.php?site=gcchecker_check&id=2076
    ; Captcha: NO
    Gui, Show,, % "Checker - " . args[1] ; Change title

    wb.Navigate(args[10]) ; Navigate to webpage
    LoadWait(wb)          ; Wait for page load

    ; Try to fill the webpage form
    Try {
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
    } Catch e {
      If (debug = 0) {
        MsgBox 16, % textError, % textErrorFill
        ExitApp, errorLvl
      } Else
        MsgBox 16, % textError, % textErrorFill . "`n`nwhat: " e.what "`nfile: " e.file . "`nline: " e.line "`nmessage: " e.message "`nextra: " e.extra
    }

    ; Check result after page reload
    ; YES: <h2 align="center" style="color:green">Herzlichen Glückwunsch!</h2>
    ; NO:  <h2 align="center" style="color:red">Schade!</h2> # <H2 style="COLOR: red" align=center>Schade!</H2>
    If (answer = 1)
      CheckAnwser(wb, "Smi)>Herzlichen Glückwunsch!<", "Smi)>Schade!<")

  } Else If (args[1] = "gccounter2") { ; ===========================================> GCCOUNTER2 (6)
    ; URL: http://gccounter.com/gcchecker.php?site=gcchecker_check&id=2076
    ; Captcha: NO
    Gui, Show,, % "Checker - " . args[1] ; Change title

    wb.Navigate(args[10]) ; Navigate to webpage
    LoadWait(wb)          ; Wait for page load

    ; Try to fill the webpage form
    Try {
      If (args[2] = "N")
        wb.Document.All.latNS.SelectedIndex := 0
      If (args[2] = "S")
        wb.Document.All.latNS.SelectedIndex := 1
      wb.Document.All.latD.Value := args[3]
      wb.Document.All.latM.Value := args[4] . "." . args[5]
      If (args[6] = "E")
        wb.Document.All.lonEW.SelectedIndex := 0
      If (args[6] = "W")
        wb.Document.All.lonEW.SelectedIndex := 1
      wb.Document.All.lonD.Value := args[7]
      wb.Document.All.lonM.Value := args[8] . "." . args[9]
      Sleep, 500

      ; This form is difficult to submit, so we must do it by this unclean way
      Loop, % (inputs := wb.Document.getElementsByTagName("input")).Length ; For all tags <input>
        If (inputs[A_index-1].Type = "submit")                             ; If some of them is type="submit"
          inputs[A_index-1].Click()                                        ; Click on it
    } Catch e {
      If (debug = 0) {
        MsgBox 16, % textError, % textErrorFill
        ExitApp, errorLvl
      } Else
        MsgBox 16, % textError, % textErrorFill . "`n`nwhat: " e.what "`nfile: " e.file . "`nline: " e.line "`nmessage: " e.message "`nextra: " e.extra
    }

    ; Check result after page reload
    ; YES: <h1 style="color: green;">Richtig</h1> # <H1 style="COLOR: green">Richtig</H1>
    ; NO:  <li>Leider stimmt die eingegebene Koordinate nicht.</li> # <LI>Leider stimmt die eingegebene Koordinate nicht. </LI>
    If (answer = 1)
      CheckAnwser(wb, "Smi)<h1 style=.?color: green.?.?>Richtig<\/h1>", "Smi)Leider stimmt die eingegebene Koordinate nicht")

  } Else If (args[1] = "certitudes") { ; ==========================================> CERTITUDES (7)
    ; URL: http://www.certitudes.org/certitude?wp=GC2QFYT
    ; Captcha: NO
    Gui, Show,, % "Checker - " . args[1] ; Change title

    wb.Navigate(args[10]) ; Navigate to webpage
    LoadWait(wb)          ; Wait for page load

    ; Try to fill the webpage form
    Try {
      wb.Document.All.coordinates.Value := args[2] . " " . args[3] . " " . args[4] . "." . args[5] . " " . args[6] . " " . args[7] . " " . args[8] . "." . args[9]
      Sleep, 500

      ; This form is difficult to submit, so we must do it by this unclean way
      Loop, % (inputs := wb.Document.getElementsByTagName("input")).Length ; For all tags <input>
        If (inputs[A_index-1].Type = "submit")                             ; If some of them is type="submit"
          inputs[A_index-1].Click()                                        ; Click on it
    } Catch e {
      If (debug = 0) {
        MsgBox 16, % textError, % textErrorFill
        ExitApp, errorLvl
      } Else
        MsgBox 16, % textError, % textErrorFill . "`n`nwhat: " e.what "`nfile: " e.file . "`nline: " e.line "`nmessage: " e.message "`nextra: " e.extra
    }

    ; Check result after page reload
    ; YES: <img src="/images/woohoo.jpg"> # <IMG src="/images/woohoo.jpg">
    ; NO:  <img src="/images/doh.jpg" align="middle"> # <IMG src="/images/doh.jpg" align=middle>
    If (answer = 1)
      CheckAnwser(wb, "Smi)src=.?\/images\/woohoo\.jpg.?", "Smi)src=.?\/images\/doh\.jpg.?")

  } Else If (args[1] = "gpscache") { ; ============================================> GPS-CACHE (8)
    ; URL: http://geochecker.gps-cache.de/check.aspx?id=7c52d196-b9d2-4b23-ad99-5d6e1bece187
    ; Captcha: YES
    Gui, Show,, % "Checker - " . args[1] ; Change title

    wb.Navigate(args[10]) ; Navigate to webpage
    LoadWait(wb)          ; Wait for page load
    wb.Document.ParentWindow.ScrollTo(0,240) ; Scroll down because page has a huge picture in header

    ; Try to fill the webpage form
    Try {
      wb.Document.All.ListView1_txtKoords_0.Value := args[2] . args[3] . " " . args[4] . "." . args[5] . " " . args[6] . args[7] . " " . args[8] . "." . args[9]
      wb.Document.All.ListView1_txtCaptchaCode_0.Focus()
    } Catch e {
      If (debug = 0) {
        MsgBox 16, % textError, % textErrorFill
        ExitApp, errorLvl
      } Else
        MsgBox 16, % textError, % textErrorFill . "`n`nwhat: " e.what "`nfile: " e.file . "`nline: " e.line "`nmessage: " e.message "`nextra: " e.extra
    }

    ; Check result after page reload
    ; YES: xxx
    ; NO:  <table><td><img alt=":)" src="http://cool-web.de/images/smiley-weird-80.png"></td><td style="font-weight:bold;color:grey;font-size:17pt;padding-left:20px;width:500px;">Sie haben eine besondere Koordinate eingegeben, zu der der Owner eine Nachricht hinterlegt hat!<br><br></td></tr></table><b>Die Mitteilung des Owners lautet:</b><br><br>Gratuliere,  du hast die Header Koordinaten richtig eingegeben! Hier findest du jedoch leider nichts!<br><br><br /><br /></td></tr>
    ;If (answer = 1)
    ;  CheckAnwser(wb, "Smi)xxx", "Smi)<img alt=.?:).? src=.?http:\/\/cool-web\.de\/images\/smiley-weird-80\.png.?>")

  } Else If (args[1] = "gccheck") { ; =============================================> GCCHECK (9)
    ; URL: http://gccheck.com/GC5EJH7
    ; Captcha: YES
    Gui, Show,, % "Checker - " . args[1] ; Change title
    
    wb.Navigate(args[10]) ; Navigate to webpage
    LoadWait(wb)          ; Wait for page load

    ; Try to fill the webpage form
    Try {
      ; This form is strange, nice way below not working, so we must do it by this unclean way
      ;wb.Document.All.realcoords.Value := args[2] . args[3] . "° " . args[4] . "." . args[5] . " " . args[6] . args[7] . "° " . args[8] . "." . args[9]
      Loop, % (inputs := wb.Document.getElementsByTagName("input")).Length ; For all tags <input>
        If (inputs[A_index-1].Name = "realcoords")                         ; If some of them is name="realcoords"
          inputs[A_index-1].Value := args[2] . args[3] . "° " . args[4] . "." . args[5] . " " . args[6] . args[7] . "° " . args[8] . "." . args[9]
      wb.Document.All.captcha.Focus()
    } Catch e {
      If (debug = 0) {
        MsgBox 16, % textError, % textErrorFill
        ExitApp, errorLvl
      } Else
        MsgBox 16, % textError, % textErrorFill . "`n`nwhat: " e.what "`nfile: " e.file . "`nline: " e.line "`nmessage: " e.message "`nextra: " e.extra
    }

    ; Check result after page reload
    ; YES: <span id="congrats">
    ; NO:  <span id="nope">Nee, das war nix! Nochmal probieren!</span> # <SPAN id=nope>Nee, das war nix! Nochmal probieren!</SPAN>
    If (answer = 1)
      CheckAnwser(wb, "Smi)<span id=.?congrats.?>", "Smi)<span id=.?nope.?>")

  } Else If (SubStr(args[1], 1, 9) = "challenge") { ; ===============================> CHALLENGE (10)
    ; URL: http://project-gc.com/Challenges/GC27Z84
    ; Captcha: NO
    Gui, Show,, % "Checker - " . args[1] ; Change title

    ;If (debug = 1)
    ;  MsgBox 16, % "", % args[10] . "?profile_name=" . UriEncode(SubStr(args[1], 11)) . "&submit=Filter"

    wb.Navigate(args[10]) ; . "?profile_name=" . UriEncode(SubStr(args[1], 11)) . "&submit=Filter") ; Navigate to webpage
    LoadWait(wb)          ; Wait for page load

    ; Try to fill the webpage form
    Try {
      wb.Document.ParentWindow.ScrollTo(0,450) ; Scroll down because page has a huge picture in header

      Loop, % (inputs := wb.Document.getElementsByTagName("input")).Length ; For all tags <input>
        If (inputs[A_index-1].ID = "profile_name")                         ; If some of them is name="realcoords"
          inputs[A_index-1].Value := SubStr(args[1], 11)                   ;UriEncode(SubStr(args[1], 11))

      Sleep, 500

      ; This form is difficult to submit, so we must do it by this unclean way
      Loop, % (inputs := wb.Document.getElementsByTagName("button")).Length ; For all tags <input>
        If (inputs[A_index-1].ID = "runChecker")                            ; If some of them is type="submit"
          inputs[A_index-1].Click()                                         ; Click on it
    } Catch e {
      If (debug = 0) {
        MsgBox 16, % textError, % textErrorFill
        ExitApp, errorLvl
      } Else
        MsgBox 16, % textError, % textErrorFill . "`n`nwhat: " e.what "`nfile: " e.file . "`nline: " e.line "`nmessage: " e.message "`nextra: " e.extra
    }

    ; Check result after page reload
    ; YES: <img src="http://maxcdn.project-gc.com/images/check48.png" alt="Check" title="Úspìch">
    ; NO:  <img src="http://maxcdn.project-gc.com/images/check48.png" alt="Check" title="Úspìch">
    ;If (answer = 1)
    ;  CheckAnwser(wb, "Smi)<img src=.?congrats.?>", "Smi)<img src=.?nope.?>")

  } Else If (args[1] = "gcappsGeochecker") { ; =============================================> GC-APPS GEOCHECKER (11.1)
    ; URL: http://www.gc-apps.com/geochecker/show/b1a0a77fa830ddbb6aa4ed4c69057e79
    ; URL: http://www.gc-apps.com/index.php?option=com_geochecker&view=item&id=b1a0a77fa830ddbb6aa4ed4c69057e79
    ; Captcha: YES
    Gui, Show,, % "Checker - " . args[1] ; Change title

    wb.Navigate(args[10]) ; Navigate to webpage
    LoadWait(wb)          ; Wait for page load

    ; Try to fill the webpage form
    Try {
      If (args[2] = "N")
        wb.Document.All.jform_ns.SelectedIndex := 0
      If (args[2] = "S")
        wb.Document.All.jform_ns.SelectedIndex := 1
      wb.Document.All.jform_nsa.Value := args[3]
      wb.Document.All.jform_nsb.Value := args[4]
      wb.Document.All.jform_nsc.Value := args[5]
      If (args[6] = "W")
        wb.Document.All.jform_we.SelectedIndex := 0
      If (args[6] = "E")
        wb.Document.All.jform_we.SelectedIndex := 1
      wb.Document.All.jform_wea.Value := args[7]
      wb.Document.All.jform_web.Value := args[8]
      wb.Document.All.jform_wec.Value := args[9]

      wb.Document.All._captcha.Focus()
    } Catch e {
      If (debug = 0) {
        MsgBox 16, % textError, % textErrorFill
        ExitApp, errorLvl
      } Else
        MsgBox 16, % textError, % textErrorFill . "`n`nwhat: " e.what "`nfile: " e.file . "`nline: " e.line "`nmessage: " e.message "`nextra: " e.extra
    }

    ; Check result after page reload
    ; YES: <div class="alert alert-success"> .. <img id="status-icon" border="0" src="/components/com_geochecker/assets/images/correct.png" /> .. <div id="status-msg">Richtig!
    ; NO:  <div class="alert alert-danger"> .. <img id="status-icon" border="0" src="/components/com_geochecker/assets/images/wrong.png" /> .. <div id="status-msg">Falsch!
    If (answer = 1)
      CheckAnwser(wb, "Smi)class=.?alert alert-success.?", "Smi)class=.?alert alert-danger.?")

  } Else If (args[1] = "gcappsMultichecker") { ; =============================================> GC-APPS MULTICHECKER (11.2)
    ; URL: http://www.gc-apps.com/multichecker/show/2d2eca9367b250181c6379c46292be32
    ; Captcha: ?
    Gui, Show,, % "Checker - " . args[1] ; Change title

    wb.Navigate(args[10]) ; Navigate to webpage
    LoadWait(wb)          ; Wait for page load

  } Else If (args[1] = "geocachefi") { ; =============================================> GEOCACHE.FI (12)
    ; URL: http://www.geocache.fi/checker/?uid=M9KAR6VJJG5VCDCSZQCR&act=check&wp=GC4CEFD
    ; Captcha: YES
    Gui, Show,, % "Checker - " . args[1] ; Change title

    wb.Navigate(args[10]) ; Navigate to webpage
    LoadWait(wb)          ; Wait for page load

    ; Try to fill the webpage form
    Try {
      If (args[2] = "N")
        wb.Document.All.ns.SelectedIndex := 0
      If (args[2] = "S")
        wb.Document.All.ns.SelectedIndex := 1
      wb.Document.All.cachelat1.Value := args[3]
      wb.Document.All.cachelat2.Value := args[4]
      wb.Document.All.cachelat3.Value := args[5]
      If (args[6] = "E")
        wb.Document.All.ew.SelectedIndex := 0
      If (args[6] = "W")
        wb.Document.All.ew.SelectedIndex := 1
      wb.Document.All.cachelon1.Value := args[7]
      wb.Document.All.cachelon2.Value := args[8]
      wb.Document.All.cachelon3.Value := args[9]

      wb.Document.All.seccode.Focus()
    } Catch e {
      If (debug = 0) {
        MsgBox 16, % textError, % textErrorFill
        ExitApp, errorLvl
      } Else
        MsgBox 16, % textError, % textErrorFill . "`n`nwhat: " e.what "`nfile: " e.file . "`nline: " e.line "`nmessage: " e.message "`nextra: " e.extra
    }

    ; Check result after page reload
    ; YES: <font color="#00AA00" size=5><b>ETUSIVU UUSIKSI! SEH&Auml;N OSUI JA UPPOSI!</b></font>
    ; YES: <font color="#00AA00" size=5><b>SEH&Auml;N MENI KUIN STR&Ouml;MS&Ouml;SS&Auml;! WAUDE!</b></font>
    ; YES: <font color="#00AA00" size=5><b>WHOPII!!!! NAPPIIN MENI!</b></font>
    ; NO:  <font color="#FF0000" size=5><b>EI, EI, EI :(</b></font>
    If (answer = 1)
      CheckAnwser(wb, "Smi)<font color=.?#00AA00.? size=.?5.?>", "Smi)<font color=.?#FF0000.? size=.?5.?>")

  } Else If (args[1] = "geowii") { ; =============================================> GEOWII (13)
    ; URL: http://geowii.miga.lv/wii/GC55D0E
    ; Captcha: -
    Gui, Show,, % "Checker - " . args[1] ; Change title

    wb.Navigate(args[10]) ; Navigate to webpage
    LoadWait(wb)          ; Wait for page load

    ; Try to fill the webpage form
    Try {

      ; Sometimes You need to login to GC.com, and allow access
      ; In this case fill nothing, just wait for user action and maybe next time
      If (wb.Document.getElementsByName("ctl00$ContentBody$uxAllowAccessButton").Length = 0) {
        wb.Document.All.verifyCoordinates.Value := args[2] . args[3] . "° " . args[4] . "." . args[5] . " " . args[6] . args[7] . "° " . args[8] . "." . args[9]
        ;wb.Document.Forms[0].Submit()
      }

    } Catch e {
      If (debug = 0) {
        MsgBox 16, % textError, % textErrorFill
        ExitApp, errorLvl
      } Else
        MsgBox 16, % textError, % textErrorFill . "`n`nwhat: " e.what "`nfile: " e.file . "`nline: " e.line "`nmessage: " e.message "`nextra: " e.extra
    }

    ; Check result after page reload
    ; YES: <h4 class="text-success">Congratulations! The coordinates you entered <strong>N 56&#176; 56.784 E 024&#176; 05.973</strong> are correct!</h4>
    ; NO:  <h4 class="text-danger">The coordinates you entered <strong>N 56&#176; 56.784 E 024&#176; 05.911</strong> are incorrect.</h4>
    If (answer = 1)
      CheckAnwser(wb, "Smi)class=.?text-success.?", "Smi)class=.?text-danger.?")

  } Else If (args[1] = "gcm") { ; =============================================> GC.GCM.CZ (14)
    ; URL: https://gc.gcm.cz/validator/index.php?uuid=7f401a15-231e-44c8-a6e6-bf8b9c69a624
    ; Captcha: YES
    Gui, Show,, % "Checker - " . args[1] ; Change title

    wb.Navigate(args[10]) ; Navigate to webpage
    LoadWait(wb)          ; Wait for page load

    ; Try to fill the webpage form
    Try {
      If (args[2] = "N")
        wb.Document.All.lat_ns.SelectedIndex := 0
      If (args[2] = "S")
        wb.Document.All.lat_ns.SelectedIndex := 1
      wb.Document.All.lat_deg.Value := args[3]
      wb.Document.All.lat_min.Value := args[4] . "." . args[5]
      If (args[6] = "E")
        wb.Document.All.lon_ew.SelectedIndex := 0
      If (args[6] = "W")
        wb.Document.All.lon_ew.SelectedIndex := 1
      wb.Document.All.lon_deg.Value := args[7]
      wb.Document.All.lon_min.Value := args[8] . "." . args[9]

      wb.Document.All.captcha.Focus()

    } Catch e {
      If (debug = 0) {
        MsgBox 16, % textError, % textErrorFill
        ExitApp, errorLvl
      } Else
        MsgBox 16, % textError, % textErrorFill . "`n`nwhat: " e.what "`nfile: " e.file . "`nline: " e.line "`nmessage: " e.message "`nextra: " e.extra
    }

    ; Check result after page reload
    ; YES: <h3 class="success">Výbornì!</h3>
    ; NO:  <h3 class="fail">Bohužel :(</h3>
    If (answer = 1)
      CheckAnwser(wb, "Smi)class=.?success.?", "Smi)class=.?fail.?")

  } Else { ; ======================================================================> SERVICE ERROR
    MsgBox 16, % textError, % textErrorService
    If (debug = 0)
      ExitApp, errorLvl
  }
} ; => Browser()

; Just for debugging
If (debug = 1)
  ListVars

; Call main function
Browser(wb)
Return

; F5 for reload page (and fill form again)
F5:: ; http://ahkscript.org/docs/KeyList.htm
  Browser(wb)
Return

; F6 for save HTML to debug2.html
F6::
If (debug = 1)
  FileAppend, % wb.Document.body.innerHTML, %A_ScriptDir%/debug2.html
Return

; Run when GUI is resized
GuiSize: ; http://ahkscript.org/docs/commands/Gui.htm#GuiSize
  ; http://www.autohotkey.com/docs/commands/GuiControl.htm
  GuiControl, Move, wb, % "w" A_GuiWidth "h" A_GuiHeight - 20
  GuiControl, Move, hint, % "x" 5 "y" A_GuiHeight - 15
  GuiControl, Move, labelanswer, % "x" A_GuiWidth - 60 "y" A_GuiHeight - 15
Return

; Run when GUI is closed
GuiClose:          ; http://ahkscript.org/docs/commands/Gui.htm#GuiClose
  ObjRelease(pipa) ; Implement Tabstop for ActiveX > Shell.Explorer
  Gui Destroy
  If iefix
    FixIE(Prev)    ; Undo registry hack for latest rendering engine
  ExitApp, errorLvl
Return

; Run when ESC is pressed with GUI active
GuiEscape:         ; http://ahkscript.org/docs/commands/Gui.htm#GuiEscape
  ObjRelease(pipa) ; Implement Tabstop for ActiveX > Shell.Explorer
  If iefix
    FixIE(Prev)    ; Undo registry hack for latest rendering engine
  ExitApp, errorLvl
Return
