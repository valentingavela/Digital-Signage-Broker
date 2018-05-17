#!/usr/bin/perl -w
#TODO: terminar templates!!!!
#TODO: consultar de la db los templates
#TODO: terminar la funcion redir

use utf8;
use HTML::Template;
use strict;
use warnings;
use CGI;
use JSON;
use File::Slurp;
use File::stat;
use Time::localtime;
# use Data::Dumper;
my $dis = 1;

my $jsonpth = '/var/www/html/cgi-bin/schedule.json' ;
my $jsonpthnew = '/tmp/schedule.json.new' ;

syncschedule($jsonpthnew,  $jsonpth) ;

if (!-e $jsonpth)
{
	if(!-e $jsonpthnew)
	{
	print ("CRITICAL ERROR \n") ;
	}
}

my $decoded_json = decode_json(read_file($jsonpth));

my $cgi = CGI->new() ;

my $noanuncio = $cgi->param('noanuncio') ;

my $canrep = $cgi->cookie('canrep') ; # Cuantas reproducciones
my $vector = $cgi->cookie('vector') ; # Por cual vector voy
my $vector_ivl = nz($cgi->cookie('vector_ivl')) ; # Por cual vector de intervalo voy

my $interval = $decoded_json->{ivl}{can_pub_ivl} ;
my $interval2 = $interval * 2 ;

#Manejo de la logica de playlist
if ($canrep eq '' || $canrep > $interval2 )
{
	$canrep = 0 ;
}
$canrep = $canrep + 1 ;

if ($vector eq '')
	{
	$vector = 0 ;
}
$vector = $vector + 1 ;

my $sch_len  = scalar @{$decoded_json->{'schedule'}};
if($vector >= $sch_len)
{
	$vector = 0 ;
}

my @ivl = @{$decoded_json->{ivl}{media}} ;
my $ivl_len  = scalar @ivl;
if($vector_ivl >= $ivl_len)
{
	$vector_ivl = 0 ;
}


my $cook1 = $cgi->cookie(-name=>'canrep',-value=>$canrep,-expires=>'+3M',-path=>'/cgi-bin/') ;
print "Set-Cookie: $cook1\n" ;

my $cook2  = $cgi->cookie(-name=>'vector',-value=>$vector,-expires=>'+3M',-path=>'/cgi-bin/') ;
print "Set-Cookie: $cook2\n" ;

my $cook3  = $cgi->cookie(-name=>'vector_ivl',-value=>$vector_ivl,-expires=>'+3M',-path=>'/cgi-bin/') ;
print "Set-Cookie: $cook3\n" ;


if ($interval ne '' && ($canrep == $interval and $noanuncio ne 'no'))
{
	mostrarinterval($decoded_json, 'marca');
}
elsif ($interval2 ne '' && ($canrep == $interval2 and $noanuncio ne 'no'))
{
	# $canrep = 0 ;
	mostrarinterval($decoded_json, 'info');
}
else
{
	mostrar($vector, $decoded_json, $dis);
}


#TODO: el dispositivo lo tiene que asignal la db!!!


# exit ;


#--------------------------
sub mostrarinterval
{
	my $decoded_json = shift ;
	my $typeivl = shift ;
	my $duration = $decoded_json->{data}{duration} ;
	# my $tptpth = "/var/www/html/templates/inmobiliarias/ds/logo/index-T.html" ; #template del intervalo hardcoded

	# 1- Definir si es video o imagen
	# 2- Si es video hacer un src de video, si es imagen de imagen.
	my $media ;
	my $tptpth ;
	my $b ;

	# my $ivlimg ;
	# my $ivlvid ;

	my $redir = redir($duration) ;
	if ($typeivl eq 'logo')
	{
		$media = $decoded_json->{logo}{media} ;
		$b = intervalStr($media) ;
		$tptpth = intervalTpt($media) ;
	}
	elsif ($typeivl eq 'info')
	{
		my @ivl = @{$decoded_json->{ivl}{media}} ;

		$media = $ivl[$vector_ivl] ;
		$b = intervalStr($media) ;
		$tptpth = intervalTpt($media) ;
	}


	# if ($typeivl eq 'marca')
	# {
	# 	#Checkear si es img_ivl ne '' elsif video
	# 	$ivlimg = $decoded_json->{ivl}{img} ;
	# 	$ivlvid = $decoded_json->{ivl}{vid} ;
	#
	# 	if($ivlimg ne '')
	# 	{
	# 		$b = qq{ <img src="/siguitds/inmobiliarias/images/$ivlimg" alt="Logo"> }  ;
	# 		$b .=  $redir ;
	# 	}
	# 	else
	# 	{
	# 		$b = qq {
	# 			<div class="videoport">
	# 	      <video id="video" autoplay>
	# 	        <source src="/siguitds/inmobiliarias/videos/$ivlvid" type="video/mp4 ">
	# 	      </video>
	# 	    </div>
	#
	# 			<script>
	# 			var vid = document.getElementById("video");
	# 				vid.onended = function() {
	# 					window.location.replace("/cgi-bin/play2.pl");
	# 			};
	# 			</script>
	# 		}
	# 	}
	# }
	# elsif ($typeivl eq 'info')
	# {
	# 	$ivlimg = $decoded_json->{ivl2}{img} ;
	# 	$ivlvid = $decoded_json->{ivl2}{vid} ;
	#
	# 	if($ivlimg ne '')
	# 	{
	# 		$b = qq{ <img src="/siguitds/inmobiliarias/images/$ivlimg" alt="Logo"> }  ;
	# 		$b .=  $redir ;
	# 	}
	# 	else
	# 	{
	# 		$b = qq {
	# 			<div class="videoport">
	# 	      <video id="video" autoplay>
	# 	        <source src="/siguitds/inmobiliarias/videos/$ivlvid" type="video/mp4" >
	# 	      </video>
	# 	    </div>
	#
	# 			<script>
	# 			var vid = document.getElementById("video");
	# 				vid.onended = function() {
	# 					window.location.replace("/cgi-bin/play2.pl");
	# 			};
	# 			</script>
	# 		}
	# 	}
	# }

	my $template = HTML::Template->new(filename => $tptpth);
	$template->param(b => $b);
	# $template->param(redir => redir($vector, $duration, $dis));

	print $cgi->header();
	print $template->output();
}



sub mostrar
{
	my $vector = shift;
	my $decoded_json = shift;

	my @schedule = @{$decoded_json->{'schedule'}} ;
	my $duration = $decoded_json->{data}{duration} ;

	# print("DUR: " . $decoded_json->{'duration'});
	my $tptid = $decoded_json->{data}{tpt_id} ;

	my $tptpth =  "/var/www/html/templates/inmobiliarias/ds/$tptid/index.html" ;

	my $template = HTML::Template->new(filename => $tptpth);
	my $imgpth = "/siguitds/inmobiliarias/images/";

	my $f = $schedule[$vector];

	my $nro_ani = $f->{"Antiguedad"} ;
	if ($nro_ani ne ' ')
	{
		$template->param(nro_ani => "$nro_ani AÑOS");
	}

	my $etg = $f->{"Entrega"} ;
	if ($etg ne ' ')
	{
		$template->param(etg => $etg );
	}

	if($decoded_json->{data}{est_bot} ne "0")
	{
		$template->param(tel_wsp_bot => $decoded_json->{data}{tel_wsp_bot}) ;
		$template->param(wsp_bot_txt => $decoded_json->{data}{wsp_bot_txt}) ;
	}

	$template->param(cod => $f->{Cod});
	$template->param(nro_amb => $f->{"Ambientes"} );
	$template->param(nro_ban => $f->{"Banos"} );
	$template->param(nro_cch => $f->{"Cocheras"} );
	$template->param(txt => $f->{"Descripcion"} );
	$template->param(dom => $f->{"Direccion"} );
	$template->param(est_emp => $f->{"Estado"} );
  $template->param(mon => $f->{"Moneda"} );
	$template->param(prc => $f->{"Precio"} );
	$template->param(des => $f->{"Propiedad"} );
	# $template->param(prc => $f->{"Provincia"} );
	$template->param(nro_sup_tot => $f->{"SuperfCubierta"} );
	$template->param(nro_sup_cub => $f->{"SuperfTotal"} );
	# $template->param(tel => $f->{"Telefono"} );
	$template->param(tip_ofe => $f->{"TipodeOperacion"} );
	$template->param(web => $f->{"Web"} );
	# $template->param(des => $f->{"Titulo"} );

	if (!$f->{"Tag"})
	{
		$template->param(tagdisplay => 'style="display:none"' );
	}
	else
	{
		$template->param(tag => $f->{"Tag"} );
	}

	#----IMAGENES----
	my @imgs = @{$decoded_json->{'schedule'}[$vector]{'images'}};
	# print @images[0]->{'url'};
	my @images;
	for my $elem (@imgs) {
		push @images,$imgpth.$elem->{'url'};
	}

    my @loop_data = ();  # initialize an array to hold your loop
	while (@images)
	{
	    my %row_data;  # get a fresh hash for the row data
		$row_data{IMAGES_SRC} = shift @images;
        push(@loop_data, \%row_data);
	}
    $template->param(IMAGES => \@loop_data);
	#-------------

	$template->param(mytime => $duration*1000);
  $template->param(REDIR => redir($duration, $dis));

	print $cgi->header();
	print $template->output();

 }
#-------------

sub traducirTag
{
my $tag = shift;
my $r;
if($tag == 1)
{
$r = 'RESERVADO';
}
elsif($tag == 2)
{
$r = 'VENDIDO';
}
return $r;
}
#-------------


sub mostrarTag
{
my $tag = shift;
my $r;
if ($tag == 1 or $tag == 2)
{
}
else
{
$r = 'style="display:none"';
}
return $r;
}
#-------------


sub traducirEti
{
my $q = shift;
my $r;

if ($q == 0){    $r="NUEVO";   }
if ($q == 1){    $r="DESTACADO";   }

return $r;
}
#-----------------


sub traducirOfe
{
my $q = shift;
my $r;

if ($q == 2) {    $r="ALQUILER";   }
if ($q == 1) {    $r="VENTA";   }
if ($q == 3) {    $r="EMPRENDIMIENTO";   }

return $r;
}
#-------------------


sub traducirEstEmp
{
my $q = shift;
my $r;

if ($q == 3)  {    $r="EN POZO";   }
if ($q == 1)  {    $r="EN CONSTRUCCION";   }
if ($q == 2)  {    $r="A ESTRENAR";   }

return $r;
}

#------------------

sub redir
{
# my $vector = shift;
# $vector += 1;
my $duration = shift;
my $miliseconds = $duration*1000;
# my $dis = shift ;
my $s = qq
	{
	<script>
	window.setTimeout("location=('/cgi-bin/play2.pl');",$miliseconds );
	</script>
	};

return $s;
}


sub syncschedule
{
	my $file1 = shift ;
	my $file2 = shift ;
	system("rsync $file1 $file2") ;
}

sub setCookiesIfEmpty
{
	my $canrep = shift ;
	my $vector = shift ;

	if ($canrep eq '')
	{
		my $cook1 = $cgi->cookie(-name=>'canrep',-value=>'0',-expires=>'2147483647',-path=>'/cgi-bin/') ;
		print "Set-Cookie: $cook1\n" ;
	}

	if ($vector eq '')
	{
		my $cook2 = $cgi->cookie(-name=>'vector',-value=>'0',-expires=>'2147483647',-path=>'/cgi-bin/') ;
		print "Set-Cookie: $cook2\n" ;
	}
}

sub intervalStr
{
	my $media = shift ;
	my $b ;
	if ((lc($media) =~ /mov$/) || (lc($media) =~ /mp4$/))
	{
		$b = qq {
					<video id="video" src="/siguitds/inmobiliarias/videos/$media" type="video/mp4">

			<script>
				var viewport = document.getElementById('video')
				var video = document.getElementById('video')
				viewport.addEventListener('mouseover', function() { video.play() }, false);
				viewport.addEventListener('mouseout', function() { video.pause() }, false);
			</script>
		}
	}
	else
	{
		$b = qq{ <img src="/siguitds/inmobiliarias/images/$media" alt="Logo"> }  ;
	}
	return $b ;
}

sub intervalTpt
{
	my $media = shift ;
	my $tptpth ;
	if ((lc($media) =~ /mov$/) || (lc($media) =~ /mp4$/))
	{
		$tptpth = "/var/www/html/templates/inmobiliarias/ds/logo/video-T.html" ;
	}
	else
	{
		$tptpth = "/var/www/html/templates/inmobiliarias/ds/logo/image-T.html" ;
	}
	return $tptpth ;
}

sub nz
{
	my $x = shift ;
	if ($x eq '')
	{
		return 0 ;
	}
	else
	{
		return $x ;
	}
}
