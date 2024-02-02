{
	General Plugin Script
  author: mikrom, http://mikrom.cz
  web: -
}

function PluginCaption: string;
begin
  Result:='checker';
end;

function PluginHint: string;
begin
  Result:='open and fill checker page (geocheck.org, geochecker.com, evince.locusprime.net)';
end;

function PluginIcon: string;
begin
  Result:=DecodeBase64('Qk02AwAAAAAAADYAAAAoAAAAEAAAABAAAAABABgAAAAAAAAAAADEDgAAxA4AAAAAAAAAAAAA3AD/3AD/3AD/3AD/3AD/3AD/3AD/3AD/3AD/3AD/3AD/3AD/3AD/3AD/3AD/3AD/3AD/7fH2ytjmpr3VjarIc5e8W4axSnmpRnanOGygQnOlusze3AD/3AD/3AD/3AD/vtDjTX+xT4S4V43AW4/EZZjMaZvPaJvOdajair3veazfTX+x3AD/3AD/3AD/3AD/Woy/cqfZgbTleazedKfZcKPVbJ/SaZzPc6bYjsHxU4e6Nmqducvd3AD/3AD/3AD/WY/Eir3sf7Lie67fdqnbcqXXbqHTap3Pdajak8b0k8b0g7fnYpXH3AD/3AD/3AD/X5TJj8Lvg7bmf7LieazddKfYb6LUap3Qd6rbmMv2dKjYRnqtRnqtvtDi3AD/3AD/ZJnOlMfyiLvog7bkfbDfd6racaTVa57Qeq3dndD5ndD5ndD5jcHtbJ7R3AD/3AD/caPUg7npl8rzj8LtibzphbjmgrXjf7Lhh7rootX7kcTwVIa5VIa5VIa5wtTm3AD/y97wdqfYcKTYd67glsnzlcjzlcjzlcjzlcjzptn+lcjzlcjzlcjzgLbndqfY3AD/3AD/3AD/5e74lbzjdKjbms72mcz2mcz2pNf8qt3/qt3/qt3/qt3/qt3/c6fa3AD/3AD/3AD/3AD/3AD/mL7ld6vem8/3nM/4iL7sWIu9ZprNZZnNdqncdqncutPt3AD/3AD/3AD/3AD/3AD/3AD/krngb6PWms71mcz2mcz0aZnK4erz3AD/3AD/3AD/3AD/3AD/3AD/3AD/3AD/3AD/3AD/krngb6PWmcz1nM/4d63bm7ra3AD/3AD/3AD/3AD/3AD/3AD/3AD/3AD/3AD/3AD/3AD/krngeK3fnM/4mc31a5zN3AD/3AD/3AD/3AD/3AD/3AD/3AD/3AD/3AD/3AD/3AD/7fP6d6fYoNT5jcPtbqDR3AD/3AD/3AD/3AD/3AD/3AD/3AD/3AD/3AD/3AD/3AD/3AD/zN/xd6fYdabWytzu3AD/3AD/3AD/3AD/');
end;

function PluginFlags: string;
begin
  Result:='';
end;

procedure PluginWork;
var
  s,url,ns,dx,mx,sx,ew,dy,my,sy,service:String;
  n:Integer;
begin
  if GC.IsSelected then begin // pro kes
    ShowMessage('warning: corrected coordinates used!');
    s:=FormatCoordNum(GC.CorrectedLatNum,GC.CorrectedLonNum);
  end
  else begin // pro waypoint
    for n := 0 to GC.Waypoints.Count - 1 do begin
      if GC.Waypoints[n].IsSelected then begin
        if GC.Waypoints[n].IsFinal then s:=FormatCoordNum(GC.Waypoints[n].LatNum,GC.Waypoints[n].LonNum)
        else ShowMessage('error: is not final!');
      end;
    end;
  end;

  if s<>'' then begin
    {DX-stupne, MX-minuty, SX-vteriny, X & Y = Lat a Lon}
    // s:='N50°30.625' E015°29.620''';
    ns:=RegExSubstitute('(N|S)(\d+)°(\d+)\.(\d+)''\s(E|W)(\d+)°(\d+)\.(\d+)''',s,'$1'); // N
    dx:=RegExSubstitute('(N|S)(\d+)°(\d+)\.(\d+)''\s(E|W)(\d+)°(\d+)\.(\d+)''',s,'$2'); // 50
    mx:=RegExSubstitute('(N|S)(\d+)°(\d+)\.(\d+)''\s(E|W)(\d+)°(\d+)\.(\d+)''',s,'$3'); // 30
    sx:=RegExSubstitute('(N|S)(\d+)°(\d+)\.(\d+)''\s(E|W)(\d+)°(\d+)\.(\d+)''',s,'$4'); // 625
    ew:=RegExSubstitute('(N|S)(\d+)°(\d+)\.(\d+)''\s(E|W)(\d+)°(\d+)\.(\d+)''',s,'$5'); // E
    dy:=RegExSubstitute('(N|S)(\d+)°(\d+)\.(\d+)''\s(E|W)(\d+)°(\d+)\.(\d+)''',s,'$6'); // 015
    my:=RegExSubstitute('(N|S)(\d+)°(\d+)\.(\d+)''\s(E|W)(\d+)°(\d+)\.(\d+)''',s,'$7'); // 29
    sy:=RegExSubstitute('(N|S)(\d+)°(\d+)\.(\d+)''\s(E|W)(\d+)°(\d+)\.(\d+)''',s,'$8'); // 620

    {zjistit typ overovaci sluzby - geocheck.org, geochecker.com, evince.locusprime.net}
    if RegexFind('(https?://|www\.)geocheck.org/geo_inputchkcoord([^"]+)',GC.LongDescription) then begin
      url:=RegExSubstitute('(https?://|www\.)geocheck.org/geo_inputchkcoord([^"]+)',GC.LongDescription,'$0#'); // parsnout url z listingu, GC.LongDescription (konci '#')
      url:=RegexReplace('#.*',url,'',false); // zabraneni dvojitym url pokud je v listingu vicekrat (www.neco.cz/odkazwww.neco.cz/odkaz)
      service:='geocheck';
    end
    else if RegexFind('(https?://|www\.)geochecker.com([^"]+)',GC.LongDescription) then begin
      url:=RegExSubstitute('(https?://|www\.)geochecker.com([^"]+)',GC.LongDescription,'$0#'); // parsnout url z listingu, GC.LongDescription (konci '#')
      url:=RegexReplace('#.*',url,'',false); // zabraneni dvojitym url pokud je v listingu vicekrat (www.neco.cz/odkazwww.neco.cz/odkaz)
      service:='geochecker';
    end
    else if RegexFind('(https?://|www\.)evince.locusprime.net/cgi-bin/([^"]+)',GC.LongDescription) then begin
      url:=RegExSubstitute('(https?://|www\.)evince.locusprime.net/cgi-bin/([^"]+)',GC.LongDescription,'$0#'); // parsnout url z listingu, GC.LongDescription (konci '#')
      url:=RegexReplace('#.*',url,'',false); // zabraneni dvojitym url pokud je v listingu vicekrat (www.neco.cz/odkazwww.neco.cz/odkaz)
      service:='evince';
    end
    else ShowMessage('error: ani geocheck.org, ani geochecker.com, ani evince!');

    //ShowMessage(GEOGET_SCRIPTDIR+'\checker\checker.exe '+service+' '+ns+' '+dx+' '+mx+' '+sx+' '+ew+' '+dy+' '+my+' '+sy+' '+url);
    RunExec(GEOGET_SCRIPTDIR+'\checker\AutoIt3.exe '+GEOGET_SCRIPTDIR+'\checker\checker.au3 '+service+' '+ns+' '+dx+' '+mx+' '+sx+' '+ew+' '+dy+' '+my+' '+sy+' '+url);
  end;
end;
