{
  GeoGet 2
  Installation script for GIP packages
  
  Www: http://geoget.ararat.cz/doku.php/user:skript:checker
  Forum: http://www.geocaching.cz/forum/viewthread.php?forum_id=20&thread_id=25822
  Author: mikrom, http://mikrom.cz
  Version: 0.2.8.0
}

{$include InstallTool.lib.pas}

{Do install tasks here.}
function InstallWork: string;
var
  ini:TIniFile;
begin
  {changelog}
  if FileExists(GEOGET_SCRIPTDIR+'\Checker\Checker.changelog.txt') then ShowLongMessage(_('Changelog'), FileToString(GEOGET_SCRIPTDIR + '\Checker\Checker.changelog.txt'));

  {clean after upgrade to version 0.2.0.0}
  if FileExists(GEOGET_SCRIPTDIR+'\Checker\AutoIt3.exe') then DeleteFile(GEOGET_SCRIPTDIR+'\Checker\AutoIt3.exe');
  if FileExists(GEOGET_SCRIPTDIR+'\Checker\AutoItConstants.au3') then DeleteFile(GEOGET_SCRIPTDIR+'\Checker\AutoItConstants.au3');
  if FileExists(GEOGET_SCRIPTDIR+'\Checker\FileConstants.au3') then DeleteFile(GEOGET_SCRIPTDIR+'\Checker\FileConstants.au3');
  if FileExists(GEOGET_SCRIPTDIR+'\Checker\Checker.au3') then DeleteFile(GEOGET_SCRIPTDIR+'\Checker\Checker.au3');
  if FileExists(GEOGET_SCRIPTDIR+'\Checker\GUIConstantsEx.au3') then DeleteFile(GEOGET_SCRIPTDIR+'\Checker\GUIConstantsEx.au3');
  if FileExists(GEOGET_SCRIPTDIR+'\Checker\IE.au3') then DeleteFile(GEOGET_SCRIPTDIR+'\Checker\IE.au3');
  if FileExists(GEOGET_SCRIPTDIR+'\Checker\WinAPIError.au3') then DeleteFile(GEOGET_SCRIPTDIR+'\Checker\WinAPIError.au3');
  if FileExists(GEOGET_SCRIPTDIR+'\Checker\WindowsConstants.au3') then DeleteFile(GEOGET_SCRIPTDIR+'\Checker\WindowsConstants.au3');

  {delete finar.txt}
  if FileExists(GEOGET_SCRIPTDIR+'\Checker\finar.txt') then DeleteFile(GEOGET_SCRIPTDIR+'\Checker\finar.txt');
  
  ini := TIniFile.Create(GEOGET_SCRIPTDIR+'\Checker\Checker.ini');
  try
    {delete key finar from ini}
    if ini.ValueExists('Checker', 'finar') then ini.DeleteKey('Checker', 'finar');
  
    {if there is no iefix better set it to true}
    if not ini.ValueExists('Checker', 'iefix') then ini.WriteBool('Checker', 'iefix', True);
  finally
    ini.Free;
  end;
  
  {installtool}
  InstallTool_MoveFile(GEOGET_SCRIPTDIR+'\Checker\AutoHotKey.exe', 'Checker');
  
  result := '';  // run without error
end;

{Do Uninstall tasks here.}
function UninstallWork: string;
begin
  {installtool}
  InstallTool_RemoveFile('AutoHotkey.exe', 'Checker');
  
  result := '';  // run without error
end;
