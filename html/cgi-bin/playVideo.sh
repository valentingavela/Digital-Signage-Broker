#!/bin/bash
/usr/bin/omxplayer -b -l 00:02:00 $1 < /var/www/omxplayerpipe &
/bin/echo . > /var/www/omxplayerpipe &
