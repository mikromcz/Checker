{
    Library of Functions

    Www: https://www.geoget.cz/doku.php/user:skript:checker
    Forum: http://www.geocaching.cz/forum/viewthread.php?forum_id=20&thread_id=25822
    Author: mikrom, http://mikrom.cz
    Version: 4.1.0

    Uses: CheckerForm, Checker.ahk

    * Depends on: http://ggplg.valicek.name/plugin/DebugHelper
    * This might be interesting: http://www.regular-expressions.info/duplicatelines.html
}

{Minimum GeoGet version}
{$V 2.12.0}

{I think I should write here what and why is it here :)}
uses
    Checker;

{ $define DEBUG_HELPER}
{$ifdef DEBUG_HELPER}
    {$include DebugHelper.lib.pas}
{$endif}

const
    {Define search regex here, good test is here: https://regex101.com/ or http://regexr.com/
    (https?:)?\/\/(www\.)? should handle probably all possible combination of http://, https://, http://www, https://www, //www, //}
    certitudesRegex      = '(?i)(https?:)?\/\/(www\.)?certitudes\.org\/certitude(\.php)?\?wp\=[^"''<\s]+';
    challengeRegex       = '(?i)(https?:)?\/\/(www\.)?project-gc\.com\/Challenges\/GC[A-Z0-9]+(\/\d+)?[^"''<\s]*';
    doxinaRegex          = '(?i)(https?:)?\/\/(www\.)?doxina\.filipruzicka\.net\/cache\.php\?id=[^"''<\s]+';
    evinceRegex          = '(?i)(https?:)?\/\/(www\.)?evince\.locusprime\.(net|invalid)\/cgi-bin\/[^"''<\s]+';
    gcappsGeoRegex       = '(?i)(https?:)?\/\/(www\.)?gc-apps\.com\/(en|de)?\/?(checker|geochecker\/show)\/[a-z0-9]+\/try';
    gcappsMultiRegex     = '(?i)(https?:)?\/\/(www\.)?gc-apps\.com\/multichecker\/show\/[^"''<\s]+';
    gcccRegex            = '(?i)(https?:)?\/\/(www\.)?gccc\.eu\/\?page=[^"''<\s]+';
    gccheckRegex         = '(?i)(https?:)?\/\/(www\.)?gccheck\.com\/GC[^"''<\s]+';
    gccounter2Regex      = '(?i)(https?:)?\/\/(www\.)?gccounter\.(de|com)\/GCchecker\/Check[^"''<\s]+';
    gccounterRegex       = '(?i)(https?:)?\/\/(www\.)?gccounter\.(de|com)\/gcchecker\.php[^"''<\s]+';
    gcmRegex             = '(?i)(https?:)?\/\/(www\.)?(gc\.gcm\.cz\/validator|validator\.gcm\.cz)\/index[^"''<\s]+';
    gctoolboxRegex       = '(?i)(https?:)?\/\/(www\.)?gctoolbox\.de\/index\.php\?goto=tools&showtool=coordinatechecker[^"''<\s]+';
    geocacheFiRegex      = '(?i)(https?:)?\/\/(www\.)?geocache\.fi\/checker\/\?[^"''<\s]+';
    geocachePlannerRegex = '(?i)(https?:)?\/\/(www\.)?geocache-planer\.de\/CAL\/checker\.php[^"''<\s]+';
    geocheckRegex        = '(?i)(https?:)?\/\/(www\.)?(geocheck\.org|geotjek\.(dk|eu|org))\/geo_inputchkcoord[^"''<\s]+';
    geocheckerRegex      = '(?i)(https?:)?\/\/(www\.)?geochecker\.com\/index\.php[^"''<\s]+';
    geowiiRegex          = '(?i)(https?:)?\/\/(www\.)?geowii\.miga\.lv\/wii\/[^"''<\s]+';
    gocachingRegex       = '(?i)(https?:)?\/\/(www\.)?gocaching\.de\/cochecker[^"''<\s]+';
    gpscacheRegex        = '(?i)(https?:)?\/\/(www\.)?geochecker\.gps-cache\.de\/check\.aspx\?id\=[^"''<\s]+';
    gzcheckerRegex       = '(?i)(https?:)?\/\/infin\.ity\.me\.uk\/GZ\.php\?MC=[^"''<\s]+';
    hermanskyRegex       = '(?i)(https?:)?\/\/(www\.)?(geo\.hermansky\.net|speedygt\.ic\.cz\/gps)\/index\.php\?co\=checker[^"''<\s]+';
    komurkaRegex         = '(?i)(https?:)?\/\/(www\.)?geo\.komurka\.cz\/check\.php[^"''<\s]+';
    nanocheckerRegex     = '(?i)(https?:)?\/\/(www\.)?nanochecker\.sternli\.ch\/\?g=[^"''<\s]+';
    puzzleCheckerRegex   = '(?i)(https?:)?\/\/(www\.)?puzzle-checker\.com\/?\?wp=[^"''<\s]+';

var
    answer, history: Boolean;
    coords: String;
    serviceName, serviceUrl: TStringList;
    serviceNum: Integer;
    service, url: String;
    correct, incorrect: String;

{Update waypoint comment. Add custom string (correct|incorrect from ini) at the begining of the waypoint comment. String will be in curly brackets!}
procedure UpdateWaypointComment(ans: String);
var
    n: Integer;
begin
    {$ifdef DEBUG_HELPER} LDHp('UpdateWaypointComment'); {$endif}

    for n := 0 to GC.Waypoints.Count - 1 do begin
        if ((GC.IsSelected and (GC.CorrectedLat = GC.Waypoints[n].Lat) and (GC.CorrectedLon = GC.Waypoints[n].Lon))
        or (GC.Waypoints[n].IsSelected and (GC.Waypoints[n].GetCoord = coords))) then begin // Which has same coordinates

            {$ifdef DEBUG_HELPER} LDH(GC.Waypoints[n].GetCoord + ' <- GC.Waypoints[n].GetCoord' + CRLF + '                    ' + coords + ' <- coords'); {$endif}

            if (GC.Waypoints[n].Comment <> '') then begin                  // If there is already some comment
                if (RegexFind('^\{[^}]+\}', GC.Waypoints[n].Comment)) then // And HAVE our tag at the begining
                    GC.Waypoints[n].UpdateComment(RegexReplace('^\{([^}]+)\}', GC.Waypoints[n].Comment, '{' + ans + ' ' + FormatDateTime('dd"."mm"."yyyy', Now()) + '}', True)) // REPLACE the existing tag
                else                                                       // Else ADD tag at the begining
                    GC.Waypoints[n].UpdateComment('{' + ans + ' ' + FormatDateTime('dd"."mm"."yyyy', Now()) + '} ' + CRLF + GC.Waypoints[n].Comment);
            end
            else                                                           // Or if comment has no our tag, then ADD only tag
                GC.Waypoints[n].UpdateComment('{' + ans + ' ' + FormatDateTime('dd"."mm"."yyyy', Now()) + '}');

            GeoListUpdateID(GC.ID);                                        // Refresh chache in the list
        end;
    end;
end;

{Simple logging}
procedure LogHistory(checkedCoords, checkerResult: String);
var
    logFile, s: String;
begin
    {$ifdef DEBUG_HELPER} LDHp('LogHistory'); {$endif}

    s := ReplaceString(GEOGET_SCRIPTFULLNAME, GEOGET_SCRIPTNAME, '') + 'Checker.csv';
    {$ifdef DEBUG_HELPER} LDH('file: ' + s); {$endif}

    if (FileExists(s)) then begin
        if (GetFileSize(s) > 100000) then begin
            {$ifdef DEBUG_HELPER} LDH('Delete file'); {$endif}
            DeleteFile(s);
        end
        else begin
            logFile := FileToString(s);
        end;
    end;

    logFile := logFile + CRLF + FormatDateTime('yyyy"."mm"."dd" "hh:nn:ss', Now()) + ';' + GC.ID + ';' + checkedCoords + ';' + checkerResult;
    {$ifdef DEBUG_HELPER} LDH('row:  ' + FormatDateTime('yyyy"."mm"."dd" "hh:nn:ss', Now()) + ';' + GC.ID + ';' + checkedCoords + ';' + checkerResult + ' -> ' + s); {$endif}
    StringToFile(logFile, s);
end;

{Cleaning URLs, sometime its parsed wrong, with this it looks working great}
function TrimUrl(url: String): String;
begin
    {$ifdef DEBUG_HELPER} LDHp('TrimUrl'); {$endif}
    {$ifdef DEBUG_HELPER} LDH('in:  ' + url); {$endif}

    url := RegexReplace('\n.*', url, '', False); // Sometimes it is on two rows
    url := RegexReplace('#.*', url, '', False); // Preventing doubled urls (www.neco.cz/odkazwww.neco.cz/odkaz)

    {$ifdef DEBUG_HELPER} LDH('out: ' + url); {$endif}

    result := url;
end;

{Add zeroes to one digit minutes in coordinates, some services need it 2.123 => 02.123}
function CorrectCoords(c: String): String;
begin
    {$ifdef DEBUG_HELPER} LDHp('CorrectCoords'); {$endif}
    {$ifdef DEBUG_HELPER} LDH('in:  ' + c); {$endif}

    {                        N      50     30     123    E      015    29    456        N 50 30 123 E 015 29 456}
    c      := RegexReplace('(N|S)\s(\d+)\s(\d+)\s(\d+)\s(E|W)\s(\d+)\s(\d)\s(\d+)', c, '$1 $2 $3 $4 $5 $6 0$7 $8', True); // For lat
    result := RegexReplace('(N|S)\s(\d+)\s(\d)\s(\d+)\s(E|W)\s(\d+)\s(\d+)\s(\d+)', c, '$1 $2 0$3 $4 $5 $6 $7 $8', True); // For lon

    {$ifdef DEBUG_HELPER} LDH('out: ' + result); {$endif}
end;

{Function to work with GcApi, written by gord}
function GcVerify: Integer;
var s, apiuri, apidata, apiresponse: String;
    lat, lon: Extended;
begin
    {$ifdef DEBUG_HELPER} LDHp('GcVerify'); {$endif}
    //vraci: 204 - OK, souradnice jsou spravne
    //    z navratove hodnoty 400 vytvorime
    //       400 - souradnice jsou chybne
    //       401 - chybny pozadavek
    //    z navratove hodnoty 403 vytvorime
    //       403 - nelze overit, prekrocen limit stahovani
    //       404 - nelze overit, keska neexistuje
    //       405 - nelze overit, keska nema overovatko
    //       406 - BM clen nemuze overit PMO kesku
    //       407 - uzivatel nepovoluje sdilet informace (to asi pri overovani nemuze nastat)
    //       429 - prekrocen pocet opakovani (10 pokusu/10 minut)

    Result := 401;

    if (not ParseWgsStr(coords, lat, lon)) then exit;

    apiuri := 'v1/geocaches/' + GC.ID + '/finalcoordinates?fields=name,state';
    apidata := '{"latitude": ' + FloatToStr(lat) + ', "longitude": ' + FloatToStr(lon) + '}';
    Result := GcLiveRest('POST', apiuri, apidata, 'application/json', apiresponse);

    if (Pos('coordinates do not match', apiresponse) > 1)                                             then Result := 400;
    if (Pos('geocache ' + GC.ID + ' not found', apiresponse) > 1)                                     then Result := 404;
    if (Pos('geocache owner has not opted in to use the native solution checker', apiresponse) > 1)   then Result := 405;
    if (Pos('only premium members may validate', apiresponse) > 1)                                    then Result := 406;
    if (Pos('cannot verify an unpublished or archived geocache', apiresponse) > 1)                    then Result := 408;

    {$ifdef DEBUG_HELPER} LDH('Result: ' + IntToStr(Result) + CRLF + apiresponse); {$endif}

    s := '';
    case Result of
        204: s := _('OK: Succesfuly verified!');                                    // "Uspesne overeno"
        400: s := _('Error: Coordinates do not match!');                            // "Kontrolovane souradnice jsou chybne"
        //401: s := _('Error: Unauthorized');                                       // "Chybny pozadavek"
        404: s := _('Error: Geocache not found!');                                  // "Keska neexistuje"
        405: ; //s := _('Error: Geocache do not use the native solution checker!'); // "Keska nema overovatko na gc.com" --> Nezobrazujeme, zobrazi to hlavni rutina
        406: s := _('Error: Basic member cannot verify PMO geocache!');             // "BM nemuze overit souradnice PMO kese"
        408: s := _('Error: Cannot verify an unpublished or archived geocache!');   // "Nelze overit nepublikovanou nebo archivovanou kesku"
        429: s := _('Error: Limit exceeded, only 10 in 10 minutes allowed!');       // "Prekrocen limit poctu kontrol (10/10 minut)"
        else s := _('Result: ') + IntToStr(Result) + CRLF + apiresponse;            // "N�vratov� hodnota"
    end;
    if (s <> '') then ShowMessage(s);
end;

{Go through all resultr from regex and if there is more than one, add them one by one to a CheckerList}
procedure AddToCheckersList(s, name: String);
var
    i: Integer;
    list: TStringList;
begin
    if (s <> '') then begin

        {$ifdef DEBUG_HELPER} LDHp('AddToCheckersList'); {$endif}

        list := TStringList.Create;
        try
            list.Delimiter := #10;
            list.DelimitedText := s;

            {Fill list by number of occurences}
            for i := 0 to list.Count - 1 do begin

                {If there is more then one checker (from the same web), then add a serial number at the end}
                if (list.Count > 1) then begin
                    {$ifdef DEBUG_HELPER} LDH('Service: name=' + name + IntToStr(i + 1)); {$endif}
                    {$ifdef DEBUG_HELPER} LDH('Service: url=' + list[i]); {$endif}
                    serviceName.Add(name + ' (' +IntToStr(i + 1) + ')');
                end
                else begin
                    {$ifdef DEBUG_HELPER} LDH('Service: name=' + name); {$endif}
                    {$ifdef DEBUG_HELPER} LDH('Service: url=' + + list[i]); {$endif}
                    serviceName.Add(name);
                end;

                serviceUrl.Add(list[i]);
                Inc(serviceNum);
            end;

        finally
            list.Free;
        end;

    end;
end;

{Remove digits from given string}
function RemoveSerialNum(s: String): String;
begin
    {$ifdef DEBUG_HELPER} LDHp('RemoveSerialNum'); {$endif}
    {$ifdef DEBUG_HELPER} LDH('In:  ' + s); {$endif}

    Result := RegexReplace('\s\(\d+\)', s, '', true);

    {$ifdef DEBUG_HELPER} LDH('Out: ' + Result); {$endif}
end;

{Service detection procedures - extracted from main Checker procedure}
procedure DetectCertitudes(const description: String);
var s, t: String;
begin
    s := RegexExtract(certitudesRegex, description);
    if (s <> '') then begin
        t := RegExSubstitute('certitudes:(.+)', GC.Comment, '$1');
        if (t <> '') then
            serviceName.Add('certitudes|' + t)
        else
            serviceName.Add('certitudes');
        serviceUrl.Add(s);
        Inc(serviceNum);
        {$ifdef DEBUG_HELPER} LDH('Service: certitudes'); {$endif}
    end;
end;

procedure DetectChallenge(const description: String);
var s: String;
begin
    s := RegexExtract(challengeRegex, description);
    AddToCheckersList(s, 'challenge');
end;

procedure DetectDoxina(const description: String);
var s: String;
begin
    s := RegexExtract(doxinaRegex, description);
    AddToCheckersList(s, 'doxina');
end;

procedure DetectEvince(const description: String);
var s: String;
begin
    s := RegexExtract(evinceRegex, description);
    AddToCheckersList(s, 'evince');
end;

procedure DetectGcappsGeo(const description: String);
var s: String;
begin
    s := RegexExtract(gcappsGeoRegex, description);
    AddToCheckersList(s, 'gcappsgeochecker');
end;

procedure DetectGcappsMulti(const description: String);
var s: String;
begin
    s := RegexExtract(gcappsMultiRegex, description);
    AddToCheckersList(s, 'gcappsmultichecker');
end;

procedure DetectGccc(const description: String);
var s: String;
begin
    s := RegexExtract(gcccRegex, description);
    AddToCheckersList(s, 'gccc');
end;

procedure DetectGccheck(const description: String);
var s: String;
begin
    s := RegexExtract(gccheckRegex, description);
    AddToCheckersList(s, 'gccheck');
end;

procedure DetectGccounter(const description: String);
var s: String;
begin
    s := RegexExtract(gccounterRegex, description);
    AddToCheckersList(s, 'gccounter');
end;

procedure DetectGccounter2(const description: String);
var s: String;
begin
    s := RegexExtract(gccounter2Regex, description);
    AddToCheckersList(s, 'gccounter2');
end;

procedure DetectGcm(const description: String);
var s: String;
begin
    s := RegexExtract(gcmRegex, description);
    AddToCheckersList(s, 'gcm');
end;

procedure DetectGctoolbox(const description: String);
var s: String;
begin
    s := RegexExtract(gctoolboxRegex, description);
    AddToCheckersList(s, 'gctoolbox');
end;

procedure DetectGeocacheFi(const description: String);
var s: String;
begin
    s := RegexExtract(geocacheFiRegex, description);
    AddToCheckersList(s, 'geocachefi');
end;

procedure DetectGeocachePlanner(const description: String);
var s: String;
begin
    s := RegexExtract(geocachePlannerRegex, description);
    AddToCheckersList(s, 'geocacheplanner');
end;

procedure DetectGeocachingCom();
begin
    if (Pos('hqsolutionchecker-yes', GC.TagValues('attribute')) > 0) then begin
        serviceName.Add('geocaching.com');
        serviceUrl.Add('#');
        Inc(serviceNum);
    end;
end;

procedure DetectGeocheck(const description: String);
var s: String;
begin
    s := RegexExtract(geocheckRegex, description);
    AddToCheckersList(s, 'geocheck');
end;

procedure DetectGeochecker(const description: String);
var s: String;
begin
    s := RegexExtract(geocheckerRegex, description);
    AddToCheckersList(s, 'geochecker');
end;

procedure DetectGeowii(const description: String);
var s: String;
begin
    s := RegexExtract(geowiiRegex, description);
    AddToCheckersList(s, 'geowii');
end;

procedure DetectGocaching(const description: String);
var s: String;
begin
    s := RegexExtract(gocachingRegex, description);
    AddToCheckersList(s, 'gocaching');
end;

procedure DetectGpscache(const description: String);
var s: String;
begin
    s := RegexExtract(gpscacheRegex, description);
    AddToCheckersList(s, 'gpscache');
end;

procedure DetectGzchecker(const description: String);
var s: String;
begin
    s := RegexExtract(gzcheckerRegex, description);
    AddToCheckersList(s, 'gzchecker');
end;

procedure DetectHermansky(const description: String);
var s: String;
begin
    s := RegexExtract(hermanskyRegex, description);
    AddToCheckersList(s, 'hermansky');
end;

procedure DetectKomurka(const description: String);
var s: String;
begin
    s := RegexExtract(komurkaRegex, description);
    AddToCheckersList(s, 'komurka');
end;

procedure DetectNanochecker(const description: String);
var s, t: String;
begin
    s := RegExSubstitute(nanocheckerRegex, description, '$0#');
    if (s <> '') then begin
        t := RegExSubstitute('nanochecker:(.+)', GC.Comment, '$1');
        if (t <> '') then
            serviceName.Add('nanochecker|' + t)
        else
            serviceName.Add('nanochecker');
        serviceUrl.Add(s);
        Inc(serviceNum);
        {$ifdef DEBUG_HELPER} LDH('Service: nanochecker'); {$endif}
    end;
end;

procedure DetectPuzzleChecker(const description: String);
var s: String;
begin
    s := RegexExtract(puzzleCheckerRegex, description);
    AddToCheckersList(s, 'puzzlechecker');
end;

{Detect all supported services in the cache description}
procedure DetectAllServices(const description: String);
begin
    {$ifdef DEBUG_HELPER} LDHp('DetectAllServices'); {$endif}

    DetectCertitudes(description);
    DetectChallenge(description);
    DetectDoxina(description);
    DetectEvince(description);
    DetectGcappsGeo(description);
    DetectGcappsMulti(description);
    DetectGccc(description);
    DetectGccheck(description);
    DetectGccounter(description);
    DetectGccounter2(description);
    DetectGcm(description);
    DetectGctoolbox(description);
    DetectGeocacheFi(description);
    DetectGeocachePlanner(description);
    DetectGeocachingCom();
    DetectGeocheck(description);
    DetectGeochecker(description);
    DetectGeowii(description);
    DetectGocaching(description);
    DetectGpscache(description);
    DetectGzchecker(description);
    DetectHermansky(description);
    DetectKomurka(description);
    DetectNanochecker(description);
    DetectPuzzleChecker(description);
end;

{Result handling procedures - extracted from main Checker procedure}
procedure CallExternalScripts();
var
    ini: TIniFile;
    callggp, callgge, ggeoutput: String;
begin
    ini := TIniFile.Create(GEOGET_SCRIPTDIR+'\Checker\Checker.ini');
    try
        callggp   := ini.ReadString('Checker', 'callggp', '');
        callgge   := ini.ReadString('Checker', 'callgge', '');
        ggeoutput := ini.ReadString('Checker', 'ggeoutput', '');
    finally
        ini.Free;
    end;

    if (callggp <> '') then
        GeoCallGGP(GEOGET_SCRIPTDIR + callggp);
    if (callgge <> '') then
        GeoExport(GEOGET_SCRIPTDIR + callgge, ggeoutput);
end;

procedure HandleNeutralResult();
begin
    {$ifdef DEBUG_HELPER} LDH('OK, neither correct or incorrect'); {$endif}
    CallExternalScripts();
end;

procedure HandleCorrectResult(const coordinates: String);
var
    ini: TIniFile;
    localCorrect: String;
begin
    {$ifdef DEBUG_HELPER} LDH('Correct solution! :)'); {$endif}

    ini := TIniFile.Create(GEOGET_SCRIPTDIR+'\Checker\Checker.ini');
    try
        localCorrect := ini.ReadString('Checker', 'correct', 'CORRECT');
    finally
        ini.Free;
    end;

    if (localCorrect <> '') then begin
        UpdateWaypointComment(localCorrect);
        CallExternalScripts();
    end;
    if (history) then
        LogHistory(coordinates, 'Correct');
end;

procedure HandleIncorrectResult(const coordinates: String);
var
    ini: TIniFile;
    localIncorrect: String;
begin
    {$ifdef DEBUG_HELPER} LDH('Incorrect solution! :('); {$endif}

    ini := TIniFile.Create(GEOGET_SCRIPTDIR+'\Checker\Checker.ini');
    try
        localIncorrect := ini.ReadString('Checker', 'incorrect', 'INCORRECT');
    finally
        ini.Free;
    end;

    if (localIncorrect <> '') then begin
        UpdateWaypointComment(localIncorrect);
        CallExternalScripts();
    end;
    if (history) then
        LogHistory(coordinates, 'Incorrect');
end;

procedure HandleDeadService();
begin
    {$ifdef DEBUG_HELPER} LDHw('Dead service.'); {$endif}
    ShowMessage(_('Dead service.'));
end;

procedure HandleWrongParameters();
begin
    {$ifdef DEBUG_HELPER} LDHe('Wrong parameters!'); {$endif}
    ShowMessage(_('Wrong parameters!'));
end;

procedure HandleCheckerResult(exitCode: Integer; const coordinates: String);
begin
    case exitCode of
        0: HandleNeutralResult();
        1: HandleCorrectResult(coordinates);
        2: HandleIncorrectResult(coordinates);
        3: HandleDeadService();
        4: HandleWrongParameters();
    end;
end;

{Service selection procedures}
function ShowServiceSelectionDialog(): Boolean;
var i: Integer;
begin
    Result := False;
    CheckerForm_ListBox.Items.Assign(serviceName);
    CheckerForm_ListBox.Selected[0] := true;

    if (CheckerForm.ShowModal <> 1) then
        Exit
    else begin
        if (CheckerForm_ListBox.ItemIndex <> -1) then begin
            for i := 0 to CheckerForm_ListBox.Items.Count - 1 do begin
                if (CheckerForm_ListBox.Selected[i]) then begin
                    service := CheckerForm_ListBox.Items[CheckerForm_ListBox.ItemIndex];
                    url := TrimUrl(serviceUrl[i]);
                    {$ifdef DEBUG_HELPER} LDH(CheckerForm_ListBox.Items[CheckerForm_ListBox.ItemIndex] + CRLF + serviceUrl[i]); {$endif}
                    Result := True;
                end;
            end;
        end
        else begin
            ShowMessage(_('Error: You didn''t select anything!'));
            {$ifdef DEBUG_HELPER} LDHe('Error: You didn''t select anything!'); {$endif}
            GeoAbort;
        end;
    end;
    CheckerForm.Close;
end;

function SelectService(): Boolean;
begin
    Result := False;
    if (serviceNum > 1) then
        Result := ShowServiceSelectionDialog()
    else begin
        service := serviceName[0];
        url := TrimUrl(serviceUrl[0]);
        Result := True;
    end;
end;

{Helper functions for main procedure}
function InitializeChecker(runFrom: String): Boolean;
var n: Integer;
begin
    Result := False;

    {Check if this script runs from GGP or GGC script}
    case runFrom of
        'ggp':
            if (GC.IsSelected) then
                coords := FormatCoordNum(GC.CorrectedLatNum, GC.CorrectedLonNum)
            else begin
                for n := 0 to GC.Waypoints.Count - 1 do begin
                    if (GC.Waypoints[n].IsSelected) then
                        coords := FormatCoordNum(GC.Waypoints[n].LatNum, GC.Waypoints[n].LonNum);
                end;
            end;
        'ggc':
            coords := FormatCoordNum(GC.CorrectedLatNum, GC.CorrectedLonNum);
    end;

    Result := True;
end;

function ValidateCoordinates(): Boolean;
begin
    Result := (coords <> '???');
    if not Result then begin
        {$ifdef DEBUG_HELPER} LDHe('Wrong coordinates. Maybe they are zero'); {$endif}
        ShowMessage(_('Wrong coordinates. Maybe they are zero'));
    end;
end;

function HasServicesFound(): Boolean;
var
    ini: TIniFile;
    writenotfound: Boolean;
    notfound, callggp, callgge, ggeoutput: String;
begin
    Result := (serviceNum > 0);
    if not Result then begin
        ShowMessage(_('Error: No coordinate checker URL found!'));
        {$ifdef DEBUG_HELPER} LDHe('Error: No coordinate checker URL found!'); {$endif}

        ini := TIniFile.Create(GEOGET_SCRIPTDIR+'\Checker\Checker.ini');
        try
            writenotfound := ini.ReadBool('Checker', 'writenotfound', False);
            notfound      := ini.ReadString('Checker', 'notfound', 'NOTFOUND');
            callggp       := ini.ReadString('Checker', 'callggp', '');
            callgge       := ini.ReadString('Checker', 'callgge', '');
            ggeoutput     := ini.ReadString('Checker', 'ggeoutput', '');
        finally
            ini.Free;
        end;

        if (writenotfound) then
            UpdateWaypointComment(notfound);
        if (callggp <> '') then
            GeoCallGGP(GEOGET_SCRIPTDIR + callggp);
        if (callgge <> '') then
            GeoExport(GEOGET_SCRIPTDIR + callgge, ggeoutput);
        GeoAbort;
    end;
end;

procedure HandleGeocachingComService(const coordinates: String);
var
    i: Integer;
    ini: TIniFile;
    localCorrect, localIncorrect: String;
begin
    {$ifdef DEBUG_HELPER} LDH('Service: geocaching.com'); {$endif}
    {$ifdef DEBUG_HELPER} LDH('Attributes: ' + GC.TagValues('attribute')); {$endif}

    ini := TIniFile.Create(GEOGET_SCRIPTDIR+'\Checker\Checker.ini');
    try
        localCorrect   := ini.ReadString('Checker', 'correct', 'CORRECT');
        localIncorrect := ini.ReadString('Checker', 'incorrect', 'INCORRECT');
    finally
        ini.Free;
    end;

    i := GcVerify();
    case i of
        204: begin
            if (localCorrect <> '') then UpdateWaypointComment(localCorrect);
            if (history) then LogHistory(coordinates, 'Correct');
            i := -1;
        end;
        400: begin
            if (localIncorrect <> '') then UpdateWaypointComment(localIncorrect);
            if (history) then LogHistory(coordinates, 'Inorrect');
            i := -1;
        end;
        401, 403, 404, 405, 406, 407, 408, 429: i := 0;
        else ShowMessage(_('Error: Unexpected return value: ') + IntToStr(i));
    end;
    if (i = -1) then GeoAbort();
end;

procedure HandleExternalService(const coordinates: String);
var s: String;
begin
    {$ifdef DEBUG_HELPER} LDHp('Call Checker.ahk'); {$endif}

    s := '"' + GEOGET_SCRIPTDIR + '\Checker\AutoHotkey64.exe" "' + GEOGET_SCRIPTDIR + '\Checker\Checker.ahk" "' + RemoveSerialNum(service) + '" ' + coordinates + ' "' + url + '"';
    {$ifdef DEBUG_HELPER} LDH('Command: ' + s); {$endif}

    if (answer) then
        HandleCheckerResult(RunExec(s), coordinates)
    else
        RunExecNoWait(s);
end;

{Main function - simplified and refactored}
procedure Checker(runFrom: String);
var
    description, coordinates: String;
    ini: TIniFile;
begin
    {$ifdef DEBUG_HELPER} LDHInit(true); {$endif}
    {$ifdef DEBUG_HELPER} LDHp('----------------------------------------'); {$endif}
    {$ifdef DEBUG_HELPER} LDHp('Checker'); {$endif}
    {$ifdef DEBUG_HELPER} LDHp('----------------------------------------'); {$endif}

    {Read configuration from INI}
    ini := TIniFile.Create(GEOGET_SCRIPTDIR+'\Checker\Checker.ini');
    try
        answer    := ini.ReadBool('Checker', 'answer', False);
        correct   := ini.ReadString('Checker', 'correct', 'CORRECT');
        incorrect := ini.ReadString('Checker', 'incorrect', 'INCORRECT');
        history   := ini.ReadBool('Checker', 'history', False);
    finally
        ini.Free;
    end;

    {This cache GC3PVWQ have url in short description, so we join short and long together}
    description := GC.ShortDescription + GC.LongDescription + GC.Hint;

    {Initialize coordinates based on run source}
    if not InitializeChecker(runFrom) then Exit;

    {Validate coordinates}
    if not ValidateCoordinates() then Exit;

    serviceName := TStringList.Create;
    serviceUrl := TStringList.Create;

    try
        {Detect all supported checker services}
        DetectAllServices(description);

        {Check if any services were found}
        if not HasServicesFound() then Exit;

        {Prepare coordinates format}
        {$ifdef DEBUG_HELPER} LDH('Coords: ' + coords); {$endif}
        coordinates := RegexReplace('(N|S)(\d+)°(\d+)\.(\d+)''\s(E|W)(\d+)°(\d+)\.(\d+)''', AnsiToUtf(coords), '$1 $2 $3 $4 $5 $6 $7 $8', true);
        //ShowMessage(_('Coords: ') + CRLF + coords + CRLF + _('Coordinates: ') + CRLF + coordinates);
        {$ifdef DEBUG_HELPER} LDH('Coordinates: ' + coordinates); {$endif}
        coordinates := CorrectCoords(coordinates);

        {Let user select service if multiple found}
        if not SelectService() then Exit;

        {Handle the selected service}
        if (service = 'geocaching.com') then
            HandleGeocachingComService(coordinates)
        else
            HandleExternalService(coordinates);

    finally
        serviceName.Free;
        serviceUrl.Free;
    end;
end;
