#!/usr/local/bin/perl -w
use CGI;
my $q = CGI->new();

my $v;
my $id = $q->param('id');

if ($id eq '' || $id >= 2)
{
$id = 0;
}
else
{
$id += 1;
}

@videos = ("video1.mp4","video2.mp4","video3.mp4");


my $miliseconds = 20000;
my $seconds = $miliseconds / 1000;


$html = qq{Content-Type: text/html

<html>
   <head>
   
      <script type="text/javascript">
         <!--
            function Redirect() {
               window.location="hello.pl?id=$id";
            }
            
            document.write("You will be redirected to main page in $seconds sec.");
            setTimeout('Redirect()', $miliseconds);
         //-->
      </script>
   </head>
   
   <body>
		<video width="1280" height="720" controls autoplay>
		  <source src="$videos[$id]" type="video/mp4">
		</video>
		<h1>$videos[$id]</h1>
   </body>
</html>
};

print $html;


#-------------
sub redirect
{
my $seconds = shift;
}