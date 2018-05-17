#!/usr/bin/perl

use LWP::Simple;                # From CPAN
use JSON qw( decode_json );     # From CPAN
use Data::Dumper;               # Perl core module
use strict;                     # Good practice
use warnings;                   # Good practice

my $trendsurl = "http://localhost/cgi-bin/test.json";

# open is for files.
# local filesystem, this won't work.
#{
#  local $/; #enable slurp
#  open my $fh, "<", $trendsurl;
#  $json = <$fh>;
#}

# 'get' is exported by LWP::Simple; install LWP from CPAN unless you have it.
# You need it or something similar (HTTP::Tiny, maybe?) to get web pages.
my $json = get( $trendsurl );
die "Could not get $trendsurl!" unless defined $json;

# This next line isn't Perl.  don't know what you're going for.
#my $decoded_json = @{decode_json{shares}};

# Decode the entire JSON
my $decoded_json = decode_json( $json );

# you'll get this (it'll print out); comment this when done.
print Dumper $decoded_json;

# Access the shares like this:
#print "INFO: ",
      #$decoded_json->{'price'} . "\n",
      #$decoded_json->{'name'} . "\n" ,
      #$decoded_json->{'tags'}[0] . "\n"
      #;

#for my $i (0 .. $#$decoded_json->{'tags'}) 
#{
#print $decoded_json->{'tags'}[$i];
#}

my @tags = @{$decoded_json->{'tags'}};
foreach my $f ( @tags ) {
  #print $f->{"name"} . "\n";
  print $f . "\n";
}


