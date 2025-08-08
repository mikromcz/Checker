{
    GeoGet 2
    General Plugin Script

    Www: https://www.geoget.cz/doku.php/user:skript:checker
    Forum: http://www.geocaching.cz/forum/viewthread.php?forum_id=20&thread_id=25822
    Icon: https://icons8.com/icon/18401/Thumb-Up
    Author: mikrom, https://www.mikrom.cz
    Version: 4.0.0
}

{$include Checker.lib.pas}

{Name of plugin}
function PluginCaption: String;
begin
    result := 'Checker';
end;

{What will be displayed as hint?}
function PluginHint: String;
begin
    result := _('Open and fill checker page (geocheck.org, geochecker.com, evince.locusprime.net, etc.)');
end;

{Icon data}
function PluginIcon: String;
begin
    result := DecodeBase64('iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAZdEVYdFNvZnR3YXJlAHBhaW50Lm5ldCA0LjAuMTZEaa/1AAABcUlEQVQ4T5WSPUsDQRCGNxYRBWvFUrG0ELSzshC0sbGxMZamsIgQC4PZjUU+EIRgjEpUrES0NF1QIkLUu1MQVMTSPxBtlHzcjHPe7hE0mrsXXg5mZ56d2RvWSnDLh8Hgh6jxPhnyJtBFGg2BaPADGXIvKIU66PZXCTiWYXdCRB8VJe1igaBFt+SRO4HO58ngAHQ+K49+aCPVyzbj444zyVFKngZD1FSxBOStMZRptCgib2MsmwyQUbk7F38zdVFpLP7LoK0O/QIM7CeaJivD9QqapWXrTc7xgfs9A6qFENYvlmgkUSZAj2eAMr1RBfRIvycAtY2fp0GsFsN16iBo/wUJ8O+soS+bcvUG319dXDmArtw67j7d42T+pGUHZimCphZ9xxs+5wCs2xcuCzh4tPcvoFYMY/Vs0dqJD7iLjdiATHyGZRNl5c7txCMtyXMzgDK1D6DFJmwAYz7GaaMaDC/pdtBjU5QYaGqDjyFSHWPsC1y1CoZb0Ad8AAAAAElFTkSuQmCC');
end;

{How Geoget can handle this plugin?}
function PluginFlags: String;
begin
    result := '';
end;

{Enter plugin code here}
procedure PluginWork;
begin
    //{$ifdef DEBUG_HELPER} LDHInit(true); {$endif}
    Checker('ggp');
end;
