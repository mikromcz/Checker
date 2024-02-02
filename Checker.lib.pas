{
    Library of Functions

    Www: https://www.geoget.cz/doku.php/user:skript:checker
    Forum: http://www.geocaching.cz/forum/viewthread.php?forum_id=20&thread_id=25822
    Author: mikrom, http://mikrom.cz
    Version: 3.00.0

    ToDo:
    * This might be interesting: http://www.regular-expressions.info/duplicatelines.html
    * pokud se najde více stejných ovìøení napø MoM: GC213AF, GC6DJTY

    * Arne1: mám takový nápad - zatím jsem nebádal zda to bude realizovatelné.
             Když je ovìøovaèem Certitude, tak by se mohl kouknout do poznámky u keše, zda tam není øádek uvozený "certitude:" (napøíklad)
             a ten text za tím pak použil pro ovìøení.

    * geoblackbirds.cz: Chtìl bych se ale zeptat, zda by nešlo automaticky po pøíkazu copymsg vložit text ze schránky do poznámky u final pointu.
                        Jako volitelnou možnost v ini souboru.

}

{Minimum GeoGet version}
{$V 2.9.15}

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
    geocheckRegex        = '(?i)(https?:)?\/\/(www\.)?(geocheck\.org|geotjek\.(dk|eu|org))\/geo_inputchkcoord[^"''<\s]+';
    geocheckerRegex      = '(?i)(https?:)?\/\/(www\.)?geochecker\.com\/index\.php[^"''<\s]+';
    evinceRegex          = '(?i)(https?:)?\/\/(www\.)?evince\.locusprime\.net\/cgi-bin\/[^"''<\s]+';
    hermanskyRegex       = '(?i)(https?:)?\/\/(www\.)?(geo\.hermansky\.net|speedygt\.ic\.cz\/gps)\/index\.php\?co\=checker[^"''<\s]+';
    komurkaRegex         = '(?i)(https?:)?\/\/(www\.)?geo\.komurka\.cz\/check\.php[^"''<\s]+';
    gccounterRegex       = '(?i)(https?:)?\/\/(www\.)?gccounter\.(de|com)\/gcchecker\.php[^"''<\s]+';
    gccounter2Regex      = '(?i)(https?:)?\/\/(www\.)?gccounter\.(de|com)\/GCchecker\/Check[^"''<\s]+';
    certitudesRegex      = '(?i)(https?:)?\/\/(www\.)?certitudes\.org\/certitude(\.php)?\?wp\=[^"''<\s]+';
    gpscacheRegex        = '(?i)(https?:)?\/\/(www\.)?geochecker\.gps-cache\.de\/check\.aspx\?id\=[^"''<\s]+';
    gccheckRegex         = '(?i)(https?:)?\/\/(www\.)?gccheck\.com\/GC[^"''<\s]+';
    challengeRegex       = '(?i)(https?:)?\/\/(www\.)?project-gc\.com\/Challenges\/GC[A-Z0-9]+\/\d+[^"''<\s]+';
    challenge2Regex      = '(?i)(https?:)?\/\/(www\.)?project-gc\.com\/Challenges\/GC[A-Z0-9]+"';
    gcappsGeoRegex       = '(?i)(https?:)?\/\/(www\.)?gc-apps\.com\/(checker|geochecker\/show)\/[^"''<\s]+';
    gcappsMultiRegex     = '(?i)(https?:)?\/\/(www\.)?gc-apps\.com\/multichecker\/show\/[^"''<\s]+';
    geocacheFiRegex      = '(?i)(https?:)?\/\/(www\.)?geocache\.fi\/checker\/\?[^"''<\s]+';
    geowiiRegex          = '(?i)(https?:)?\/\/(www\.)?geowii\.miga\.lv\/wii\/[^"''<\s]+';
    gcmRegex             = '(?i)(https?:)?\/\/(www\.)?(gc\.gcm\.cz\/validator|validator\.gcm\.cz)\/[^"''<\s]+';
    doxinaRegex          = '(?i)(https?:)?\/\/(www\.)?doxina\.filipruzicka\.net\/cache\.php\?id=[^"''<\s]+';
    geocachePlannerRegex = '(?i)(https?:)?\/\/(www\.)?geocache-planer\.de\/CAL\/checker\.php[^"''<\s]+';
    gctoolboxRegex       = '(?i)(https?:)?\/\/(www\.)?gctoolbox\.de\/index\.php\?goto=tools&showtool=coordinatechecker[^"''<\s]+';
    nanocheckerRegex     = '(?i)(https?:)?\/\/(www\.)?nanochecker\.sternli\.ch\/\?g=[^"''<\s]+';
    gzcheckerRegex       = '(?i)(https?:)?\/\/infin\.ity\.me\.uk\/GZ\.php\?MC=[^"''<\s]+';
    puzzleCheckerRegex   = '(?i)(https?:)?\/\/(www\.)?puzzle-checker\.com\/?\?wp=[^"''<\s]+';
    gocachingRegex       = '(?i)(https?:)?\/\/(www\.)?gocaching\.de\/[^"''<\s]+';
    gcccRegex            = '(?i)(https?:)?\/\/(www\.)?gccc\.eu\/\?page=[^"''<\s]+';

var
    answer, history: Boolean;
    coords: String;

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
    //{$ifdef DEBUG_HELPER} LDH('url: ' + url); {$endif}
    url := RegexReplace('#.*', url, '', False); // Preventing doubled urls (www.neco.cz/odkazwww.neco.cz/odkaz)
    {$ifdef DEBUG_HELPER} LDH('out: ' + url); {$endif}
    result := url;
end;

{Add zeroes to one digit minutes in coordinates, some services need it 2.123 => 02.123}
function CorrectCoords(c: String): String;
begin
    {$ifdef DEBUG_HELPER} LDHp('CorrectCoords'); {$endif}
    {$ifdef DEBUG_HELPER} LDH('in:  ' + c); {$endif}

    {                        N            50         30        123        E            015        29        456                 N    50 30 123 E 015 29 456}
    c      := RegexReplace('(N|S)\s(\d+)\s(\d+)\s(\d+)\s(E|W)\s(\d+)\s(\d)\s(\d+)', c, '$1 $2 $3 $4 $5 $6 0$7 $8', True); // For lat
    result := RegexReplace('(N|S)\s(\d+)\s(\d)\s(\d+)\s(E|W)\s(\d+)\s(\d+)\s(\d+)', c, '$1 $2 0$3 $4 $5 $6 $7 $8', True); // For lon

    {$ifdef DEBUG_HELPER} LDH('out: ' + result); {$endif}
end;

{Function to work with GcApi, written by gord.}
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
        else s := _('Result: ') + IntToStr(Result) + CRLF + apiresponse;            // "Návratová hodnota"
    end;
    if (s <> '') then ShowMessage(s);
end;

{Main function. Mainly just sifting by service and call AHK at the end}
procedure Checker(runFrom: String);
var
    url, s, t, coordinates, service, description, correct, incorrect, notfound, callggp, callgge, ggeoutput: String;
    writenotfound: Boolean;
    i, n: Integer;
    ini: TIniFile;
    serviceName, serviceUrl: TStringList;
    serviceNum: Integer;
begin
    {$ifdef DEBUG_HELPER} LDHInit(true); {$endif}
    {$ifdef DEBUG_HELPER} LDHp('Checker'); {$endif}

    {Read configuration from INI}
    ini := TIniFile.Create(GEOGET_SCRIPTDIR+'\Checker\Checker.ini');
    try
        answer        := ini.ReadBool('Checker', 'answer', False);
        correct       := ini.ReadString('Checker', 'correct', 'CORRECT');
        incorrect     := ini.ReadString('Checker', 'incorrect', 'INCORRECT');
        history       := ini.ReadBool('Checker', 'history', False);
        writenotfound := ini.ReadBool('Checker', 'writenotfound', False);
        notfound      := ini.ReadString('Checker', 'notfound', ' NOTFOUND');
        callggp       := ini.ReadString('Checker', 'callggp', '');
        callgge       := ini.ReadString('Checker', 'callgge', '');
        ggeoutput     := ini.ReadString('Checker', 'ggeoutput', '');
    finally
        ini.Free;
    end;

    {This cache GC3PVWQ have url in short description, so we join short and long together}
    description := GC.ShortDescription + GC.LongDescription + GC.Hint;

    {Check if this script runs from GGP or GGC script}
    case runFrom of
        'ggp':
            if (GC.IsSelected) then                                                  // for cache
                coords := FormatCoordNum(GC.CorrectedLatNum, GC.CorrectedLonNum)
            else begin                                                               // for waypoint
                for n := 0 to GC.Waypoints.Count - 1 do begin
                    if (GC.Waypoints[n].IsSelected) then
                        coords := FormatCoordNum(GC.Waypoints[n].LatNum, GC.Waypoints[n].LonNum);
                end;
            end;
        'ggc':
            coords := FormatCoordNum(GC.CorrectedLatNum, GC.CorrectedLonNum);
    end;

    {Just for sure if coordinates are not zero}
    if (coords <> '???') then begin

        serviceName := TStringList.Create;
        serviceUrl := TStringList.Create;

        try
            {Try to find type of the checking service - geocheck.org, geochecker.com, evince.locusprime.net, etc..}
            {
            GEOCHECK
            url: geocheck.org/geo_inputchkcoord.php?gid=61241961c72ab1d-b813-47da-bf03-07c67bb81ac9
            captcha: yes
            }
            s := RegExSubstitute(geocheckRegex, description, '$0#');
            if (s <> '') then begin
                serviceName.Add('geocheck');
                serviceUrl.Add(s);
                Inc(serviceNum);
                {$ifdef DEBUG_HELPER} LDH('Service: geocheck'); {$endif}
            end;
            {
            GEOCHECKER
            url: http://www.geochecker.com/index.php?code=e380cf72d82fa02a81bf71505e8c535c&action=check&wp=4743324457584d&name=536b6c656e696b202d20477265656e20486f757365
            captcha: no
            }
            s := RegExSubstitute(geocheckerRegex, description, '$0#');
            if (s <> '') then begin
                serviceName.Add('geochecker');
                serviceUrl.Add(s);
                Inc(serviceNum);
                {$ifdef DEBUG_HELPER} LDH('Service: geochecker'); {$endif}
            end;
            {
            EVINCE - DEAD
            url: http://evince.locusprime.net/cgi-bin/index.cgi?q=d0ZNzQeHKReGKzr
            captcha: yes
            }
            s := RegExSubstitute(evinceRegex, description, '$0#');
            if (s <> '') then begin
                serviceName.Add('evince');
                serviceUrl.Add(s);
                Inc(serviceNum);
                {$ifdef DEBUG_HELPER} LDH('Service: evince'); {$endif}
            end;
            {
            HERMANSKY
            url: http://geo.hermansky.net/index.php?co=checker&code=2542e4245f80d4f7783e41ed7503fba6b3c8cc3188ff05
            captcha: no
            }
            s := RegExSubstitute(hermanskyRegex, description, '$0#');
            if (s <> '') then begin
                serviceName.Add('hermansky');
                s := ReplaceString(s, 'speedygt.ic.cz/gps', 'geo.hermansky.net');
                serviceUrl.Add(s);
                Inc(serviceNum);
                {$ifdef DEBUG_HELPER} LDH('Service: hermansky'); {$endif}
            end;
            {
            KOMURKA - DEAD
            url: http://geo.komurka.cz/check.php?cache=GC2JCEQ
            captcha: yes
            }
            s := RegExSubstitute(komurkaRegex, description, '$0#');
            if (s <> '') then begin
                serviceName.Add('komurka');
                serviceUrl.Add(s);
                Inc(serviceNum);
                {$ifdef DEBUG_HELPER} LDH('Service: komurka'); {$endif}
            end;
            {
            GCCOUNTER - DEAD
            url: http://gccounter.com/gcchecker.php?site=gcchecker_check&id=2076
            captcha: no
            }
            s := RegExSubstitute(gccounterRegex, description, '$0#');
            if (s <> '') then begin
                serviceName.Add('gccounter');
                serviceUrl.Add(s);
                Inc(serviceNum);
                {$ifdef DEBUG_HELPER} LDH('Service: gccounter'); {$endif}
            end;
            {
            GCCOUNTER2 - DEAD
            url: http://gccounter.de/GCchecker/Check?cacheID=3545
            captcha: no
            }
            s := RegExSubstitute(gccounter2Regex, description, '$0#');
            if (s <> '') then begin
                serviceName.Add('gccounter2');
                serviceUrl.Add(s);
                Inc(serviceNum);
                {$ifdef DEBUG_HELPER} LDH('Service: gccounter2'); {$endif}
            end;
            {
            CERTITUDES
            url: http://www.certitudes.org/certitude?wp=GC2QFYT
            captcha: no
            }
            s := RegExSubstitute(certitudesRegex, description, '$0#');
            if (s <> '') then begin

                // look for note "certitudes: xxx"
                t := RegExSubstitute('certitudes:(.+)', GC.Comment, '$1');
                if (t <> '') then
                    serviceName.Add('certitudes|' + t)
                else
                    serviceName.Add('certitudes');

                serviceUrl.Add(s);
                Inc(serviceNum);
                {$ifdef DEBUG_HELPER} LDH('Service: certitudes'); {$endif}
            end;
            {
            GPS-CACHE
            url: http://geochecker.gps-cache.de/check.aspx?id=7c52d196-b9d2-4b23-ad99-5d6e1bece187
            captcha: yes
            }
            s := RegExSubstitute(gpscacheRegex, description, '$0#');
            if (s <> '') then begin
                serviceName.Add('gpscache');
                serviceUrl.Add(s);
                Inc(serviceNum);
                {$ifdef DEBUG_HELPER} LDH('Service: gpscache'); {$endif}
            end;
            {
            GCCHECK
            url: http://gccheck.com/GC5EJH7
            captcha: yes
            }
            s := RegExSubstitute(gccheckRegex, description, '$0#');
            if (s <> '') then begin
                serviceName.Add('gccheck');
                serviceUrl.Add(s);
                Inc(serviceNum);
                {$ifdef DEBUG_HELPER} LDH('Service: gccheck'); {$endif}
            end;
            {
            CHALLENGE
            url: http://project-gc.com/Challenges/GC5KDPR/11265 - musi se kliknout na submit a mit IE10+
            url: http://project-gc.com/Tools/Challenges?ccId=85&amp;ccTagId=378&amp;ccCountry=Czech+Republic
            captcha: no
            }
            s := RegExSubstitute(challengeRegex, description, '$0#');
            if (s <> '') then begin
                serviceName.Add('"challenge|' + GEOGET_OWNER +'"'); //EncodeUrlElement(GEOGET_OWNER);
                serviceUrl.Add(s);
                Inc(serviceNum);
                {$ifdef DEBUG_HELPER} LDH('Service: challenge'); {$endif}
            end;
            {
            CHALLENGE2
            url: http://project-gc.com/Challenges/GC27Z84 - staèí poslat s parametry (http://project-gc.com/Challenges/GC27Z84?profile_name=mikrom&submit=Filter)
            url: http://project-gc.com/Tools/Challenges?ccId=85&amp;ccTagId=378&amp;ccCountry=Czech+Republic
            captcha: no
            }
            s := RegExSubstitute(challenge2Regex, description, '$0#');
            if (s <> '') then begin
                serviceName.Add('"challenge2|' + GEOGET_OWNER +'"'); //EncodeUrlElement(GEOGET_OWNER);
                s := SeparateLeft(s, '"'); // Regex returns URL ending with "
                serviceUrl.Add(s);
                Inc(serviceNum);
                {$ifdef DEBUG_HELPER} LDH('Service: challenge2'); {$endif}
            end;
            {
            GC-APPS GEOCHECKER
            url: http://www.gc-apps.com/geochecker/show/b1a0a77fa830ddbb6aa4ed4c69057e79
            url: http://www.gc-apps.com/index.php?option=com_geochecker&view=item&id=b1a0a77fa830ddbb6aa4ed4c69057e79
            captcha: yes
            }
            s := RegExSubstitute(gcappsGeoRegex, description, '$0#');
            if (s <> '') then begin
                serviceName.Add('gcappsGeochecker');
                serviceUrl.Add(s);
                Inc(serviceNum);
                {$ifdef DEBUG_HELPER} LDH('Service: gcappsGeochecker'); {$endif}
            end;
            {
            GC-APPS MULTICHECKER
            url: http://beta.gc-apps.com/checker/try/6e520532c3aa8c150ab90a82bf68d874
            captcha: ?
            }
            s := RegExSubstitute(gcappsMultiRegex, description, '$0#');
            if (s <> '') then begin
                serviceName.Add('gcappsMultichecker');
                serviceUrl.Add(s);
                Inc(serviceNum);
                {$ifdef DEBUG_HELPER} LDH('Service: gcappsMultichecker'); {$endif}
            end;
            {
            GEOCACHE.FI
            url: http://www.geocache.fi/checker/?uid=M9KAR6VJJG5VCDCSZQCR&act=check&wp=GC4CEFD
            captcha: yes
            }
            s := RegExSubstitute(geocacheFiRegex, description, '$0#');
            if (s <> '') then begin
                serviceName.Add('geocachefi');
                serviceUrl.Add(s);
                Inc(serviceNum);
                {$ifdef DEBUG_HELPER} LDH('Service: geocachefi'); {$endif}
            end;
            {
            GEOWII.MIGA.LV
            url: http://geowii.miga.lv/wii/GC55D0E
            captcha: -
            }
            s := RegExSubstitute(geowiiRegex, description, '$0#');
            if (s <> '') then begin
                serviceName.Add('geowii');
                serviceUrl.Add(s);
                Inc(serviceNum);
                {$ifdef DEBUG_HELPER} LDH('Service: geowii'); {$endif}
            end;
            {
            GC.GCM.CZ
            url: https://gc.gcm.cz/validator/index.php?uuid=7f401a15-231e-44c8-a6e6-bf8b9c69a624
            captcha: yes
            }
            s := RegExSubstitute(gcmRegex, description, '$0#');
            if (s <> '') then begin
                serviceName.Add('gcm');
                s := ReplaceString(s, 'gc.gcm.cz/validator', 'validator.gcm.cz');
                serviceUrl.Add(s);
                Inc(serviceNum);
                {$ifdef DEBUG_HELPER} LDH('Service: gcm'); {$endif}
            end;
            {
            DOXINA - DEAD
            url: http://doxina.filipruzicka.net/cache.php?id=480
            captcha: ?
            }
            s := RegExSubstitute(doxinaRegex, description, '$0#');
            if (s <> '') then begin
                serviceName.Add('doxina');
                serviceUrl.Add(s);
                Inc(serviceNum);
                {$ifdef DEBUG_HELPER} LDH('Service: doxina'); {$endif}
            end;
            {
            GEOCACHE-PLANNER
            url: https://geocache-planer.de/CAL/checker.php?CALID=GJHTSLO&KEY=0JZRSAG
            captcha: NO
            }
            s := RegExSubstitute(geocachePlannerRegex, description, '$0#');
            if (s <> '') then begin
                serviceName.Add('geocacheplanner');
                serviceUrl.Add(s);
                Inc(serviceNum);
                {$ifdef DEBUG_HELPER} LDH('Service: geocacheplanner'); {$endif}
            end;
            {
            GCTOOLBOX
            url: http://www.gctoolbox.de/index.php?goto=tools&showtool=coordinatechecker&solve=true&id=2062&lang=ger
            captcha: NO
            }
            s := RegExSubstitute(gctoolboxRegex, description, '$0#');
            if (s <> '') then begin
                serviceName.Add('gctoolbox');
                s := ReplaceString(s, 'lang=ger', 'lang=eng'); // Force ENGLISH
                serviceUrl.Add(s);
                Inc(serviceNum);
                {$ifdef DEBUG_HELPER} LDH('Service: gctoolbox'); {$endif}
            end;
            {
            NANOCHECKER
            url: https://nanochecker.sternli.ch/?g=GC662FD
            captcha: YES
            }
            s := RegExSubstitute(nanocheckerRegex, description, '$0#');
            if (s <> '') then begin

                // look for note "nanochecker: xxx"
                t := RegExSubstitute('nanochecker:(.+)', GC.Comment, '$1');
                if (t <> '') then
                    serviceName.Add('nanochecker|' + t)
                else
                    serviceName.Add('nanochecker');

                serviceUrl.Add(s);
                Inc(serviceNum);
                {$ifdef DEBUG_HELPER} LDH('Service: nanochecker'); {$endif}
            end;
            {
            GZ CHECKER
            url: http://infin.ity.me.uk/GZ.php?MC=RR074
            captcha: NO
            }
            s := RegExSubstitute(gzcheckerRegex, description, '$0#');
            if (s <> '') then begin
                serviceName.Add('gzchecker');
                serviceUrl.Add(s);
                Inc(serviceNum);
                {$ifdef DEBUG_HELPER} LDH('Service: gzchecker'); {$endif}
            end;
            {
            PUZZLE CHECKER
            url: https://puzzle-checker.com/?wp=GC80HFF
            captcha: YES
            }
            s := RegExSubstitute(puzzleCheckerRegex, description, '$0#');
            if (s <> '') then begin
                serviceName.Add('puzzlechecker');
                serviceUrl.Add(s);
                Inc(serviceNum);
                {$ifdef DEBUG_HELPER} LDH('Service: puzzlechecker'); {$endif}
            end;
            {
            GOCACHING
            url: http://www.gocaching.de/cochecker.php?check=406
            captcha: YES
            }
            s := RegExSubstitute(gocachingRegex, description, '$0#');
            if (s <> '') then begin
                serviceName.Add('gocaching');
                serviceUrl.Add(s);
                Inc(serviceNum);
                {$ifdef DEBUG_HELPER} LDH('Service: gocaching'); {$endif}
            end;
            {
            GCCC
            url: http://gccc.eu/?page=GC6FBFA
            captcha: NO
            }
            s := RegExSubstitute(gcccRegex, description, '$0#');
            if (s <> '') then begin
                serviceName.Add('gccc');
                serviceUrl.Add(s);
                Inc(serviceNum);
                {$ifdef DEBUG_HELPER} LDH('Service: gccc'); {$endif}
            end;

            //## Gord - start (vyzkousime overovatko na gc.com)
            if (serviceNum = 0) then begin
              serviceName.Add('gc.com');
              i := GcVerify();
              case i of
                204: begin      // Souradnice jsou spravne
                       if (correct <> '') then UpdateWaypointComment(correct);
                       if (history) then LogHistory(coordinates, 'Correct');
                       i := -1;
                     end;
                400: begin      // Souradnice jsou chybne
                       if (incorrect <> '') then UpdateWaypointComment(incorrect);
                       if (history) then LogHistory(coordinates, 'Inorrect');
                       i := -1;
                     end;
                401,            // Chybny pozadavek
                403,            // Nelze overit, prekrocen limit stahovani
                404,            // Nelze overit, keska neexistuje
                405,            // Nelze overit, keska nema overovatko
                406,            // BM clen nemuze overit PMO kesku
                407,            // Uzivatel nepovoluje sdilet informace (to asi pri overovani nemuze nastat)
                429: i := 0;    // Prekrocen pocet opakovani (10 pokusu/10 minut)
                else ShowMessage(_('Error: Unexpected return value: ') + IntToStr(i)); // "ERR: neocekavana navratova hodnota"
              end;
              if (i = -1) then GeoAbort();
            end;
            //## Gord - stop

            {Nothing found}
            if (serviceNum = 0) then begin
                ShowMessage(_('Error: No coordinate checker URL found!'));
                {$ifdef DEBUG_HELPER} LDHe('Error: No coordinate checker URL found!'); {$endif}
                if (writenotfound) then
                    UpdateWaypointComment(notfound);
                    if (callggp <> '') then
                        GeoCallGGP(GEOGET_SCRIPTDIR + callggp);
                    if (callgge <> '') then
                        GeoExport(GEOGET_SCRIPTDIR + callgge, ggeoutput);
                GeoAbort;
            end;

            {N50°30.123' E015°29.456' split to sections divided by spaces => N 50 30 123 E 015 29 456}
            coordinates := RegexReplace('(N|S)(\d+)°(\d+)\.(\d+)''\s(E|W)(\d+)°(\d+)\.(\d+)''', coords, '$1 $2 $3 $4 $5 $6 $7 $8', true);
            coordinates := CorrectCoords(coordinates); // Add leading zeroes to minutes if missing

            {If there more than 1 services found}
            if (serviceNum > 1) then begin
                CheckerForm_ListBox.Items.Assign(serviceName); // Just fill ListBox with TStringList
                CheckerForm_ListBox.Selected[0] := true;

                {Show Window (Cancel return 1, OK return 2)}
                if (CheckerForm.ShowModal <> 1) then
                    Exit
                else begin
                    if (CheckerForm_ListBox.ItemIndex <> -1) then begin
                        for i := 0 to CheckerForm_ListBox.Items.Count - 1 do begin
                            if (CheckerForm_ListBox.Selected[i]) then begin
                                service := CheckerForm_ListBox.Items[CheckerForm_ListBox.ItemIndex]; // Just get selected item
                                url := TrimUrl(serviceUrl[i]);                                                                              // Get same row from stringlist with URLs

                                {$ifdef DEBUG_HELPER} LDH(CheckerForm_ListBox.Items[CheckerForm_ListBox.ItemIndex] + CRLF + serviceUrl[i]); {$endif} // Show name of selected item
                            end;
                        end;
                    end
                    else begin
                        {$ifdef DEBUG_HELPER} LDHe('Error: You didn''t select anything!'); {$endif}

                        ShowMessage(_('Error: You didn''t select anything!'));
                        GeoAbort;
                    end;
                end;
                CheckerForm.Close;
            end
            else begin
                service := serviceName[0];
                url := TrimUrl(serviceUrl[0]);
            end;

            {$ifdef DEBUG_HELPER} LDHp('Checker'); {$endif}

            {Make command for running AHK}
            s := '"' + GEOGET_DATADIR + '\tools\AutoHotkey.exe" "' + GEOGET_SCRIPTDIR + '\Checker\Checker.ahk" ' + service + ' ' + coordinates + ' "' + url + '"';
            {$ifdef DEBUG_HELPER} LDH('Command: ' + s); {$endif}

            {If we can get result of the check}
            if (answer) then begin
                case RunExec(s) of
                    0:  begin
                        // AHK script ran without error, but not found if result was correct or not

                         {$ifdef DEBUG_HELPER} LDH('OK, neither correct or incorrect'); {$endif}
                         if (callggp <> '') then
                            GeoCallGGP(GEOGET_SCRIPTDIR + callggp);
                         if (callgge <> '') then
                            GeoExport(GEOGET_SCRIPTDIR + callgge, ggeoutput);
                        end;
                    1:  begin
                        // If it WAS correct add special comment to the Final waypoint

                            {$ifdef DEBUG_HELPER} LDH('Correct solution! :)'); {$endif}

                            if (correct <> '') then begin
                                UpdateWaypointComment(correct);
                                if (callggp <> '') then
                                    GeoCallGGP(GEOGET_SCRIPTDIR + callggp);
                                if (callgge <> '') then
                                    GeoExport(GEOGET_SCRIPTDIR + callgge, ggeoutput);
                            end;
                            if (history) then
                                LogHistory(coordinates, 'Correct');
                        end;
                    2:  begin
                        // If it WAS NOT correct add special comment to the Final waypoint

                            {$ifdef DEBUG_HELPER} LDH('Incorrect solution! :('); {$endif}

                            if (incorrect <> '') then begin
                                UpdateWaypointComment(incorrect);
                                if (callggp <> '') then
                                    GeoCallGGP(GEOGET_SCRIPTDIR + callggp);
                                if (callgge <> '') then
                                    GeoExport(GEOGET_SCRIPTDIR + callgge, ggeoutput);
                            end;
                            if (history) then
                                LogHistory(coordinates, 'Incorrect');
                        end;
                    3:
                        begin
                            {$ifdef DEBUG_HELPER} LDHe('Error: This should not happen!' + CRLF + 'No or wrong exit code from Checker.ahk'); {$endif}

                            ShowMessage(_('Error: This should not happen!' + CRLF + 'No or wrong exit code from Checker.ahk'));
                        end;
                end;
            end
            else
                RunExecNoWait(s);

        finally
            serviceName.Free;
            serviceUrl.Free;
        end;
    end
    {Wrong coordinates, maybe they are zero}
    else begin
        {$ifdef DEBUG_HELPER} LDHe('Wrong coordinates. Maybe they are zero'); {$endif}

        ShowMessage(_('Wrong coordinates. Maybe they are zero'));
    end;
end;
