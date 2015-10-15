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
use HTML::Entities qw(encode_entities);

GD::Image->trueColor(1);

my $size      = 500;
my $font_size = 1;

sub help {
    my ($code) = @_;
    print <<"HELP";
usage: $0 [options] [files]

options:
    -w  --width=i     : scale the image to this width (default: $size)
    -f  --font-size=i : HTML font size property (default: $font_size)

example:
    perl $0 --width 800 image.png
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

    my $header = <<"EOT";
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>${\encode_entities($image)}</title>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<style type="text/css">
/*<![CDATA[*/
<!--

pre {
      font-size: $font_size;
      font-family: monospace;
    }

EOT

    my $footer = <<'EOT';
</pre>
</body>
</html>
EOT

    my %colors;
    my $style = '';

    my @html;
    my $name = 'A';

    while (@pixels) {
        push @html, [
            map {
                my $color = sprintf("%02x%02x%02x", @{$_});

                if (not exists $colors{$color}) {
                    $colors{$color} = $name;
                    $style .= ".$name\{background-color:#$color;}\n";
                    $name++;
                }

                $colors{$color};
              } splice(@pixels, 0, $width)
        ];
    }

    my $html = '';
    foreach my $row (@html) {

        while (@{$row}) {
            my $class = shift @{$row};

            my $count = 1;
            while (@{$row} and $row->[0] eq $class) {
                ++$count;
                shift @{$row};
            }

            $html .= qq{<span class="$class">} . (' ' x $count) . "</span>";
        }

        $html .= '<br/>';
    }

    $style .= <<'EOT';
-->
/*]]>*/
</style>
</head>
<body>
<pre>
EOT

    join('', $header, $style, $html, $footer);
}

say img2html($ARGV[0] // help(1));
