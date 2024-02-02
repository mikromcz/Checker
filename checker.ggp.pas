{
	General Plugin Script
}
function PluginCaption: string;
begin
  Result:='checker';
end;

function PluginHint: string;
begin
  Result:='';
end;

function PluginIcon: string;
begin
  Result:=DecodeBase64('Qk02AwAAAAAAADYAAAAoAAAAEAAAABAAAAABABgAAAAAAAAAAADEDgAAxA4AAAAAAAAAAAAA////tKUR0cW5////tq9qtKURtKURT6HqT6HqwtrE////ecLZT6HqT6Hq9Pb2////tKURtKURwtrE////0cW5tKURloN/VjEhloN/9Pb2////m+b5T6HqT6Hq9Pb2////tKURtq9qtKURtq9qtKURloN/VjEhh21TVjEhloN/T6HqT6HqT6HqT6Hq9Pb2wtrE9Pb29Pb2tKURtKURtKURloN/VjEhVjEhVjEhloN/T6HqT6HqT6HqT6HqT6HqT6Hq0cW50cW5tKURtKURtKURtKUR0cW5VjEhecLZT6HqT6HqT6HqT6HqT6Hqm+b5m+b5tKURtKURtKURtKURtKURtKURVjEhVjEhloN/T6HqT6HqT6HqT6HqT6Hq9Pb2////tq9qtKURtKURtKURabJFtKUR0cW5VjEhVjEhT6HqT6HqT6HqT6HqT6Hq9Pb2////T/D5GfD5abJFtKURTMCOGfD5GfD5VjEhVjEhVjEhT6HqabJFabJFabJF9Pb2////GfD5GfD5abJFtKURtq9qh21TVjEhabJFh21TVjEhVjEhTMCOabJFabJF9Pb2////T/D5m+b5GfD5tq9qVjEhVjEhh21T0cW5abJFVjEhVjEhh21TabJFabJFwtrEwtrE9Pb29Pb2T/D5h21TVjEhh21TVjEhGfD5GfD5VjEhVjEhh21TabJFabJFabJFabJFecLZecLZGfD5h21TVjEhVjEh0cW5tq9qloN/VjEhVjEhtq9qabJFabJFwtrEwtrEGfD5GfD5GfD5loN/VjEhVjEhVjEhVjEhVjEhVjEhtq9qVjEhabJFabJF9Pb2////m+b5m+b5T/D5GfD5VjEhVjEhVjEhVjEhVjEhh21TVjEhwtrEwtrEwtrE9Pb2////////////T/D5GfD5wtrEloN/VjEhVjEhVjEhloN/abJFwtrE////////////////////////m+b5GfD5m+b5////////////9Pb2wtrEabJFwtrE////////////////');
end;

function PluginFlags: string;
begin
  Result:='';
end;

function WGStoDMS(coord:Extended):String;
var
  D,M:Integer;
  S:String;
begin
  {nakouskovat souradnice (50.41327 16.20013 => N50°24.796' E016°12.008')}
  // Conversion from Decimal Degree to DMS
  // 1. Subtract the whole number portion of the coordinate, leaving the fractional part. The whole number is the number of degrees. 87.728055 = 87 degrees.
  // 2. Multiply the remaining fractional part by 60. This will produce a number of minutes in the whole number portion. 0.728055 x 60 = 43.6833 = 43 minutes.
  // 3. Multiply the fractional part of the number of minutes by 60, producing a number of seconds. 0.6833 x 60 = 40.998 = 41 seconds.
  //    It is possible to count this as 40 seconds, truncating the decimal, round it to 41, or keep the entire number.
  D:=Trunc(coord); // 50.41327 => 50
  M:=Trunc((coord-D)*60); //Trunc(Frac(coord)*60); // 50.41327 => 0.41327 * 60 = 24,7962
  S:=SeparateRight(FormatFloat('0.###',(coord-D)*60),','); // 24,7962 => 796
  Result:=IntToStr(D)+'°'+IntToStr(M)+'.'+S;
end;

procedure PluginWork;
var
  s,url,DX,MX,SX,DY,MY,SY,param:String;
  //n:Integer;
begin
  //for n := 0 to GC.Waypoints.Count - 1 do begin
    //if true then begin //GC.Waypoints[n].IsSelected then begin
      //if true then begin //GC.Waypoints[n].IsFinal then begin

        {WGS->DMS}
        // DX-stupne, MX-minuty, SX-vteriny, X a Y = Lat a Lon
        s:=WGStoDMS(GC.CorrectedLatNum);
        DX:=SeparateLeft(s,'°');
        MX:=SeparateLeft(SeparateRight(s,'°'),'.');
        SX:=SeparateRight(s,'.');
        s:=WGStoDMS(GC.CorrectedLonNum);
        DY:=SeparateLeft(s,'°');
        MY:=SeparateLeft(SeparateRight(s,'°'),'.');
        SY:=SeparateRight(s,'.');

        {zjistit typ overovaci sluzby - geocheck.org, geochecker.com, evince.locusprime.net}
        if RegexFind('http\:\/\/geocheck\.org\/geo\_inputchkcoord\.php\?gid\=[a-z0-9\-]+',GC.LongDescription) then begin
          {parsnout url z listingu, GC.LongDescription}
          url:=RegExSubstitute('http\:\/\/geocheck\.org\/geo\_inputchkcoord\.php\?gid\=[a-z0-9\-]+',GC.LongDescription,'$0');
          {otevrit url}
          RunShell(url);
          {nez se nacte stranka}
          Sleep(5000);
          {spustit pres runshell exac}
          param:='-d -w "GeoCheck - " {TAB}{TAB}{TAB}{TAB}{TAB}{TAB}{TAB}{TAB}{TAB}{TAB}{TAB}{TAB}{TAB}{TAB}{TAB}{TAB}{TAB}{TAB}{TAB}{TAB}{TAB}{TAB}{TAB}{TAB}{TAB}{TAB}{TAB}{TAB}{TAB}{TAB}{TAB}{TAB}{TAB}{TAB}{TAB}{TAB}{TAB}{TAB}'+DX+'{TAB}'+MX+'{TAB}'+SX+'{TAB}{TAB}'+DY+'{TAB}'+MY+'{TAB}'+SY+'{TAB}{TAB}';
          RunExec(GEOGET_SCRIPTDIR+'\checker\WinSendKeys\WinSendKeys.exe '+param);
        end
        else if RegexFind('http\:\/\/www\.geochecker\.com\/[a-z0-9\-\=\&\;\?\.]+',GC.LongDescription) then begin
          {parsnout url z listingu, GC.LongDescription}
          url:=RegExSubstitute('http\:\/\/www\.geochecker\.com\/[a-z0-9\-\=\&\;\?\.]+',GC.LongDescription,'$0');
          {otevrit url}
          RunShell(url);
          {nez se nacte stranka}
          Sleep(5000);
          {spustit pres runshell exac}
          param:='-d -w "GeoChecker link for " {TAB}{TAB}{TAB}{TAB}{TAB}{TAB}{TAB}{TAB}{TAB}{TAB}{TAB}{TAB}{TAB}{TAB}{TAB}{TAB}{TAB}N{SPACE}'+DX+'{SPACE}'+MX+'.'+SX+'{TAB}E{SPACE}'+DY+'{SPACE}'+MY+'.'+SY+'{TAB}{TAB}';
          RunExec(GEOGET_SCRIPTDIR+'\checker\WinSendKeys\WinSendKeys.exe '+param);
        end
        else if RegexFind('http\:\/\/evince\.locusprime\.net\/cgi\-bin\/[a-zA-Z0-9\-\=\&\;\?\.\/]+',GC.LongDescription) then begin
          {parsnout url z listingu, GC.LongDescription}
          url:=RegExSubstitute('http\:\/\/evince\.locusprime\.net\/cgi\-bin\/[a-zA-Z0-9\-\=\&\;\?\.\/]+',GC.LongDescription,'$0');
          {otevrit url}
          RunShell(url);
          {nez se nacte stranka}
          Sleep(5000);
          {spustit pres runshell exac}
          param:='-d -w "evince - " '+DX+'{TAB}'+MX+'.'+SX+'{TAB}{TAB}E{TAB}'+DY+'{TAB}'+MY+'.'+SY+'{TAB}{TAB}{TAB}{TAB}';
          RunExec(GEOGET_SCRIPTDIR+'\checker\WinSendKeys\WinSendKeys.exe '+param);
        end
        else ShowMessage('error: ani geocheck.org, ani geochecker.com, ani evince!');
      //end
      //else ShowMessage('error: is not final!');
    //end
    //else ShowMessage('error: is not selected!');
  //end;
end;
