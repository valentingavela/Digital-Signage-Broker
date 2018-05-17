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

my $cgi = CGI->new() ;
my $vector = $cgi->param('vector') ;
my $noanuncio = $cgi->param('noanuncio') ;
#my $dis = $cgi->param('dis') ;

my $ses = $cgi->cookie('sessis') ;
my $canrep = $ses->{canrep};

if ($ses eq '')
{
	my $cook = $cgi->cookie(-name=>'canrep',-value=>'0',-expires=>'2147483647',-path=>'/cgi-bin/') ;
	print "Set-Cookie: $cook\n" ;
}
else
{
	$canrep = $canrep + 1 ;
	my $cook = $cgi->cookie(-name=>'canrep',-value=>"$vector",-expires=>'2147483647',-path=>'/cgi-bin/') ;
	print "Set-Cookie: $cook\n" ;
}




#TODO: el dispositivo lo tiene que asignal la db!!!
my $dis = 1;

my $jsonpth = '/var/www/html/cgi-bin/schedule.json' ;
my $jsonpthnew = '/tmp/schedule.json.new' ;

syncschedule($jsonpthnew,  $jsonpth) ;

if (!-e $jsonpth)
{
	# print ("no json exists \n") ;
	if(-e $jsonpthnew)
	{
	# system("cp $jsonpthnew $jsonpth ") ;
	}
	else
	{
	print ("CRITICAL ERROR \n") ;
	}
}

# exit ;



my $decoded_json = decode_json(read_file($jsonpth));

#--------------------------
my $interval = $decoded_json->{ivl}{can_pub_ivl} ;
my $interval2 = $interval + $interval ;

if ($interval ne '' && ($canrep == $interval and $noanuncio ne 'no'))
{
	mostrarinterval($decoded_json, '1');
}
elsif ($interval2 ne '' && ($canrep == $interval2 and $noanuncio ne 'no'))
{
	# $canrep = 0 ;
	mostrarinterval($decoded_json, '2');
}
else
{
	mostrar($vector, $decoded_json, $dis);
}


#--------------------------
sub mostrarinterval
{
	my $decoded_json = shift ;
	my $typeivl = shift ;
	my $duration = $decoded_json->{data}{duration} ;
	my $tptpth = "/var/www/html/templates/inmobiliarias/ds/logo/index-T.html" ; #template del intervalo hardcoded

	# my $ivlimg = $decoded_json->{ivl}{img} ;
	my $b = '' ;
	my $ivlimg ;
	if ($typeivl eq '1') {
		$ivlimg = $decoded_json->{ivl}{img} ;
	}
	elsif ($typeivl eq '2') {
		$ivlimg = $decoded_json->{ivl2}{img} ;
	}

	$b = qq{ <img src="/siguitds/inmobiliarias/images/$ivlimg" alt="Logo"> }  ;

	my $template = HTML::Template->new(filename => $tptpth);
	$template->param(b => $b);
	$template->param(redir => redir($vector, $duration, $dis));

	print $cgi->header();
	print $template->output();
}


sub mostrar
{
	my $vector = shift;
	my $decoded_json = shift;

	my $jsonlen  = scalar @{$decoded_json->{'schedule'}};
	if($vector >= $jsonlen){ $vector = 0 ; }

	my @schedule = @{$decoded_json->{'schedule'}} ;
	my $duration = $decoded_json->{data}{duration} ;

	# print("DUR: " . $decoded_json->{'duration'});
	my $tptid = $decoded_json->{data}{tpt_id} ;

	my $tptpth =  "/var/www/html/templates/inmobiliarias/ds/$tptid/index.html" ;

	my $template = HTML::Template->new(filename => $tptpth);
	my $imgpth = "/siguitds/inmobiliarias/images/";

	my $f = $schedule[$vector];

	my $nro_ani = $f->{Antiguedad} ;
	if ($nro_ani ne '')
	{
		# $template->param(nro_ani => "$nro_ani AÑOS");
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
  $template->param(REDIR => redir($vector, $duration, $dis));

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
my $vector = shift;
$vector += 1;
my $duration = shift;
my $miliseconds = $duration*1000;
my $dis = shift ;
my $s = qq
	{
	<script>
	window.setTimeout("location=('/cgi-bin/play.pl?vector=$vector&dis=$dis');",$miliseconds );
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
