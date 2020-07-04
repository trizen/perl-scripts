#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 25 May 2015
# http://github.com/trizen

#
## Generate magic triangles with n gaps between numbers
#

use 5.010;
use strict;
use warnings;

use GD::Simple;
use File::Spec::Functions qw(catfile);

my $num_triangles = shift(@ARGV) // 100;    # duration: about 6 minutes

sub generate {
    my ($n, $j, $data) = @_;

    foreach my $i (1 .. $n) {
        if ($i % $j == 0) {
            $data->{$i} = 1;
        }
    }

    return $n;
}

my $dir = "Number Triangles";
if (not -d $dir) {
    mkdir($dir)
      or die "Can't create dir `$dir': $!";
}

foreach my $k (1 .. $num_triangles) {

    my %data;
    my $max = generate(921600, $k, \%data);
    my $limit = int(sqrt($max)) - 1;

    say "[$k of $num_triangles] Generating...";

    # create a new image
    my $img = GD::Simple->new($limit * 2, $limit + 1);

    $img->bgcolor('black');
    $img->rectangle(0, 0, $limit * 2, $limit + 1);

    my $i = 1;
    my $j = 1;

    my $black = 0;
    for my $m (reverse(0 .. $limit)) {
        $img->moveTo($m, $i - 1);

        for my $n ($j .. $i**2) {
            if (exists $data{$j}) {
                $black = 0;
                $img->fgcolor('yellow');
            }
            elsif (not $black) {
                $black = 1;
                $img->fgcolor('black');
            }
            $img->line(1);
            ++$j;
        }
        ++$i;
    }

    open my $fh, '>:raw', catfile($dir, sprintf("%04d.png", $k));
    print $fh $img->png;
    close $fh;
}
