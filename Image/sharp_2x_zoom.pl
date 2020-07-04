#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 31 October 2015
# Website: https://github.com/trizen

# Zoom a picture two times, without loosing too much details.

# Requires: wkhtmltoimage

use 5.010;
use strict;
use autodie;
use warnings;

use GD qw();
use File::Temp qw(tempfile);
use HTML::Entities qw(encode_entities);

GD::Image->trueColor(1);

sub help {
    my ($code) = @_;
    print <<"HELP";
usage: $0 [input image] [output image]
HELP
    exit($code);
}

sub enhance_img {
    my ($image, $out) = @_;

    my $img = GD::Image->new($image) // return;
    my ($width, $height) = $img->getBounds;

    my $scale_width  = 2 * $width;
    my $scale_height = $height;

    my $resized = GD::Image->new($scale_width, $scale_height);
    $resized->copyResampled($img, 0, 0, 0, 0, $scale_width, $scale_height, $width, $height);

    ($width, $height) = ($scale_width, $scale_height);
    $img = $resized;

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
      font-size: 1;
      font-family: monospace;
    }
EOT

    my $footer = <<'EOT';
</pre></body></html>
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

    $html = join('', $header, $style, $html, $footer);

    my ($fh, $tmpfile) = tempfile(UNLINK => 1, SUFFIX => '.html');
    print $fh $html;
    close $fh;

    system(
           'wkhtmltoimage', '--quality',     '100',      '--crop-h', $height * 2,
           '--crop-w',      $width,          '--crop-x', '8',        '--crop-y',
           '8',             '--transparent', '--quiet',  $tmpfile,   $out
          );
}

my $img = $ARGV[0] // help(1);
my $out = $ARGV[1] // help(1);
enhance_img($img, $out);
