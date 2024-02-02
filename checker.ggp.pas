{
  GeoGet 2
  General Plugin Script

  Www: http://geoget.ararat.cz/doku.php/user:skript:checker
  Forum: http://www.geocaching.cz/forum/viewthread.php?forum_id=20&thread_id=25822
  Icon: https://icons8.com/icon/18401/Thumb-Up
  Author: mikrom, https://www.mikrom.cz
  Version: 2.14.0
}

{$INCLUDE Checker.lib.pas}

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
  //result := DecodeBase64('iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAn5JREFUeNqUU01oU0EQns1LXvKatwmJ1dZQCzU9WLw1JaI9Kb0piAiNf0XqofQggj83KYKmB08eBD0UCx4s9eBBLxqllpJDkSBYG7GUBIKSggQT0/z0mff2rbPpa0hSFBz42JndmW9mdmdJ7LIdNB1gy+AgxK8QaJOQySHCONiYyZ+jntg5OP3MALtQFAeAWybATADOW4L9aEaO33o8WcptlOJP7sq8iUCIvcWQACQsQDMaW5d6QiODnBGqeDqJYYBkWglUJ9lN0CbXJJd6uO/oqbAw0omF5G8GnwRBl0rAaYd/EtSDj01Mnydgp4auldeWF9ZqjMcO+m3w1xYsmaQeGhwcnz5HbDItfkt+eT03m6KkontdZArPf1l+7xBviXgF0Y2NQIAQOONQ6MDQlegYcnuEl+x2gyTLu7K8j154cGJWvyEqGBI3jSXTroFw8ED45BFmAAXYvsmtYhHcPh9UCoVG8OZGKmuYwOot6IxfDI3eHFW7+wI1TYNqRQOG180YAxPhdLnARWl9b/7+9Rc7JFj1qzqBwYC69/YGKpjJ0HXQa7UWUK8XfLivqCqM35s5W87nyvGZ209LNYjXCWomOBg6mAKYpQ7MzM3tqRK6OM98XS3E5h4lrOyNSmzYgiwcDFF2UzDHYDEzQhfkvf2HfJGrU8P7VJJVZLLYIVuDhP+A576nf3o6A3sM4WyhUQGuIsHSm5fZlQ9LWQybb34NaSQI+VTyY0/+R7Za3sxXK8VCFfdNQvBhCdjwEkmHooDH65Mzq8ufTSBRCY8EhsfugB1Hc1HT+UomvR6E9Ho/2vuRIIDoRvisYRMzUcU5eSgKb/5vhLd9v/+VPwIMAHaYM3koihLpAAAAAElFTkSuQmCC');
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
  Checker('ggp');
end;
