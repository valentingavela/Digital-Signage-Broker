#!/usr/local/bin/perl
use strict ;
use warnings ;

my $r_cgibin = "/otrodisco/inmobiliarias/playerUpgradeFiles/cgi-bin/" ;
my $r_etc = "/otrodisco/inmobiliarias/playerUpgradeFiles/etc/" ;
my $r_home= "/otrodisco/inmobiliarias/playerUpgradeFiles/home/" ;
my $r_templates= "/otrodisco/inmobiliarias/playerUpgradeFiles/templates/" ;

my $tmp_cgibin = "/home/pi/tmp/cgi-bin" ;
my $tmp_etc = "/home/pi/tmp/etc" ;
my $tmp_home = "/home/pi/tmp/home" ;
my $tmp_templates = "/home/pi/tmp/templates" ;

my $d_cgibin = "/var/www/html/cgi-bin/" ;
my $d_etc = "/etc/" ;
my $d_home = "/home/pi/" ;
my $d_templates = "/var/www/html/templates/" ;

createDirs();

my $doUpgrade = synchronize() ;

if ($doUpgrade)
{
  print("Matar Programas \n") ;
  killPrograms() ;
  print("Copiar Archivos \n") ;
  copyFiles() ;
  print("Cambiando Owners \n") ;
  chownDirs() ;
  print("Iniciar Programas \n") ;
  print("Iniciar Reiniciar \n") ;
  startPrograms() ;
}


#--------------------------
sub rsync
{
	my $source = shift;
	my $dest = shift;
	my $c;
	my $outputlines = 4;

	$c = 'rsync -Pav -e "ssh -i /home/pi/siguit.pem" siguit@benteveo.com:' ;
	$c .= $source . " " ;
	$c .= $dest . " " ;
	my $v = qx($c);
	my $ln = $v =~ tr/\n// ;

  print "RESULTADO RSYNC \n $v";

	if ($ln > $outputlines)
	{
	return 1 ;
	}
	else
	{
 	return 0 ;
	}
}


sub createDirs
{
  if (!-e "/home/pi/tmp")
  {
    system("mkdir /home/pi/tmp") ;
  }
  if (!-e $tmp_cgibin)
  {
    system("mkdir $tmp_cgibin") ;
  }
  if (!-e $tmp_etc)
  {
    system("mkdir $tmp_etc") ;
  }
  if (!-e $tmp_home)
  {
    system("mkdir $tmp_home") ;
  }
  if (!-e $tmp_templates)
  {
    system("mkdir $tmp_templates") ;
  }
}

sub synchronize
{
  my $doUpgrade = 0 ;

  if (rsync($r_cgibin, $tmp_cgibin))
  {
    print "CGI ACTUALIZADO \n" ;
    $doUpgrade = 1 ;
  }

  if (rsync($r_etc, $tmp_etc))
  {
    print "ETC ACTUALIZADO \n" ;
    $doUpgrade = 1 ;
  }

  if (rsync($r_home, $tmp_home))
  {
    print "TMP ACTUALIZADO \n" ;
    $doUpgrade = 1 ;
  }

  if (rsync($r_templates, $tmp_templates))
  {
    print "TEMPLATES ACTUALIZADO \n" ;
    $doUpgrade = 1 ;
  }

  return $doUpgrade ;
}


sub killPrograms
{
  system("killall chromium-browser") ;
  sleep(2);
  system("service cron stop") ;
  sleep(2);
}

sub startPrograms
{
  system("service cron start") ;
  sleep(2);
  system("reboot") ;
}

sub copyFiles
{
  system("cp -R $tmp_cgibin/* $d_cgibin ") ;
  system("cp -R $tmp_templates/* $d_templates ") ;
  system("cp -R $tmp_etc/* $d_etc ") ;
  system("cp -R $tmp_home/* $d_home ") ;
}

sub chownDirs
{
  system("chown pi:pi /home/pi/*") ;
  system("chown pi:www-data -R /var/www/html/") ;
}
