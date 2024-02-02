{
    GeoGet 2
    Installation script for GIP packages
    
    Www: https://www.geoget.cz/doku.php/user:skript:checker
    Forum: http://www.geocaching.cz/forum/viewthread.php?forum_id=20&thread_id=25822
    Author: mikrom, http://mikrom.cz
    Version: 2.22.0
}

{$include InstallTool.lib.pas}

{Do install tasks here.}
function InstallWork: String;
var
    ini: TIniFile;
begin
    {changelog}
    if not GEOGET_SILENTINSTALL then begin
        if FileExists(GEOGET_SCRIPTDIR + '\Checker\Checker.changelog.txt') then begin
            ShowLongMessage(_('Changelog'), FileToString(GEOGET_SCRIPTDIR + '\Checker\Checker.changelog.txt'));
        end;
    end;
    
    {clean after upgrade to version 0.2.0.0}
    if FileExists(GEOGET_SCRIPTDIR + '\Checker\AutoIt3.exe') then begin
        DeleteFile(GEOGET_SCRIPTDIR + '\Checker\AutoIt3.exe');
    end;
    
    if FileExists(GEOGET_SCRIPTDIR + '\Checker\AutoItConstants.au3') then begin
        DeleteFile(GEOGET_SCRIPTDIR + '\Checker\AutoItConstants.au3');
    end;
    
    if FileExists(GEOGET_SCRIPTDIR + '\Checker\FileConstants.au3') then begin
        DeleteFile(GEOGET_SCRIPTDIR + '\Checker\FileConstants.au3');
    end;
    
    if FileExists(GEOGET_SCRIPTDIR + '\Checker\Checker.au3') then begin 
        DeleteFile(GEOGET_SCRIPTDIR + '\Checker\Checker.au3');
    end;
    
    if FileExists(GEOGET_SCRIPTDIR + '\Checker\GUIConstantsEx.au3') then begin
        DeleteFile(GEOGET_SCRIPTDIR + '\Checker\GUIConstantsEx.au3');
    end;
    
    if FileExists(GEOGET_SCRIPTDIR + '\Checker\IE.au3') then begin
        DeleteFile(GEOGET_SCRIPTDIR + '\Checker\IE.au3');
    end;
    
    if FileExists(GEOGET_SCRIPTDIR + '\Checker\WinAPIError.au3') then begin
        DeleteFile(GEOGET_SCRIPTDIR + '\Checker\WinAPIError.au3');
    end;
    
    if FileExists(GEOGET_SCRIPTDIR + '\Checker\WindowsConstants.au3') then begin
        DeleteFile(GEOGET_SCRIPTDIR + '\Checker\WindowsConstants.au3');
    end;
    
    {delete finar.txt}
    if FileExists(GEOGET_SCRIPTDIR + '\Checker\finar.txt') then begin
        DeleteFile(GEOGET_SCRIPTDIR + '\Checker\finar.txt');
    end;
    
    ini := TIniFile.Create(GEOGET_SCRIPTDIR + '\Checker\Checker.ini');
    try
        {delete key finar from ini}
        if ini.ValueExists('Checker', 'finar') then begin
            ini.DeleteKey('Checker', 'finar');
        end;
        
        {if there is no iefix better set it to true}
        if not ini.ValueExists('Checker', 'iefix') then begin
            ini.WriteBool('Checker', 'iefix', True);
        end;
        
        {add beep option}
        if not ini.ValueExists('Checker', 'beep') then begin
            ini.WriteBool('Checker', 'beep', True);
        end;
        
        {add copy to clipboard option}
        if not ini.ValueExists('Checker', 'copymsg') then begin
            ini.WriteBool('Checker', 'copymsg', True);
        end;
        
    finally
        ini.Free;
    end;
    
    {installtool}
    InstallTool_MoveFile(GEOGET_SCRIPTDIR + '\Checker\AutoHotKey.exe', 'Checker');
    
    result := ''; // Run without error
end;

{Do Uninstall tasks here.}
function UninstallWork: string;
begin
    {installtool}
    InstallTool_RemoveFile('AutoHotkey.exe', 'Checker');
    
    result := ''; // Run without error
end;
