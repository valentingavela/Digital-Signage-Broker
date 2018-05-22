#!/usr/local/bin/perl
use strict ;
use warnings ;
use JSON;
use File::Slurp;

my $dis = read_file("/var/www/html/cgi-bin/dis_number.txt"); #el id del dispositivo debe leerse desde un file
$dis =~ tr/\r\n//d;
my $pthlocalimages = '/var/www/html/siguitds/inmobiliarias/images' ;
my $pthlocalvideos = '/var/www/html/siguitds/inmobiliarias/videos' ;
my $pthlocalschedule = "/tmp/schedule.json.new.tmp" ;
my $decoded_json = decode_json(read_file($pthlocalschedule)) ;

my @list_files = listFiles($pthlocalimages) ;
push @list_files, listFiles($pthlocalvideos) ;

my @list_in_json = createImgList($decoded_json, '');
push @list_in_json, createVidList($decoded_json, '');

my %hash_files=map{$_ =>1} @list_files;
my %hash_json=map{$_=>1} @list_in_json;
my @list_remove=grep(!defined $hash_json{$_}, @list_files);

foreach my $rec (@list_remove)
{
  if ((lc($rec) =~ /mov$/) || (lc($rec) =~ /mp4$/))
  {
    system("rm $pthlocalvideos/$rec") ;
    print "\n SON VIDEOS \n $rec \n" ;
  }
  else
  {
    print "\n SON IMGS \n $rec \n" ;
    system("rm $pthlocalimages/$rec") ;
  }
}

######

sub listFiles
{
  my @list_files ;
  my $directory = shift ;
  opendir (DIR, $directory) or die $!;
  while (my $file = readdir(DIR)) {
      if($file ne '.' && $file ne '..')
      {
      push @list_files, $file ;
      }
  }
  return @list_files ;
}

sub createImgList
{
	#Crea una lista de imagenes a partir del json
	my $decoded_json = shift;
	my $pthlistimages = shift;
	my @list_images;
	my $s;

	my @schedule ;
	#QR
	if (ref($decoded_json->{'schedule'}) eq 'HASH' or ref($decoded_json->{'schedule'}) eq 'ARRAY') {
		@schedule = @{$decoded_json->{'schedule'}};
		foreach my $f ( @schedule )
		{
			$s .= "$f->{'img_qr'}\n" ;
			push @list_images, $f->{'img_qr'} ;
			foreach my $p (@{$f->{images}})
			{
			#imagenes de las propiedades
				$s .= "$p->{'url'}\n" ;
				push @list_images, $p->{'url'} ;
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
				push @list_images, $f ;
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
			push @list_images, $logo ;
		}
	}
	# print("$s \n") ;
	# write_file($pthlistimages, $s) ;
	return @list_images ;
}
#----------------------------------


sub createVidList
{
	#Crea una lista de imagenes a partir del json
	my $decoded_json = shift;
	my $pthlistvideos = shift;
	my @list_videos ;
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
				push @list_videos, $f ;

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
				push @list_videos, $logo ;

			}
			else
			{
			}
		}
	}
	# print("$s \n") ;
	# write_file($pthlistvideos, $s) ;
	return @list_videos ;
}
