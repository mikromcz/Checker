{
    GeoGet 2
    Installation script for GIP packages

    Www: https://www.geoget.cz/doku.php/user:skript:checker
    Forum: http://www.geocaching.cz/forum/viewthread.php?forum_id=20&thread_id=25822
    Author: mikrom, http://mikrom.cz
    Version: 4.0.0
}

{$include InstallTool.lib.pas}

{Safe delete file.}
procedure DeleteIfExists(s: String)
begin
    if FileExists(s) then begin
        DeleteFile(s);
    end;
end;

{Do install tasks here.}
function InstallWork: String;
var
    ini: TIniFile;
begin
    {Changelog}
    if not GEOGET_SILENTINSTALL then begin
        if FileExists(GEOGET_SCRIPTDIR + '\Checker\Checker.changelog.txt') then begin
            ShowLongMessage(_('Changelog'), FileToString(GEOGET_SCRIPTDIR + '\Checker\Checker.changelog.txt'));
        end;
    end;

    {Clean up after upgrade to version 2.0.0}
    DeleteIfExists(GEOGET_SCRIPTDIR + '\Checker\AutoIt3.exe');
    DeleteIfExists(GEOGET_SCRIPTDIR + '\Checker\AutoItConstants.au3');
    DeleteIfExists(GEOGET_SCRIPTDIR + '\Checker\FileConstants.au3');
    DeleteIfExists(GEOGET_SCRIPTDIR + '\Checker\Checker.au3');
    DeleteIfExists(GEOGET_SCRIPTDIR + '\Checker\GUIConstantsEx.au3');
    DeleteIfExists(GEOGET_SCRIPTDIR + '\Checker\IE.au3');
    DeleteIfExists(GEOGET_SCRIPTDIR + '\Checker\WinAPIError.au3');
    DeleteIfExists(GEOGET_SCRIPTDIR + '\Checker\WindowsConstants.au3');

    {Clean up after upgrade to version 2.5.2}
    DeleteIfExists(GEOGET_SCRIPTDIR + '\Checker\finar.txt');

    {Clean up after upgrade to version 4.0.0}
    DeleteIfExists(GEOGET_SCRIPTDIR + '\Checker\AutoHotkeyU32.exe');

    result := ''; // Ran without error
end;

{Do Uninstall tasks here.}
function UninstallWork: string;
begin
    {Installtool}
    InstallTool_RemoveFile('AutoHotkey.exe', 'Checker');

    result := ''; // Ran without error
end;
