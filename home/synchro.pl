#!/usr/local/bin/perl
use strict ;
use warnings ;
use JSON;
use File::Slurp;

my $synccore = $ARGV[0];

my $dis = 1 ; #el id del dispositivo debe leerse desde un file

# my $folder = 3;
# my $local = 7;

my $pthremoteimages = '/var/www/html/siguitds/inmobiliarias/images' ;
my $pthlocalimages = '/var/www/html/siguitds/inmobiliarias/images' ;
my $pthlocallistimages = '/tmp/rsyncimages.txt';

my $pthremotevideos = '/var/www/html/siguitds/inmobiliarias/videos' ;
my $pthlocalvideos = '/var/www/html/siguitds/inmobiliarias/videos' ;
my $pthlocallistcvideos = '/tmp/rsyncvideos.txt';

# my $pthremoteplay = '/usr/lib/cgi-bin/play.pl' ;
# my $pthlocalplay = '/home/pi/play.pl' ;

# my $pthremotetpt = 'inmobiliarias/templates/' ;
# my $pthlocaltpt = '/var/www/html/templates/' ;
 #De aca se descargan los json

my $phtremoteschedule = "/var/www/html/siguitds/inmobiliarias/schedule/$dis.json" ;
my $phtlocalschedule = "/tmp/schedule.json.new";




###############
##UPDATE CORE##
###############

# if (defined $synccore && $synccore eq 'core') {
	# print "Warning: SINCRONIZANDO NUCLEO!'\n\n";

	# if (rsync($pthremoteplay, $pthlocalplay))
	# {
		# print("ACTUALIZANDO PLAY.PL. DEBO REINICIAR EL SISTEMA. \n")
		# # Si se actualiza play.pl debo detener el chrome	.
	# }

	# #En realidad la raspi va a saber qué carpeta buscar por dispositivo. porque va a estar asociada
	# #por MAC a un dispositivo fisico.
	# if (rsync($pthremotetpt, $pthlocaltpt))
	# {
	# print("ACTUALIZANDO TEMPLATES \n");
	# }

	# exit;
# }

#########################
####UPDATE SCHEDULE #####
#########################
print ("Comenzando \n") ;

if (rsync($phtremoteschedule, $phtlocalschedule))
{
print("ACTUALIZANDO SCHEDULE.JSON \n") ;

	#Sincronizar IMAGENES LEYENDO EL JSON.
	# system("chown www-data:www-data /var/www/html/cgi-bin/schedule.json") ;
	system("chown www-data:www-data $phtlocalschedule") ;

	if (-e $phtlocalschedule)
	{
		my $decoded_json = decode_json(read_file($phtlocalschedule)) ;
		createimglist($decoded_json, $pthlocallistimages);
		createVidList($decoded_json, $pthlocallistcvideos);

		#ACTUALIZAR IMAGENES
		if (rsync($pthremoteimages, $pthlocalimages, $pthlocallistimages))
		{
		print("IMAGENES ACTUALIZADAS \n");
		# system("chown pi:www-data -R /var/www/html/siguit-inmo/images") ;
    # system("chown pi:www-data /var/www/html/siguit-inmo/images/*") ;
		system("chown pi:www-data -R $pthlocalimages") ;
    system("chown pi:www-data $pthlocalimages/*") ;
		}
		#ACTUALIZAR VIDEOS
		if (rsync($pthremotevideos, $pthlocalvideos, $pthlocallistcvideos))
		{
		print("VIDEOS ACTUALIZADOS \n");
		# system("chown pi:www-data -R /var/www/html/siguit-inmo/images") ;
		# system("chown pi:www-data /var/www/html/siguit-inmo/images/*") ;
		system("chown pi:www-data -R $pthlocalvideos") ;
		system("chown pi:www-data $pthlocalvideos/*") ;
		}
	}
}
else
{
print "Nada que hacer \n" ;
}

#----------------------------------


sub createimglist
{
	#Crea una lista de imagenes a partir del json
	my $decoded_json = shift;
	my $pthlistimages = shift;


	my @schedule = @{$decoded_json->{'schedule'}};
	my $s;
	foreach my $f ( @schedule )
	{
		foreach my $p (@{$f->{images}})
		{
		#imagenes de las propiedades
		$s .= "$p->{'url'}\n" ;
		}
	}
	#imagenes de los intervalos
	$s .= "$decoded_json->{ivl}{img}\n" ;
	$s .= "$decoded_json->{ivl2}{img}\n" ;

	write_file($pthlistimages, $s) ;
	# open(my $fh, '>', $pthlistimages);
	# print $fh $s;
	# close $fh;
}
#----------------------------------


sub createVidList
{
	#Crea una lista de imagenes a partir del json
	my $decoded_json = shift;
	my $pthlistvideos = shift;

	# my @schedule = @{$decoded_json->{'schedule'}};
	my $s = "";
	# foreach my $f ( @schedule )
	# {
	# 	foreach my $p (@{$f->{videos}})
	# 	{
	# 	$s .= "$p->{'url'}\n" ;
	# 	}
	# }
	$s .= "$decoded_json->{ivl}{vid}\n" ;
	$s .= "$decoded_json->{ivl2}{vid}\n" ;

	write_file($pthlistvideos, $s) ;
	# open(my $fh, '>', $pthlistimages);
	# print $fh $s;
	# close $fh;
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
	# print $v;

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
