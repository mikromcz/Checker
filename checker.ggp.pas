{
	General Plugin Script

  Www: http://geoget.ararat.cz/doku.php/user:skript:checker
  Forum: http://www.geocaching.cz/forum/viewthread.php?forum_id=20&thread_id=25822
  Author: mikrom, http://mikrom.cz
  Version: 0.0.1.8
}

function PluginCaption: string;
begin
  Result:='Checker';
end;

function PluginHint: string;
begin
  Result:=_('Open and fill checker page (geocheck.org, geochecker.com, evince.locusprime.net, etc.)');
end;

function PluginIcon: string;
begin
  Result:=DecodeBase64('iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAn5JREFUeNqUU01oU0EQns1LXvKatwmJ1dZQCzU9WLw1JaI9Kb0piAiNf0XqofQggj83KYKmB08eBD0UCx4s9eBBLxqllpJDkSBYG7GUBIKSggQT0/z0mff2rbPpa0hSFBz42JndmW9mdmdJ7LIdNB1gy+AgxK8QaJOQySHCONiYyZ+jntg5OP3MALtQFAeAWybATADOW4L9aEaO33o8WcptlOJP7sq8iUCIvcWQACQsQDMaW5d6QiODnBGqeDqJYYBkWglUJ9lN0CbXJJd6uO/oqbAw0omF5G8GnwRBl0rAaYd/EtSDj01Mnydgp4auldeWF9ZqjMcO+m3w1xYsmaQeGhwcnz5HbDItfkt+eT03m6KkontdZArPf1l+7xBviXgF0Y2NQIAQOONQ6MDQlegYcnuEl+x2gyTLu7K8j154cGJWvyEqGBI3jSXTroFw8ED45BFmAAXYvsmtYhHcPh9UCoVG8OZGKmuYwOot6IxfDI3eHFW7+wI1TYNqRQOG180YAxPhdLnARWl9b/7+9Rc7JFj1qzqBwYC69/YGKpjJ0HXQa7UWUK8XfLivqCqM35s5W87nyvGZ209LNYjXCWomOBg6mAKYpQ7MzM3tqRK6OM98XS3E5h4lrOyNSmzYgiwcDFF2UzDHYDEzQhfkvf2HfJGrU8P7VJJVZLLYIVuDhP+A576nf3o6A3sM4WyhUQGuIsHSm5fZlQ9LWQybb34NaSQI+VTyY0/+R7Za3sxXK8VCFfdNQvBhCdjwEkmHooDH65Mzq8ufTSBRCY8EhsfugB1Hc1HT+UomvR6E9Ho/2vuRIIDoRvisYRMzUcU5eSgKb/5vhLd9v/+VPwIMAHaYM3koihLpAAAAAElFTkSuQmCC');
end;

function PluginFlags: string;
begin
  Result:='';
end;

function TrimUrl(url:string): string;
begin
  url:=RegexReplace('\n.*',url,'',false); // nekdy je to na dva radky
  url:=RegexReplace('#.*',url,'',false); // zabraneni dvojitym url pokud je v listingu vicekrat (www.neco.cz/odkazwww.neco.cz/odkaz)
  Result:=url;
end;

procedure PluginWork;
var
  s,url,ns,dx,mx,sx,ew,dy,my,sy,service:String;
  n:Integer;
begin
  if GC.IsSelected then begin // for cache
    if GC.HaveFinal then begin
      //ShowMessage(_('Warning: Corrected coordinates used!'));
      s:=FormatCoordNum(GC.CorrectedLatNum,GC.CorrectedLonNum);
    end
    else begin
      ShowMessage(_('Warning: No final waypoint found!'));
      s:='';
    end;
  end
  else begin // for waypoint
    for n := 0 to GC.Waypoints.Count - 1 do begin
      if GC.Waypoints[n].IsSelected then begin
        if GC.Waypoints[n].IsFinal then s:=FormatCoordNum(GC.Waypoints[n].LatNum,GC.Waypoints[n].LonNum)
        else ShowMessage(_('Error: Is not final!'));
      end;
    end;
  end;

  if s<>'' then begin
    {DX-stupne, MX-minuty, SX-vteriny, X & Y = Lat a Lon}
    //s:='N50°30.625' E015°29.620''';
    ns:=RegExSubstitute('(N|S)(\d+)°(\d+)\.(\d+)''\s(E|W)(\d+)°(\d+)\.(\d+)''',s,'$1'); // N
    dx:=RegExSubstitute('(N|S)(\d+)°(\d+)\.(\d+)''\s(E|W)(\d+)°(\d+)\.(\d+)''',s,'$2'); // 50
    mx:=RegExSubstitute('(N|S)(\d+)°(\d+)\.(\d+)''\s(E|W)(\d+)°(\d+)\.(\d+)''',s,'$3'); // 30
    sx:=RegExSubstitute('(N|S)(\d+)°(\d+)\.(\d+)''\s(E|W)(\d+)°(\d+)\.(\d+)''',s,'$4'); // 625
    ew:=RegExSubstitute('(N|S)(\d+)°(\d+)\.(\d+)''\s(E|W)(\d+)°(\d+)\.(\d+)''',s,'$5'); // E
    dy:=RegExSubstitute('(N|S)(\d+)°(\d+)\.(\d+)''\s(E|W)(\d+)°(\d+)\.(\d+)''',s,'$6'); // 015
    my:=RegExSubstitute('(N|S)(\d+)°(\d+)\.(\d+)''\s(E|W)(\d+)°(\d+)\.(\d+)''',s,'$7'); // 29
    sy:=RegExSubstitute('(N|S)(\d+)°(\d+)\.(\d+)''\s(E|W)(\d+)°(\d+)\.(\d+)''',s,'$8'); // 620

    {zjistit typ overovaci sluzby - geocheck.org, geochecker.com, evince.locusprime.net}
    if RegexFind('(https?://|www\.)(geocheck\.org|geotjek\.dk)\/geo_inputchkcoord([^"'']+)',GC.LongDescription) then begin
      url:=RegExSubstitute('(https?://|www\.)(geocheck\.org|geotjek\.dk)\/geo_inputchkcoord([^"'']+)',GC.LongDescription,'$0#'); // parsnout url z listingu, GC.LongDescription (konci '#')
      url:=TrimUrl(url);
      service:='geocheck';
      {
      captcha: ano
      url:
      form:
      }
    end
    else if RegexFind('(https?://|www\.)geochecker\.com\/index\.php([^"'']+)',GC.LongDescription) then begin
      url:=RegExSubstitute('(https?://|www\.)geochecker\.com\/index\.php([^"'']+)',GC.LongDescription,'$0#'); // parsnout url z listingu, GC.LongDescription (konci '#')
      url:=TrimUrl(url);
      service:='geochecker';
      {
      captcha: ano
      url:
      form:
      }
    end
    else if RegexFind('(https?://|www\.)evince\.locusprime\.net\/cgi-bin\/([^"'']+)',GC.LongDescription) then begin
      url:=RegExSubstitute('(https?://|www\.)evince\.locusprime\.net\/cgi-bin\/([^"'']+)',GC.LongDescription,'$0#'); // parsnout url z listingu, GC.LongDescription (konci '#')
      url:=TrimUrl(url);
      service:='evince';
      {
      captcha: ano
      url:
      form:
      }
    end
    else if RegexFind('(https?://|www\.)(geo\.hermansky\.net|speedygt\.ic\.cz\/gps)\/index\.php\?co\=checker([^"'']+)',GC.LongDescription) then begin
      url:=RegExSubstitute('(https?://|www\.)(geo\.hermansky\.net|speedygt\.ic\.cz\/gps)\/index\.php\?co\=checker([^"'']+)',GC.LongDescription,'$0#'); // parsnout url z listingu, GC.LongDescription (konci '#')
      url:=TrimUrl(url);
      service:='hermansky';
      {
      captcha: ne
      url: http://geo.hermansky.net/index.php?co=checker&code=2542e4245f80d4f7783e41ed7503fba6b3c8cc3188ff05
      form: &vyska=N&stupne21=50&minuty21=13.061&sirka=E&stupne22=014&minuty22=16.024
      }
    end
    else if RegexFind('(https?://|www\.)geo\.komurka\.cz\/check\.php([^"'']+)',GC.LongDescription) then begin
      url:=RegExSubstitute('(https?://|www\.)geo\.komurka\.cz\/check\.php([^"'']+)',GC.LongDescription,'$0#'); // parsnout url z listingu, GC.LongDescription (konci '#')
      url:=TrimUrl(url);
      service:='komurka';
      {
      captcha: ano
      url: http://geo.komurka.cz/check.php?cache=GC2JCEQ
      form: http://geo.komurka.cz/check.php?select1=N&sirka1=49&sirka2=02&sirka3=728&select2=E&delka1=014&delka2=06&delka3=635&code=DWUL&Submit=+Ov%EC%F8it+
      }
    end
    else if RegexFind('(https?://|www\.)gccounter\.(de|com)\/gcchecker\.php([^"'']+)',GC.LongDescription) then begin
      url:=RegExSubstitute('(https?://|www\.)gccounter\.(de|com)\/gcchecker\.php([^"'']+)',GC.LongDescription,'$0#'); // parsnout url z listingu, GC.LongDescription (konci '#')
      url:=TrimUrl(url);
      service:='gccounter';
      {
      captcha: ne
      url: http://gccounter.com/gcchecker.php?site=gcchecker_check&id=2076
      form: http://gccounter.com/gcchecker.php?site=gcchecker_check&id=2076&Lat_R=N&Lat_G=50&Lat_M=12&Lat_MM=345&Lon_R=E&Lon_G=12&Lon_M=33&Lon_MM=456
      }
    end
    else if RegexFind('(https?://|www\.)certitudes\.org\/certitude\?wp\=([^"'']+)',GC.LongDescription) then begin
      url:=RegExSubstitute('(https?://|www\.)certitudes\.org\/certitude\?wp\=([^"'']+)',GC.LongDescription,'$0#'); // parsnout url z listingu, GC.LongDescription (konci '#')
      url:=TrimUrl(url);
      service:='certitudes';
      {
      captcha: ne
      url: http://www.certitudes.org/certitude?wp=GC2QFYT
      form: http://www.certitudes.org/certify?waypoint=GC2QFYT&mapping=off&coordinates=N+50+09.800+E+014+08.169&anonymous=yes
      hacker poplach :)
      }
    end
    else begin
      ShowMessage('error: ani geocheck.org, ani geochecker.com, ani evince, ani hermansky!');
      GeoAbort;
    end;

    //ShowMessage(GEOGET_SCRIPTDIR+'\checker\checker.exe '+service+' '+ns+' '+dx+' '+mx+' '+sx+' '+ew+' '+dy+' '+my+' '+sy+' '+url);
    RunExec('"'+GEOGET_SCRIPTDIR+'\checker\AutoIt3.exe" "'+GEOGET_SCRIPTDIR+'\checker\checker.au3" '+service+' '+ns+' '+dx+' '+mx+' '+sx+' '+ew+' '+dy+' '+my+' '+sy+' '+url);
  end;
end;
