#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 26 May 2015
# http://github.com/trizen

#
## Generate line-pattern triangles
#

use 5.010;
use strict;
use warnings;

use GD::Simple;
use File::Spec::Functions qw(catfile);

my $num_triangles = shift(@ARGV) // 15;    # duration: about 1 minute

sub generate {
    my ($n, $k, $data) = @_;

    my $acc = 1;
    for (my $i = 1 ; $i <= $n ;) {
        if ($acc % $k == 0) {
            foreach my $j (1 .. $acc) {
                $data->{$i + $j} = 1;
            }
        }
        $i += $acc;
        $acc++;
    }

    return $n;
}

my $dir = "Line-pattern Triangles";
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
