{
	Library of Function

  Www: http://geoget.ararat.cz/doku.php/user:skript:checker
  Forum: http://www.geocaching.cz/forum/viewthread.php?forum_id=20&thread_id=25822
  Author: mikrom, http://mikrom.cz
  Version: 0.1.2.0

  tohle by mohlo bejt zajimavy: http://www.regular-expressions.info/duplicatelines.html
}

{ocisteni url, nekdy se to z listingu vyparsuje blbe, tohle to celkem uspesne resi}
function TrimUrl(url:String):String;
begin
  url:=RegexReplace('\n.*',url,'',false); // nekdy je to na dva radky
  url:=RegexReplace('#.*',url,'',false); // zabraneni dvojitym url pokud je v listingu vicekrat (www.neco.cz/odkazwww.neco.cz/odkaz)
  result:=url;
end;

{oprava souradnic, nektere weby vyzaduji minuty jako dvojmistne cislo 2.123 => 02.123}
function CorrectCoords(coords:String):String;
begin
  {                      N      50     30    123    E      015    29    456            N 50  30 123 E 015 29 456}
  coords:=RegexReplace('(N|S)\s(\d+)\s(\d+)\s(\d+)\s(E|W)\s(\d+)\s(\d)\s(\d+)',coords,'$1 $2 $3 $4 $5 $6 0$7 $8',true); // pro lat
  result:=RegexReplace('(N|S)\s(\d+)\s(\d)\s(\d+)\s(E|W)\s(\d+)\s(\d+)\s(\d+)',coords,'$1 $2 0$3 $4 $5 $6 $7 $8',true); // pro lon
end;

{hlavni funkce. vpodstate jen propadavacka podle toho na co se narazi a nakonec se zavola autoit}
procedure Checker(runFrom:String);
var
  coord,url,service:String;
  n:Integer;
begin
  {zjistime zda bylo spusteno z GGP, nebo GGC skriptu}
  case runFrom of
    'ggp': if GC.IsSelected then // for cache
             coord:=FormatCoordNum(GC.CorrectedLatNum,GC.CorrectedLonNum)
           else begin // for waypoint
             for n:=0 to GC.Waypoints.Count-1 do begin
               if GC.Waypoints[n].IsSelected then coord:=FormatCoordNum(GC.Waypoints[n].LatNum,GC.Waypoints[n].LonNum);
             end;
           end;
    'ggc': coord:=FormatCoordNum(GC.CorrectedLatNum,GC.CorrectedLonNum);
  end;

  {pro jistotu zda jsou souradnice nenulove}
  if coord<>'' then begin
    {N50°30.123' E015°29.456' rozdelime na jednotlive sekce oddelene mezerami => N 50 30 123 E 015 29 456}
    coord:=RegexReplace('(N|S)(\d+)°(\d+)\.(\d+)''\s(E|W)(\d+)°(\d+)\.(\d+)''',coord,'$1 $2 $3 $4 $5 $6 $7 $8',true);

    {zjistit typ overovaci sluzby - geocheck.org, geochecker.com, evince.locusprime.net, atd..}
    if RegexFind('(https?://|www\.)(geocheck\.org|geotjek\.dk)\/geo_inputchkcoord([^"'']+)',GC.LongDescription) then begin
      url:=RegExSubstitute('(https?://|www\.)(geocheck\.org|geotjek\.dk)\/geo_inputchkcoord([^"'']+)',GC.LongDescription,'$0#'); // parsnout url z listingu, GC.LongDescription (konci '#')
      service:='geocheck';
      {
      url: geocheck.org/geo_inputchkcoord.php?gid=61241961c72ab1d-b813-47da-bf03-07c67bb81ac9
      captcha: ano
      }
    end
    else if RegexFind('(https?://|www\.)geochecker\.com\/index\.php([^"'']+)',GC.LongDescription) then begin
      url:=RegExSubstitute('(https?://|www\.)geochecker\.com\/index\.php([^"'']+)',GC.LongDescription,'$0#'); // parsnout url z listingu, GC.LongDescription (konci '#')
      service:='geochecker';
      {
      url: http://www.geochecker.com/index.php?code=e380cf72d82fa02a81bf71505e8c535c&action=check&wp=4743324457584d&name=536b6c656e696b202d20477265656e20486f757365
      captcha: ne
      }
    end
    else if RegexFind('(https?://|www\.)evince\.locusprime\.net\/cgi-bin\/([^"'']+)',GC.LongDescription) then begin
      url:=RegExSubstitute('(https?://|www\.)evince\.locusprime\.net\/cgi-bin\/([^"'']+)',GC.LongDescription,'$0#'); // parsnout url z listingu, GC.LongDescription (konci '#')
      service:='evince';
      {
      url: http://evince.locusprime.net/cgi-bin/index.cgi?q=d0ZNzQeHKReGKzr
      captcha: ano
      }
    end
    else if RegexFind('(https?://|www\.)(geo\.hermansky\.net|speedygt\.ic\.cz\/gps)\/index\.php\?co\=checker([^"'']+)',GC.LongDescription) then begin
      url:=RegExSubstitute('(https?://|www\.)(geo\.hermansky\.net|speedygt\.ic\.cz\/gps)\/index\.php\?co\=checker([^"'']+)',GC.LongDescription,'$0#'); // parsnout url z listingu, GC.LongDescription (konci '#')
      service:='hermansky';
      {
      url: http://geo.hermansky.net/index.php?co=checker&code=2542e4245f80d4f7783e41ed7503fba6b3c8cc3188ff05
      captcha: ne
      }
    end
    else if RegexFind('(https?://|www\.)geo\.komurka\.cz\/check\.php([^"'']+)',GC.LongDescription) then begin
      url:=RegExSubstitute('(https?://|www\.)geo\.komurka\.cz\/check\.php([^"'']+)',GC.LongDescription,'$0#'); // parsnout url z listingu, GC.LongDescription (konci '#')
      service:='komurka';
      {
      url: http://geo.komurka.cz/check.php?cache=GC2JCEQ
      captcha: ano
      }
    end
    else if RegexFind('(https?://|www\.)gccounter\.(de|com)\/gcchecker\.php([^"'']+)',GC.LongDescription) then begin
      url:=RegExSubstitute('(https?://|www\.)gccounter\.(de|com)\/gcchecker\.php([^"'']+)',GC.LongDescription,'$0#'); // parsnout url z listingu, GC.LongDescription (konci '#')
      service:='gccounter';
      {
      url: http://gccounter.com/gcchecker.php?site=gcchecker_check&id=2076
      captcha: ne
      }
    end
    else if RegexFind('(https?://|www\.)certitudes\.org\/certitude\?wp\=([^"'']+)',GC.LongDescription) then begin
      url:=RegExSubstitute('(https?://|www\.)certitudes\.org\/certitude\?wp\=([^"'']+)',GC.LongDescription,'$0#'); // parsnout url z listingu, GC.LongDescription (konci '#')
      service:='certitudes';
      {
      url: http://www.certitudes.org/certitude?wp=GC2QFYT
      captcha: ne
      }
    end
    else if FileExists(GEOGET_SCRIPTDIR+'\Checker\finar.txt') then begin
      {secret behavior}
      url:='http://gc.elanot.cz/index.php/data-final.html';
      service:='finar';
      {
      url: http://gc.elanot.cz/index.php/data-final.html?fabrik_list_filter_all_1_com_fabrik_1=N+49%C2%B0+06.864+E+017%C2%B0+46.694&limit1=10&limitstart1=0&option=com_fabrik&orderdir=&orderby=&view=list&listid=1&listref=1_com_fabrik_1&Itemid=112&fabrik_referrer=%2Findex.php%2Fdata-final.html%3Fresetfilters%3D0&735d56ae937921f2bb7c794d8ebfee41=1&format=html&packageId=0&task=list.filter&fabrik_listplugin_name=&fabrik_listplugin_renderOrder=&fabrik_listplugin_options=&incfilters=1
      captcha: ne
      }
    end
    else begin
      {standard behavior}
      ShowMessage(_('Error: No coordinate checker URL found!'));
      GeoAbort;
    end;

    //ShowMessage('"'+GEOGET_SCRIPTDIR+'\Checker\AutoIt3.exe" "'+GEOGET_SCRIPTDIR+'\Checker\Checker.au3" '+service+' '+CorrectCoords(coord)+' '+TrimUrl(url));
    RunExecNoWait('"'+GEOGET_SCRIPTDIR+'\Checker\AutoIt3.exe" "'+GEOGET_SCRIPTDIR+'\Checker\Checker.au3" '+service+' '+CorrectCoords(coord)+' '+TrimUrl(url));
  end;
end;
