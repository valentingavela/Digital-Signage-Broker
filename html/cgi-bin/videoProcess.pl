#!/usr/bin/perl -w
use CGI;
use utf8 ;
my $cgi = CGI->new() ;
print $cgi->header();
if(`ps -aef | pgrep omxplayer`) {
  #is playing
  print(0) ;
}
else
{
  #is not playing
  print('END') ;
}
