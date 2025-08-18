{
    GeoGet 2
    Installation script for GIP packages

    Www: https://www.geoget.cz/doku.php/user:skript:checker
    Forum: http://www.geocaching.cz/forum/viewthread.php?forum_id=20&thread_id=25822
    Author: mikrom, http://mikrom.cz
    Version: 4.0.1
}

{$include InstallTool.lib.pas}

{Safe delete file}
procedure DeleteFileIfExists(s: String);
begin
    s := GEOGET_SCRIPTDIR + '\Checker\' + s;
    if FileExists(s) then begin
        DeleteFile(s);
    end;
end;

{Safe delete INI value}
procedure DeleteIniValueIfExists(s, t: String);
var
    ini: TIniFile;
begin
    ini := TIniFile.Create(GEOGET_SCRIPTDIR + '\Checker\Checker.ini');
    try
        if ini.ValueExists(s, t) then begin
            ini.DeleteKey(s, t);
        end;
    finally
        ini.Free;
    end;
end;

{Do install tasks here}
function InstallWork: String;
begin
    {Changelog}
    if not GEOGET_SILENTINSTALL then begin
        if FileExists(GEOGET_SCRIPTDIR + '\Checker\Checker.changelog.txt') then begin
            ShowLongMessage(_('Changelog'), FileToString(GEOGET_SCRIPTDIR + '\Checker\Checker.changelog.txt'));
        end;
    end;

    {Clean up after upgrade to version 2.0.0}
    DeleteFileIfExists('AutoIt3.exe');
    DeleteFileIfExists('AutoItConstants.au3');
    DeleteFileIfExists('FileConstants.au3');
    DeleteFileIfExists('Checker.au3');
    DeleteFileIfExists('GUIConstantsEx.au3');
    DeleteFileIfExists('IE.au3');
    DeleteFileIfExists('WinAPIError.au3');
    DeleteFileIfExists('WindowsConstants.au3');

    {Clean up after upgrade to version 2.5.2}
    DeleteFileIfExists('finar.txt');

    {Clean up after upgrade to version 4.0.0}
    InstallTool_RemoveFile('AutoHotkey.exe', 'Checker');
    DeleteFileIfExists('AutoHotkeyU32.exe');
    DeleteIniValueIfExists('Checker', 'iefix');
    DeleteIniValueIfExists('Checker', 'certfix');
    DeleteIniValueIfExists('Checker', 'proxy');
    DeleteIniValueIfExists('Checker', 'pgclogin');

    {Clean up after upgrade to version 4.1.0}
    DeleteFileIfExists('lib\Checker\Services\Gccounter2.ahk');

    result := ''; // Ran without error
end;

{Do Uninstall tasks here}
function UninstallWork: String;
begin
    result := ''; // Ran without error
end;
