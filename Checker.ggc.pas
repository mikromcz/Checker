{
  Cache listing Plugin Script

  Www: http://geoget.ararat.cz/doku.php/user:skript:checker
  Forum: http://www.geocaching.cz/forum/viewthread.php?forum_id=20&thread_id=25822
  Author: mikrom, http://mikrom.cz
  Version: 0.1.0.2
}

{$INCLUDE Checker.lib.pas}

{Name of plugin}
function PluginCaption: string;
begin
  result := ' ';
end;

{What will be displayed as hint?}
function PluginHint: string;
begin
  result := _('Open and fill checker page (geocheck.org, geochecker.com, evince.locusprime.net, etc.)');
end;

{Icon data}
function PluginIcon: string;
begin
  result := DecodeBase64('iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAn5JREFUeNqUU01oU0EQns1LXvKatwmJ1dZQCzU9WLw1JaI9Kb0piAiNf0XqofQggj83KYKmB08eBD0UCx4s9eBBLxqllpJDkSBYG7GUBIKSggQT0/z0mff2rbPpa0hSFBz42JndmW9mdmdJ7LIdNB1gy+AgxK8QaJOQySHCONiYyZ+jntg5OP3MALtQFAeAWybATADOW4L9aEaO33o8WcptlOJP7sq8iUCIvcWQACQsQDMaW5d6QiODnBGqeDqJYYBkWglUJ9lN0CbXJJd6uO/oqbAw0omF5G8GnwRBl0rAaYd/EtSDj01Mnydgp4auldeWF9ZqjMcO+m3w1xYsmaQeGhwcnz5HbDItfkt+eT03m6KkontdZArPf1l+7xBviXgF0Y2NQIAQOONQ6MDQlegYcnuEl+x2gyTLu7K8j154cGJWvyEqGBI3jSXTroFw8ED45BFmAAXYvsmtYhHcPh9UCoVG8OZGKmuYwOot6IxfDI3eHFW7+wI1TYNqRQOG180YAxPhdLnARWl9b/7+9Rc7JFj1qzqBwYC69/YGKpjJ0HXQa7UWUK8XfLivqCqM35s5W87nyvGZ209LNYjXCWomOBg6mAKYpQ7MzM3tqRK6OM98XS3E5h4lrOyNSmzYgiwcDFF2UzDHYDEzQhfkvf2HfJGrU8P7VJJVZLLYIVuDhP+A576nf3o6A3sM4WyhUQGuIsHSm5fZlQ9LWQybb34NaSQI+VTyY0/+R7Za3sxXK8VCFfdNQvBhCdjwEkmHooDH65Mzq8ufTSBRCY8EhsfugB1Hc1HT+UomvR6E9Ho/2vuRIIDoRvisYRMzUcU5eSgKb/5vhLd9v/+VPwIMAHaYM3koihLpAAAAAElFTkSuQmCC');
end;

{Enter plugin code here}
procedure PluginWork;
begin
  Checker;
end;
