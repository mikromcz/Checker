{
	General Plugin Script
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
  Result:=DecodeBase64('Qk02AwAAAAAAADYAAAAoAAAAEAAAABAAAAABABgAAAAAAAAAAADEDgAAxA4AAAAAAAAAAAAA////tKUR0cW5////tq9qtKURtKURT6HqT6HqwtrE////ecLZT6HqT6Hq9Pb2////tKURtKURwtrE////0cW5tKURloN/VjEhloN/9Pb2////m+b5T6HqT6Hq9Pb2////tKURtq9qtKURtq9qtKURloN/VjEhh21TVjEhloN/T6HqT6HqT6HqT6Hq9Pb2wtrE9Pb29Pb2tKURtKURtKURloN/VjEhVjEhVjEhloN/T6HqT6HqT6HqT6HqT6HqT6Hq0cW50cW5tKURtKURtKURtKUR0cW5VjEhecLZT6HqT6HqT6HqT6HqT6Hqm+b5m+b5tKURtKURtKURtKURtKURtKURVjEhVjEhloN/T6HqT6HqT6HqT6HqT6Hq9Pb2////tq9qtKURtKURtKURabJFtKUR0cW5VjEhVjEhT6HqT6HqT6HqT6HqT6Hq9Pb2////T/D5GfD5abJFtKURTMCOGfD5GfD5VjEhVjEhVjEhT6HqabJFabJFabJF9Pb2////GfD5GfD5abJFtKURtq9qh21TVjEhabJFh21TVjEhVjEhTMCOabJFabJF9Pb2////T/D5m+b5GfD5tq9qVjEhVjEhh21T0cW5abJFVjEhVjEhh21TabJFabJFwtrEwtrE9Pb29Pb2T/D5h21TVjEhh21TVjEhGfD5GfD5VjEhVjEhh21TabJFabJFabJFabJFecLZecLZGfD5h21TVjEhVjEh0cW5tq9qloN/VjEhVjEhtq9qabJFabJFwtrEwtrEGfD5GfD5GfD5loN/VjEhVjEhVjEhVjEhVjEhVjEhtq9qVjEhabJFabJF9Pb2////m+b5m+b5T/D5GfD5VjEhVjEhVjEhVjEhVjEhh21TVjEhwtrEwtrEwtrE9Pb2////////////T/D5GfD5wtrEloN/VjEhVjEhVjEhloN/abJFwtrE////////////////////////m+b5GfD5m+b5////////////9Pb2wtrEabJFwtrE////////////////');
end;

function PluginFlags: string;
begin
  Result:='';
end;

procedure PluginWork;
var
  s,url,ns,dx,mx,sx,ew,dy,my,sy,service:String;
  //n:Integer;
begin
  //for n := 0 to GC.Waypoints.Count - 1 do begin
    //if GC.Waypoints[n].IsSelected then begin
      //if GC.Waypoints[n].IsFinal then begin
//showmessage(GC.Waypoints[n].Name);
        {DX-stupne, MX-minuty, SX-vteriny, X & Y = Lat a Lon}
        s:=FormatCoordNum(GC.CorrectedLatNum,GC.CorrectedLonNum); // N50°30.625' E015°29.620'
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
          {parsnout url z listingu, GC.LongDescription}
          url:=RegExSubstitute('(https?://|www\.)geocheck.org/geo_inputchkcoord([^"]+)',GC.LongDescription,'$0');
          service:='geocheck';
        end
        else if RegexFind('(https?://|www\.)geochecker.com([^"]+)',GC.LongDescription) then begin
          {parsnout url z listingu, GC.LongDescription}
          url:=RegExSubstitute('(https?://|www\.)geochecker.com([^"]+)',GC.LongDescription,'$0');
          service:='geochecker';
        end
        else if RegexFind('(https?://|www\.)evince.locusprime.net/cgi-bin/([^"]+)',GC.LongDescription) then begin
          {parsnout url z listingu, GC.LongDescription}
          url:=RegExSubstitute('(https?://|www\.)evince.locusprime.net/cgi-bin/([^"]+)',GC.LongDescription,'$0');
          service:='evince';
        end
        else ShowMessage('error: ani geocheck.org, ani geochecker.com, ani evince!');

        //ShowMessage(GEOGET_SCRIPTDIR+'\checker\checker.exe '+service+' '+ns+' '+dx+' '+mx+' '+sx+' '+ew+' '+dy+' '+my+' '+sy+' '+url);
        RunExec(GEOGET_SCRIPTDIR+'\checker\AutoIt3.exe '+GEOGET_SCRIPTDIR+'\checker\checker.au3 '+service+' '+ns+' '+dx+' '+mx+' '+sx+' '+ew+' '+dy+' '+my+' '+sy+' '+url);

      //end
      //else ShowMessage('error: is not final!');
    //end
    //else ShowMessage('error: is not selected!');
  //end;
end;
