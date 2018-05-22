#!/usr/local/bin/perl
# use strict ;
use warnings ;
use JSON;
use File::Slurp;

# my $dis = qx(cat /var/www/html/cgi-bin/dis_number.txt) ; #el id del dispositivo debe leerse desde un file
my $dis = read_file("/var/www/html/cgi-bin/dis_number.txt"); #el id del dispositivo debe leerse desde un file
$dis =~ tr/\r\n//d;

my $pthremoteimages = '/var/www/html/siguitds/inmobiliarias/images' ;
my $pthlocalimages = '/var/www/html/siguitds/inmobiliarias/images' ;
my $pthlocallistimages = '/tmp/rsyncimages.txt';

my $pthremotevideos = '/var/www/html/siguitds/inmobiliarias/videos' ;
my $pthlocalvideos = '/var/www/html/siguitds/inmobiliarias/videos' ;
my $pthlocallistcvideos = '/tmp/rsyncvideos.txt';

my $pthremoteschedule = "/var/www/html/siguitds/inmobiliarias/schedule/".$dis.".json" ;
my $pthlocalschedule = "/tmp/schedule.json.new.tmp" ;
my $pthplayschedule = "/tmp/schedule.json.new" ;

#########################
####UPDATE SCHEDULE #####
#########################
print ("Comenzando \n") ;

if (rsync($pthremoteschedule, $pthlocalschedule))
{
print("ACTUALIZANDO SCHEDULE.JSON \n") ;

	#Sincronizar IMAGENES LEYENDO EL JSON.
	system("chown www-data:www-data $pthlocalschedule") ;
	system("chown www-data:www-data $pthplayschedule") ;

	if (-e $pthlocalschedule)
	{
		my $decoded_json = decode_json(read_file($pthlocalschedule)) ;
		createimglist($decoded_json, $pthlocallistimages);
		createVidList($decoded_json, $pthlocallistcvideos);

		#ACTUALIZAR IMAGENES
		if (rsync($pthremoteimages, $pthlocalimages, $pthlocallistimages))
		{
		print("IMAGENES ACTUALIZADAS \n");
		system("chown pi:www-data -R $pthlocalimages") ;
	        system("chown pi:www-data $pthlocalimages/*") ;
		}
		#ACTUALIZAR VIDEOS
		if (rsync($pthremotevideos, $pthlocalvideos, $pthlocallistcvideos))
		{
		print("VIDEOS ACTUALIZADOS \n");
		system("chown pi:www-data -R $pthlocalvideos") ;
		system("chown pi:www-data $pthlocalvideos/*") ;
		}
	}
	system("cp $pthlocalschedule $pthplayschedule") ;
	system("perl /home/pi/rpi-digital-signage/home/removeFiles.pl") ;
}
else
{
print "Nada que hacer \n" ;
}


#----------------------------------


sub createimglist
{
	#Crea una lista de imagenes a partir del json
	print("Creando lista de imagenes \n") ;
	my $decoded_json = shift;
	my $pthlistimages = shift;
	my $s;

	my @schedule ;
	#QR
	if (ref($decoded_json->{'schedule'}) eq 'HASH' or ref($decoded_json->{'schedule'}) eq 'ARRAY') {
		@schedule = @{$decoded_json->{'schedule'}};
		foreach my $f ( @schedule )
		{
			$s .= "$f->{'img_qr'}\n" ;

			foreach my $p (@{$f->{images}})
			{
			#imagenes de las propiedades
			$s .= "$p->{'url'}\n" ;
			}
		}
	}

	#Invervalos
	my @ivl ;
	if (ref($decoded_json->{'ivl'}{media}) eq 'ARRAY')
	{
		@ivl = @{$decoded_json->{'ivl'}{media}};
		foreach my $f ( @ivl )
		{
			if ((lc($f) =~ /mov$/) || (lc($f) =~ /mp4$/))
			{

			}
			else
			{
				$s .= "$f\n" ;
			}
		}
	}

	#Logos
	my $logo = $decoded_json->{logo}{media};
	if (defined $logo and $logo ne '')
	{
		if ((lc($logo) =~ /mov$/) || (lc($logo) =~ /mp4$/))
		{

		}
		else
		{
			$s .= "$logo\n" ;
		}
	}
	# print("$s \n") ;
	write_file($pthlistimages, $s) ;
}
#----------------------------------


sub createVidList
{
	#Crea una lista de imagenes a partir del json
	my $decoded_json = shift;
	my $pthlistvideos = shift;

	my $s ;

	#Videos de los instervalos
	my @ivl ;
	if (ref($decoded_json->{'ivl'}{media}) eq 'ARRAY')
	 {
		@ivl = @{$decoded_json->{'ivl'}{media}};
		foreach my $f ( @ivl )
		{
			if ((lc($f) =~ /mov$/) || (lc($f) =~ /mp4$/))
			{
				$s .= "$f\n" ;
			}
			else
			{
			}
		}
	}

	#Logos
	my $logo = $decoded_json->{logo}{media};
	if (defined $logo and $logo ne '')
	{
		if ($logo ne '')
		{
			if ((lc($logo) =~ /mov$/) || (lc($logo) =~ /mp4$/))
			{
				$s .= "$logo\n" ;
			}
			else
			{
			}
		}
	}
	# print("$s \n") ;
	write_file($pthlistvideos, $s) ;
}


#----------------------------------

sub rsync
{
	my $source = shift;
	my $dest = shift;
	my $filesfrom = shift;
	my $c;
	my $outputlines;

	if (!$filesfrom)
	{
		$c = 'rsync -Pav -e "ssh -i /home/pi/siguit.pem" siguit@benteveo.com:' ;
		$outputlines = 4;
	}
	else
	{
		$c = 'rsync -Pav --files-from='.$filesfrom.' -e "ssh -i /home/pi/siguit.pem" siguit@benteveo.com:' ;
		$outputlines = 5;
	}

	$c .= $source . " " ;
	$c .= $dest . " " ;
	my $v = qx($c);
	my $ln = $v =~ tr/\n// ;
	print $v;

	if ($ln > $outputlines)
	{
	return 1 ;
	}
	else
	{
 	return 0 ;
	}
}
#----------------------------------
