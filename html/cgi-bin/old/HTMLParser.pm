package HTMLParser ;

sub Parse
{
my $partes = shift ;
my $filename = shift ;
my @partes = @{$partes} ;

my %htmls = () ;
my $current = 'main' ;

my %flags = () ;
open HTML, $filename ;
while (<HTML>)
	{
#	chop ;
	$x = Encode::decode('utf-8',$_) ;
	my $k ;
	my $nada = 1 ;
	my @estaspartes = () ;
	if ($current ne 'main')
		{
		@estaspartes = ($current) ;
		}		
	else
		{
		@estaspartes = @partes ;
		}
	for $k (@estaspartes)
		{
		my $clave = "<!--$k-->" ;
		my $finclave = "<!--fin$k-->" ;
		if ($x =~ /$clave/)
			{
			$flags{$k} = 1 ;
			$htmls{$current} .= $x ;
			$current = $k ;
			$nada = 0 ;
			}
		elsif ($flags{$k})
			{
			if ($x =~ /$finclave/)
				{
				$flags{$k} = 0 ;
				$nada = 0 ;
				$x = '' ;
				$current = 'main' ;
				}
			else
				{
				$htmls{$current} .=$x ;
				$nada = 0 ;
				}
			}
		}
	if ($nada)
		{
		$htmls{$current} .= $x ;
		}
	}
\%htmls ;
}

sub Popular      
{
my $html = shift ;
my $rec = shift ;                  
my $k ;                  
for $k (keys %{$rec})
        {
        $html = main::reemplazar($html,$k,$rec->{$k}) ;
        }
$html ;                  
}

return 1 ;
