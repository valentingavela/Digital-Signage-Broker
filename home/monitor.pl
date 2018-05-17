#!/usr/local/bin/perl
use strict ;
use warnings ;

my $mac = qx(cat /sys/class/net/wlan0/address);
$mac =~ tr/\r\n//d;
my $uptime = substr(qx(uptime), 0, 9);

my $cmd = qq { curl --data "mac=$mac&uptime=$uptime" https://benteveo.com/cgi-bin/inmoping.pl } ;
my $res = qx($cmd) ;

# qx(cat /var/www/html/cgi-bin/dis_number.txt) ;

if($res ne "ERROR")
{
  file_write("/var/www/html/cgi-bin/dis_number.txt", $res) ;
  system("chown pi:www-data /var/www/html/cgi-bin/dis_number.txt") ;
}

sub file_write
{
  my $filename = shift ;
  my $text = shift ;
  open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
  print $fh $text ;
  close $fh;
}
