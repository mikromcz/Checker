{
  GeoGet 2
  Installation script for GIP packages
  
  Www: http://geoget.ararat.cz/doku.php/user:skript:checker
  Forum: http://www.geocaching.cz/forum/viewthread.php?forum_id=20&thread_id=25822
  Author: mikrom, http://mikrom.cz
  Version: 0.1.0.3
}

{Do install tasks here.}
function InstallWork: string;
begin
  {changelog}
  if FileExists(GEOGET_SCRIPTDIR + '\Checker\Checker.changelog.txt') then ShowLongMessage(_('Changelog'), FileToString(GEOGET_SCRIPTDIR + '\Checker\Checker.changelog.txt'));

  result := '';  // probehlo bez chyby
end;

{Do Uninstall tasks here.}
function UninstallWork: string;
begin
  result := '';
end;
