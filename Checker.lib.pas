{
	Library of Function

  Www: http://geoget.ararat.cz/doku.php/user:skript:checker
  Forum: http://www.geocaching.cz/forum/viewthread.php?forum_id=20&thread_id=25822
  Author: mikrom, http://mikrom.cz
  Version: 0.1.0.2
}

function TrimUrl(url: string): string;
begin
  url := RegexReplace('\n.*', url, '', false); // nekdy je to na dva radky
  url := RegexReplace('#.*', url, '', false); // zabraneni dvojitym url pokud je v listingu vicekrat (www.neco.cz/odkazwww.neco.cz/odkaz)
  result := url;
end;

Procedure Checker;
var
  s, url, ns, dx, mx, sx, ew, dy, my, sy, service: string;
  n: Integer;
begin
  if GC.IsSelected then begin // for cache
    s := FormatCoordNum(GC.CorrectedLatNum, GC.CorrectedLonNum)
    //if GC.HaveFinal then s := FormatCoordNum(GC.CorrectedLatNum, GC.CorrectedLonNum)
    //else begin
    //  ShowMessage(_('Warning: No final waypoint found!'));
    //  s := '';
    //end;
  end
  else begin // for waypoint
    for n := 0 to GC.Waypoints.Count - 1 do begin
      if GC.Waypoints[n].IsSelected then begin
        s := FormatCoordNum(GC.Waypoints[n].LatNum, GC.Waypoints[n].LonNum)
        //if GC.Waypoints[n].IsFinal then s := FormatCoordNum(GC.Waypoints[n].LatNum, GC.Waypoints[n].LonNum)
        //else ShowMessage(_('Error: Is not final!'));
      end;
    end;
  end;

  if s <> '' then begin
    //s := 'N50°30.123' E015°29.456''';
    ns := RegExSubstitute('(N|S)(\d+)°(\d+)\.(\d+)''\s(E|W)(\d+)°(\d+)\.(\d+)''', s, '$1'); // N
    dx := RegExSubstitute('(N|S)(\d+)°(\d+)\.(\d+)''\s(E|W)(\d+)°(\d+)\.(\d+)''', s, '$2'); // 50
    mx := RegExSubstitute('(N|S)(\d+)°(\d+)\.(\d+)''\s(E|W)(\d+)°(\d+)\.(\d+)''', s, '$3'); // 30
    sx := RegExSubstitute('(N|S)(\d+)°(\d+)\.(\d+)''\s(E|W)(\d+)°(\d+)\.(\d+)''', s, '$4'); // 123
    ew := RegExSubstitute('(N|S)(\d+)°(\d+)\.(\d+)''\s(E|W)(\d+)°(\d+)\.(\d+)''', s, '$5'); // E
    dy := RegExSubstitute('(N|S)(\d+)°(\d+)\.(\d+)''\s(E|W)(\d+)°(\d+)\.(\d+)''', s, '$6'); // 015
    my := RegExSubstitute('(N|S)(\d+)°(\d+)\.(\d+)''\s(E|W)(\d+)°(\d+)\.(\d+)''', s, '$7'); // 29
    sy := RegExSubstitute('(N|S)(\d+)°(\d+)\.(\d+)''\s(E|W)(\d+)°(\d+)\.(\d+)''', s, '$8'); // 456

    {zjistit typ overovaci sluzby - geocheck.org, geochecker.com, evince.locusprime.net, atd..}
    if RegexFind('(https?://|www\.)(geocheck\.org|geotjek\.dk)\/geo_inputchkcoord([^"'']+)', GC.LongDescription) then begin
      url := RegExSubstitute('(https?://|www\.)(geocheck\.org|geotjek\.dk)\/geo_inputchkcoord([^"'']+)', GC.LongDescription, '$0#'); // parsnout url z listingu, GC.LongDescription (konci '#')
      url := TrimUrl(url);
      service := 'geocheck';
      {
      url: geocheck.org/geo_inputchkcoord.php?gid=61241961c72ab1d-b813-47da-bf03-07c67bb81ac9
      captcha: ano
      }
    end
    else if RegexFind('(https?://|www\.)geochecker\.com\/index\.php([^"'']+)', GC.LongDescription) then begin
      url := RegExSubstitute('(https?://|www\.)geochecker\.com\/index\.php([^"'']+)', GC.LongDescription, '$0#'); // parsnout url z listingu, GC.LongDescription (konci '#')
      url := TrimUrl(url);
      service := 'geochecker';
      {
      url: http://www.geochecker.com/index.php?code=e380cf72d82fa02a81bf71505e8c535c&action=check&wp=4743324457584d&name=536b6c656e696b202d20477265656e20486f757365
      captcha: ne
      }
    end
    else if RegexFind('(https?://|www\.)evince\.locusprime\.net\/cgi-bin\/([^"'']+)', GC.LongDescription) then begin
      url := RegExSubstitute('(https?://|www\.)evince\.locusprime\.net\/cgi-bin\/([^"'']+)', GC.LongDescription, '$0#'); // parsnout url z listingu, GC.LongDescription (konci '#')
      url := TrimUrl(url);
      service := 'evince';
      {
      url: http://evince.locusprime.net/cgi-bin/index.cgi?q=d0ZNzQeHKReGKzr
      captcha: ano
      }
    end
    else if RegexFind('(https?://|www\.)(geo\.hermansky\.net|speedygt\.ic\.cz\/gps)\/index\.php\?co\=checker([^"'']+)', GC.LongDescription) then begin
      url := RegExSubstitute('(https?://|www\.)(geo\.hermansky\.net|speedygt\.ic\.cz\/gps)\/index\.php\?co\=checker([^"'']+)', GC.LongDescription, '$0#'); // parsnout url z listingu, GC.LongDescription (konci '#')
      url := TrimUrl(url);
      service := 'hermansky';
      {
      url: http://geo.hermansky.net/index.php?co=checker&code=2542e4245f80d4f7783e41ed7503fba6b3c8cc3188ff05
      captcha: ne
      }
    end
    else if RegexFind('(https?://|www\.)geo\.komurka\.cz\/check\.php([^"'']+)', GC.LongDescription) then begin
      url := RegExSubstitute('(https?://|www\.)geo\.komurka\.cz\/check\.php([^"'']+)', GC.LongDescription, '$0#'); // parsnout url z listingu, GC.LongDescription (konci '#')
      url := TrimUrl(url);
      service := 'komurka';
      {
      url: http://geo.komurka.cz/check.php?cache=GC2JCEQ
      captcha: ano
      }
    end
    else if RegexFind('(https?://|www\.)gccounter\.(de|com)\/gcchecker\.php([^"'']+)', GC.LongDescription) then begin
      url := RegExSubstitute('(https?://|www\.)gccounter\.(de|com)\/gcchecker\.php([^"'']+)', GC.LongDescription, '$0#'); // parsnout url z listingu, GC.LongDescription (konci '#')
      url := TrimUrl(url);
      service := 'gccounter';
      {
      url: http://gccounter.com/gcchecker.php?site=gcchecker_check&id=2076
      captcha: ne
      }
    end
    else if RegexFind('(https?://|www\.)certitudes\.org\/certitude\?wp\=([^"'']+)', GC.LongDescription) then begin
      url := RegExSubstitute('(https?://|www\.)certitudes\.org\/certitude\?wp\=([^"'']+)', GC.LongDescription, '$0#'); // parsnout url z listingu, GC.LongDescription (konci '#')
      url := TrimUrl(url);
      service := 'certitudes';
      {
      url: http://www.certitudes.org/certitude?wp=GC2QFYT
      captcha: ne
      }
    end
    else begin
      ShowMessage('error: ani geocheck.org, ani geochecker.com, ani evince, ani hermansky!');
      GeoAbort;
    end;

    //ShowMessage(GEOGET_SCRIPTDIR + '\checker\checker.exe ' + service + ' ' + ns + ' ' + dx + ' ' + mx + ' ' + sx + ' ' + ew + ' ' + dy + ' ' + my + ' ' + sy + ' ' + url);
    RunExecNoWait('"' + GEOGET_SCRIPTDIR + '\checker\AutoIt3.exe" "' + GEOGET_SCRIPTDIR + '\checker\checker.au3" ' + service + ' ' + ns + ' ' + dx + ' ' + mx + ' ' + sx + ' ' + ew + ' ' + dy + ' ' + my + ' ' + sy + ' ' + url);
  end;
end;
