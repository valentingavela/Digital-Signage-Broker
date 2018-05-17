#!/usr/bin/perl
use DBI ;
use CGI;use lib "."; ;

use strict ;
use warnings ;
use Encode qw(decode);
use MKUtils qw(reemplazar) ;
use MKAppUtils qw(traducircampo) ;
use HTMLParser ;
my $cgi = new CGI ;
my $ip='localhost';
my $dbh = DBI->connect("DBI:mysql:host=$ip:user=benteveo_root:password=bichofeo:database=benteveo_siguitds") or die ;
$dbh->{'mysql_enable_utf8'} = 1;


my $idpub = $cgi->param('id') ; #id de inmueble 
#my $idtpt = $cgi->param('tpt_inm_id') ; #id de template
#my $pth;

#Tomo el path del template
#my $sthtpt = $dbh->prepare("SELECT pth FROM benteveo_siguitds.tpt_inm where id=?") ;
#$sthtpt->execute($idtpt) ;
#my $rectpt = $sthtpt->fetchrow_hashref() ;
#$pth  = $rectpt->{pth};
#$sthtpt->finish ;
#--
my $sthpub = $dbh->prepare("SELECT * FROM benteveo_siguitds.inm where id=?") ;
$sthpub->execute($idpub) ;

if ($sthpub->rows())
	{
	my $rec = $sthpub->fetchrow_hashref() ;
	
	my $sthcli = $dbh->prepare("SELECT tpt_inm_id FROM benteveo_siguitds.cli where id=?") ;
	$sthcli->execute($rec->{cli_id});
	my $reccli = $sthcli->fetchrow_hashref() ;
	$sthcli ->finish ;
	
	my $sthtpt = $dbh->prepare("SELECT pth FROM benteveo_siguitds.tpt_inm where id=?") ;
	$sthtpt->execute($reccli->{tpt_inm_id}) ;
	my $rectpt = $sthtpt->fetchrow_hashref() ;
	my $pth  = $rectpt->{pth};
	$sthtpt->finish ;
 
	mostrar($rec,$pth);
	}
#--
$sthpub->finish ;
$dbh->disconnect ;

##############################################################
sub mostrar
{
my $rec = shift;
my $pth = shift;
my $imgpth = "/siguit-inmo/images/";
#my $pth = "templates/inmobiliarias/01/index.html";
my $des = $rec->{des};
#my %html = %{HTMLParser::Parse(['dom','des','prc','txt','nro_sup_tot','nro_sup_cub','nro_amb','nro_ban','nro_cch','nro_ani','etg','tel','web']

#--Genero LISTADO DE IMAGENES.
#TODO: verificar if imagen ne '' then push..
my %html = %{HTMLParser::Parse(['imagen'], $pth)} ;

$html{imagen};
my @imagenes ;

if($rec->{img_1} ne ''){push @imagenes,reemplazar($html{imagen},'img',$imgpth . $rec->{img_1}) ;}
if($rec->{img_2} ne ''){push @imagenes,reemplazar($html{imagen},'img',$imgpth . $rec->{img_2}) ;}
if($rec->{img_3} ne ''){push @imagenes,reemplazar($html{imagen},'img',$imgpth . $rec->{img_3}) ;}
if($rec->{img_4} ne ''){push @imagenes,reemplazar($html{imagen},'img',$imgpth . $rec->{img_4}) ;}

$rec->{imagen} = sacablancos(join('',@imagenes)) ;

my $html = HTMLParser::Popular($html{main},$rec) ;
#--
$html = reemplazar($html,'eti_',traducirEti($rec->{eti}));
$html = reemplazar($html,'tip_ofe_',traducirOfe($rec->{tip_ofe}));
$html = reemplazar($html,'est_emp_',traducirEstEmp($rec->{est_emp}));

$html = reemplazar($html,'dom',$rec->{dom});
$html = reemplazar($html,'des',$rec->{des}) ;
$html = reemplazar($html,'prc',$rec->{prc}) ;
$html = reemplazar($html,'txt',$rec->{txt}) ;
$html = reemplazar($html,'nro_sup_tot',$rec->{nro_sup_tot}) ;
$html = reemplazar($html,'nro_sup_cub',$rec->{nro_sup_cub}) ;
$html = reemplazar($html,'nro_amb',$rec->{nro_amb}) ;
$html = reemplazar($html,'nro_ban',$rec->{nro_ban}) ;
$html = reemplazar($html,'nro_cch',$rec->{nro_cch}) ;
$html = reemplazar($html,'_nro_ani',$rec->{nro_ani} . ' a&ntildeos') ;
$html = reemplazar($html,'etg',$rec->{etg}) ;
$html = reemplazar($html,'tel',$rec->{tel}) ;
$html = reemplazar($html,'web',$rec->{web}) ;
$html = reemplazar($html,'tagdisplay',mostrarTag($rec->{tag})) ;
$html = reemplazar($html,'_tag',traducirTag($rec->{tag})) ;




$cgi->charset("utf-8") ;
print $cgi->header() ;
print encode($html) ;
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
