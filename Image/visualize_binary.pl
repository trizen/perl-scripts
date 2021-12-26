#!/usr/bin/perl

# Visualize a given input stream of bytes, as a PGM (P5) image.

use 5.014;
use strict;
use warnings;

use Getopt::Long qw(GetOptions);

my $width  = 0;
my $height = 0;
my $colors = 255;

GetOptions(
           "w|width=i"  => \$width,
           "h|height=i" => \$height,
           "c|colors=i" => \$colors,
          )
  or die "Error in arguments";

binmode(STDIN,  ':raw');
binmode(STDOUT, ':raw');

my $data = do {
    local $/;
    <>;
};

if (!$width or !$height) {
    $width  ||= ($height ? int(length($data) / $height) : int(sqrt(length($data))));
    $height ||= int(length($data) / $width);
}

print "P5 $width $height $colors\n";
print $data;
