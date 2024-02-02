{
  Library of Functions

  Www: http://geoget.ararat.cz/doku.php/user:skript:checker
  Forum: http://www.geocaching.cz/forum/viewthread.php?forum_id=20&thread_id=25822
  Author: mikrom, http://mikrom.cz
  Version: 2.10.0

  ToDo:
  * This is maybe interesting: http://www.regular-expressions.info/duplicatelines.html
}

const
  {Define search regex here, good test is here: https://regex101.com/ or http://regexr.com/}
  geocheckRegex    = '(?i)https?:\/\/(www\.)?(geocheck\.org|geotjek\.dk)\/geo_inputchkcoord([^"''<\s]+)';
  geocheckerRegex  = '(?i)https?:\/\/(www\.)?geochecker\.com\/index\.php([^"''<\s]+)';
  evinceRegex      = '(?i)https?:\/\/(www\.)?evince\.locusprime\.net\/cgi-bin\/([^"''<\s]+)';
  hermanskyRegex   = '(?i)https?:\/\/(www\.)?(geo\.hermansky\.net|speedygt\.ic\.cz\/gps)\/index\.php\?co\=checker([^"''<\s]+)';
  komurkaRegex     = '(?i)https?:\/\/(www\.)?geo\.komurka\.cz\/check\.php([^"''<\s]+)';
  gccounterRegex   = '(?i)https?:\/\/(www\.)?gccounter\.(de|com)\/gcchecker\.php([^"''<\s]+)';
  gccounter2Regex  = '(?i)https?:\/\/(www\.)?gccounter\.(de|com)\/GCchecker\/Check([^"''<\s]+)';
  certitudesRegex  = '(?i)https?:\/\/(www\.)?certitudes\.org\/certitude(\.php)?\?wp\=([^"''<\s]+)';
  gpscacheRegex    = '(?i)https?:\/\/(www\.)?geochecker\.gps-cache\.de\/check\.aspx\?id\=([^"''<\s]+)';
  gccheckRegex     = '(?i)https?:\/\/(www\.)?gccheck\.com\/(GC[^"''<\s]+)';
  challengeRegex   = '(?i)https?:\/\/(www\.)?project-gc\.com\/Challenges\/GC[A-Z0-9]+\/\d+[^"''<\s]+';
  gcappsGeoRegex   = '(?i)https?:\/\/(www\.)?gc-apps\.com\/geochecker\/show\/([^"''<\s]+)'; // '(?i)https?:\/\/(www\.)?gc-apps\.com\/(geochecker\/show\/)|(index\.php\?option=com_geochecker&view=item&id=)([^"''<\s]+)';
  gcappsMultiRegex = '(?i)https?:\/\/(www\.)?gc-apps\.com\/multichecker\/show\/([^"''<\s]+)';
  geocacheFiRegex  = '(?i)https?:\/\/(www\.)?geocache\.fi\/checker\/\?.+wp\=([^"''<\s]+)';
  geowiiRegex      = '(?i)https?:\/\/(www\.)?geowii\.miga\.lv\/wii\/([^"''<\s]+)';
  
var
  debug, answer: Boolean;
  coords: String;

{Update waypoint comment. Add custom string (correct|incorrect from ini) at the begining of the waypoint comment. String will be in curly brackets!}
procedure UpdateWaypointComment(ans: String);
var
  n: Integer;
begin
  for n:=0 to GC.Waypoints.Count-1 do begin
    if ((GC.IsSelected and (GC.CorrectedLat = GC.Waypoints[n].Lat) and (GC.CorrectedLon = GC.Waypoints[n].Lon))
    or (GC.Waypoints[n].IsSelected and (GC.Waypoints[n].GetCoord = coords))) then begin // Which has same coordinates
    
      if debug then ShowMessage(GC.Waypoints[n].GetCoord+' <- GC.Waypoints[n].GetCoord'+CRLF+coords+' <- coords');
    
      if GC.Waypoints[n].Comment <> '' then begin                // If there is already some comment
        if RegexFind('^\{[^}]+\}', GC.Waypoints[n].Comment) then // And HAVE our tag at the begining
          GC.Waypoints[n].UpdateComment(RegexReplace('^\{([^}]+)\}', GC.Waypoints[n].Comment, '{'+ans+' '+FormatDateTime('dd"."mm"."yyyy', Now())+'}', true)) // REPLACE the existing tag
        else                                                     // Else ADD tag at the begining
          GC.Waypoints[n].UpdateComment('{'+ans+' '+FormatDateTime('dd"."mm"."yyyy', Now())+'} ' + GC.Waypoints[n].Comment);
      end
      else                                                       // Or if comment has no our tag, then ADD only tag
        GC.Waypoints[n].UpdateComment('{'+ans+' '+FormatDateTime('dd"."mm"."yyyy', Now())+'}');
        
      GeoListUpdateID(GC.ID);                                    // Refresh chache in the list
    end;
  end;
end;

{Cleaning URLs, sometime its parsed wrong, with this it looks working great}
function TrimUrl(url: String): String;
begin
  if debug then ShowMessage(url);
  url := RegexReplace('\n.*', url, '', false); // Sometimes it is on two rows
  if debug then ShowMessage(url);
  url := RegexReplace('#.*', url, '', false);  // Preventing doubled urls (www.neco.cz/odkazwww.neco.cz/odkaz)
  result := url;
end;

{Add zeroes to one digit minutes in coordinates, some services need it 2.123 => 02.123}
function CorrectCoords(c: String): String;
begin
  {                        N      50     30    123    E      015    29    456         N  50 30 123 E 015 29 456}
  c      := RegexReplace('(N|S)\s(\d+)\s(\d+)\s(\d+)\s(E|W)\s(\d+)\s(\d)\s(\d+)', c, '$1 $2 $3 $4 $5 $6 0$7 $8', true); // For lat
  result := RegexReplace('(N|S)\s(\d+)\s(\d)\s(\d+)\s(E|W)\s(\d+)\s(\d+)\s(\d+)', c, '$1 $2 0$3 $4 $5 $6 $7 $8', true); // For lon
end;

{Main function. Mainly just sifting by service and call AHK at the end}
procedure Checker(runFrom: String);
var
  url, s, coordinates, service, description, correct, incorrect: String;
  n: Integer;
  ini: TIniFile;
begin
  {Read configuration from INI}
  ini := TIniFile.Create(GEOGET_SCRIPTDIR+'\Checker\Checker.ini');
  try
    debug := ini.ReadBool('Checker', 'debug', False);
    answer := ini.ReadBool('Checker', 'answer', False);
    correct := ini.ReadString('Checker', 'correct', 'CORRECT');
    incorrect := ini.ReadString('Checker', 'incorrect', 'INCORRECT');
  finally
    ini.Free;
  end;
  
  {This cache GC3PVWQ have url in short description, so we join short and long together}
  description := GC.ShortDescription + GC.LongDescription;

  {Check if this script runs from GGP or GGC script}
  case runFrom of
    'ggp': if GC.IsSelected then                                             // for cache
             coords := FormatCoordNum(GC.CorrectedLatNum, GC.CorrectedLonNum)
           else begin                                                        // for waypoint
             for n:=0 to GC.Waypoints.Count-1 do
               if GC.Waypoints[n].IsSelected then coords := FormatCoordNum(GC.Waypoints[n].LatNum, GC.Waypoints[n].LonNum);
           end;
    'ggc': coords := FormatCoordNum(GC.CorrectedLatNum, GC.CorrectedLonNum);
  end;

  {Just for sure if coordinates are not zero}
  if coords <> '???' then begin
        
    {Try to find type of the checking service - geocheck.org, geochecker.com, evince.locusprime.net, etc..}
    {
    GEOCHECK
    url: geocheck.org/geo_inputchkcoord.php?gid=61241961c72ab1d-b813-47da-bf03-07c67bb81ac9
    captcha: yes
    }
    if RegexFind(geocheckRegex, description) then begin
      url := RegExSubstitute(geocheckRegex, description, '$0#'); // Parse URL from listing (on purpose it ends with '#')
      service := 'geocheck';
    end
    {
    GEOCHECKER
    url: http://www.geochecker.com/index.php?code=e380cf72d82fa02a81bf71505e8c535c&action=check&wp=4743324457584d&name=536b6c656e696b202d20477265656e20486f757365
    captcha: no
    }
    else if RegexFind(geocheckerRegex, description) then begin
      url := RegExSubstitute(geocheckerRegex, description, '$0#'); // Parse URL from listing (on purpose it ends with '#')
      service := 'geochecker';
    end
    {
    EVINCE
    url: http://evince.locusprime.net/cgi-bin/index.cgi?q=d0ZNzQeHKReGKzr
    captcha: yes
    }
    else if RegexFind(evinceRegex, description) then begin
      url := RegExSubstitute(evinceRegex, description, '$0#'); // Parse URL from listing (on purpose it ends with '#')
      service := 'evince';
    end
    {
    HERMANSKY
    url: http://geo.hermansky.net/index.php?co=checker&code=2542e4245f80d4f7783e41ed7503fba6b3c8cc3188ff05
    captcha: no
    }
    else if RegexFind(hermanskyRegex, description) then begin
      url := RegExSubstitute(hermanskyRegex, description, '$0#'); // Parse URL from listing (on purpose it ends with '#')
      service := 'hermansky';
    end
    {
    KOMURKA
    url: http://geo.komurka.cz/check.php?cache=GC2JCEQ
    captcha: yes
    }
    else if RegexFind(komurkaRegex, description) then begin
      url := RegExSubstitute(komurkaRegex, description, '$0#'); // Parse URL from listing (on purpose it ends with '#')
      service := 'komurka';
    end
    {
    GCCOUNTER
    url: http://gccounter.com/gcchecker.php?site=gcchecker_check&id=2076
    captcha: no
    }
    else if RegexFind(gccounterRegex, description) then begin
      url := RegExSubstitute(gccounterRegex, description, '$0#'); // Parse URL from listing (on purpose it ends with '#')
      service := 'gccounter';
    end
    {
    GCCOUNTER2
    url: http://gccounter.de/GCchecker/Check?cacheID=3545
    captcha: no
    }
    else if RegexFind(gccounter2Regex, description) then begin
      url := RegExSubstitute(gccounter2Regex, description, '$0#'); // Parse URL from listing (on purpose it ends with '#')
      service := 'gccounter2';
    end
    {
    CERTITUDES
    url: http://www.certitudes.org/certitude?wp=GC2QFYT
    captcha: no
    }
    else if RegexFind(certitudesRegex, description) then begin
      url := RegExSubstitute(certitudesRegex, description, '$0#'); // Parse URL from listing (on purpose it ends with '#')
      service := 'certitudes';
    end
    {
    GPS-CACHE
    url: http://geochecker.gps-cache.de/check.aspx?id=7c52d196-b9d2-4b23-ad99-5d6e1bece187
    captcha: yes
    }
    else if RegexFind(gpscacheRegex, description) then begin
      url := RegExSubstitute(gpscacheRegex, description, '$0#'); // Parse URL from listing (on purpose it ends with '#')
      service := 'gpscache';
    end
    {
    GCCHECK
    url: http://gccheck.com/GC5EJH7
    captcha: yes
    }
    else if RegexFind(gccheckRegex, description) then begin
      url := RegExSubstitute(gccheckRegex, description, '$0#'); // Parse URL from listing (on purpose it ends with '#')
      service := 'gccheck';
    end
    {
    CHALLENGE
    url: http://project-gc.com/Challenges/GC27Z84         (zde staèí poslat s parametry)
    url: http://project-gc.com/Challenges/GC5KDPR/11265   (zde se musi kliknout na submit a mit IE10+)
    url: http://project-gc.com/Tools/Challenges?ccId=85&amp;ccTagId=378&amp;ccCountry=Czech+Republic
    captcha: no
    }
    else if RegexFind(challengeRegex, description) then begin
      url := RegExSubstitute(challengeRegex, description, '$0#'); // Parse URL from listing (on purpose it ends with '#')
      service := '"challenge|' + GEOGET_OWNER +'"'; //EncodeUrlElement(GEOGET_OWNER);
    end
    {
    GC-APPS GEOCHECKER
    url: http://www.gc-apps.com/geochecker/show/b1a0a77fa830ddbb6aa4ed4c69057e79
    url: http://www.gc-apps.com/index.php?option=com_geochecker&view=item&id=b1a0a77fa830ddbb6aa4ed4c69057e79
    captcha: yes
    }
    else if RegexFind(gcappsGeoRegex, description) then begin
      url := RegExSubstitute(gcappsGeoRegex, description, '$0#'); // Parse URL from listing (on purpose it ends with '#')
      service := 'gcappsGeochecker';
    end
    {
    GC-APPS MULTICHECKER
    url: http://beta.gc-apps.com/checker/try/6e520532c3aa8c150ab90a82bf68d874
    captcha: ?
    }
    else if RegexFind(gcappsMultiRegex, description) then begin
      url := RegExSubstitute(gcappsMultiRegex, description, '$0#'); // Parse URL from listing (on purpose it ends with '#')
      service := 'gcappsMultichecker';
    end
    {
    GEOCACHE.FI
    url: http://www.geocache.fi/checker/?uid=M9KAR6VJJG5VCDCSZQCR&act=check&wp=GC4CEFD
    captcha: yes
    }
    else if RegexFind(geocacheFiRegex, description) then begin
      url := RegExSubstitute(geocacheFiRegex, description, '$0#'); // Parse URL from listing (on purpose it ends with '#')
      service := 'geocachefi';
    end
    {
    GEOWII.MIGA.LV
    url: http://geowii.miga.lv/wii/GC55D0E
    captcha: -
    }
    else if RegexFind(geowiiRegex, description) then begin
      url := RegExSubstitute(geowiiRegex, description, '$0#'); // Parse URL from listing (on purpose it ends with '#')
      service := 'geowii';
    end 
    {Standard behavior}
    else begin
      ShowMessage(_('Error: No coordinate checker URL found!'));
      if debug then StringToFile(description, GEOGET_SCRIPTDIR + '\Checker\description.html');
      GeoAbort;
    end;

    {N50°30.123' E015°29.456' split to sections divided by spaces => N 50 30 123 E 015 29 456}
    coordinates := RegexReplace('(N|S)(\d+)°(\d+)\.(\d+)''\s(E|W)(\d+)°(\d+)\.(\d+)''', coords, '$1 $2 $3 $4 $5 $6 $7 $8', true);
    coordinates := CorrectCoords(coordinates); // Add leading zeroes to minutes if missing
    
    {Make command for running AHK}
    s := '"' + GEOGET_DATADIR+'\tools\AutoHotkey.exe" "' + GEOGET_SCRIPTDIR+'\Checker\Checker.ahk" ' + service + ' ' + coordinates + ' "' + TrimUrl(url) + '"';
    if debug then ShowMessage(s);
    
    {If we can get result of the check}
    if answer then begin
      case RunExec(s) of
        0: if debug then ShowMessage(_('OK, neither correct or incorrect')); // AHK script run without error, but not found if result was correct or not
        1: begin                                                             // If it WAS correct add special comment to the Final waypoint
             if debug then ShowMessage(_('Correct solution! :)'));
             if correct <> '' then UpdateWaypointComment(correct);
           end;
        2: begin                                                             // If it WAS NOT correct add special comment to the Final waypoint
             if debug then ShowMessage(_('Incorrect solution! :('));
             if incorrect <> '' then UpdateWaypointComment(incorrect);
           end;
        3: if debug then ShowMessage(_('Error'));
      end;
    end
    else
      RunExecNoWait(s);
  end
  {Wrong coordinates, maybe they are zero}
  else
    ShowMessage(_('Wrong coordinates. Maybe they are zero'));
end;
