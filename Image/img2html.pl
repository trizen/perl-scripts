#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 15 October 2015
# Website: https://github.com/trizen

# Generate an HTML representation of an image
# (best viewed with Firefox)

use 5.010;
use strict;
use autodie;
use warnings;

use GD qw();
use Getopt::Long qw(GetOptions);

GD::Image->trueColor(1);

my $size      = 500;
my $font_size = 1;

sub help {
    my ($code) = @_;
    print <<"HELP";
usage: $0 [options] [files]

options:
    -w  --width=i     : width size of the ASCII image (default: $size)
    -f  --font-size=i : HTML font size property (default: $font_size)

example:
    perl $0 --size 200 image.png
HELP
    exit($code);
}

GetOptions(
           'w|width=i'     => \$size,
           'f|font-size=f' => \$font_size,
           'h|help'        => sub { help(0) },
          )
  || die "Error in command-line arguments!";

sub img2html {
    my ($image) = @_;

    my $img = GD::Image->new($image) // return;
    my ($width, $height) = $img->getBounds;

    if ($size != 0) {
        my $scale_width = $size;
        my $scale_height = int($height / ($width / ($size / 2)));

        my $resized = GD::Image->new($scale_width, $scale_height);
        $resized->copyResampled($img, 0, 0, 0, 0, $scale_width, $scale_height, $width, $height);

        ($width, $height) = ($scale_width, $scale_height);
        $img = $resized;
    }

    my @pixels;

    foreach my $y (0 .. $height - 1) {
        foreach my $x (0 .. $width - 1) {
            my $index = $img->getPixel($x, $y);
            push @pixels, [$img->rgb($index)];
        }
    }

    my $html = <<"EOT";
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>pl2html</title>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<style type="text/css">
/*<![CDATA[*/
<!--

pre {
      font-size: $font_size;
      font-family: monospace;
    }

-->
/*]]>*/
</style>
</head>
<body>
<pre>
EOT

    while (@pixels) {
        $html .= join('',
                      map { sprintf(q{<span style="background-color:#%02x%02x%02x;">%s</span>}, @{$_}, ' ') }
                        splice(@pixels, 0, $width));
        $html .= '<br/>';
    }

    $html . <<'EOT';
</pre>
</body>
</html>
EOT
}

say img2html($ARGV[0] // help(1));
