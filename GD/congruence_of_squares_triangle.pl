#!/usr/bin/perl

# Highlight integers `k` in a triangle such that `k^2 (mod N)`
# is a square and leads to a non-trivial factorization of `N`.

use 5.010;
use strict;
use warnings;

use GD::Simple;
use ntheory qw(:all);

# Composite integer N for which x^2 == y^2 (mod N)
# and { gcd(x-y, N), gcd(x+y, N) } are non trivial factors of N.
my $N = 43 * 79;

my $i = 1;
my $j = 1;

my $n     = shift(@ARGV) // 1000000;
my $limit = int(sqrt($n)) - 1;

my $img = GD::Simple->new($limit * 2, $limit + 1);
$img->bgcolor('black');
$img->rectangle(0, 0, $limit * 2, $limit + 1);

my $white = 0;
for (my $m = $limit; $m > 0; --$m) {

    $img->moveTo($m, $i - 1);

    for my $n ($j .. $i**2) {

        my $copy = $j;
        ## $j = ($copy*$copy + 3*$copy + 1);

        my $x = mulmod($j, $j, $N);

        my $root = sqrtint($x);
        my $r    = gcd($root - $j, $N);
        my $s    = gcd($root + $j, $N);

        if (is_square($x) and ($j % $N) != $root and (($r > 1 and $r < $N) and ($s > 1 and $s < $N))) {
            $white = 0;
            $img->fgcolor('white');
        }
        elsif (not $white) {
            $white = 1;
            $img->fgcolor('black');
        }
        $img->line(1);

        $j = $copy;
        ++$j;
    }
    ++$i;
}

open my $fh, '>:raw', 'congruence_of_squares.png';
print $fh $img->png;
close $fh;
