#!/usr/bin/perl

# Encode a sequence of n numbers into a polynomial of, at most, degree n-1.
# The polynomial will generate the given sequence of numbers, starting with index 0.

# See also:
#   https://yewtu.be/watch?v=4AuV93LOPcE
#   https://en.wikipedia.org/wiki/Polynomial_interpolation

use 5.014;
use warnings;
use experimental qw(signatures);

use Math::Polynomial;
use Math::AnyNum qw(:overload :all);
use List::Util qw(all);

sub binary_product (@arr) {

    while ($#arr > 0) {
        push @arr, shift(@arr)->mul(shift(@arr));
    }

    $arr[0];
}

sub poly_binomial ($n, $k) {
    my @terms;

    foreach my $i (0 .. $k - 1) {
        push @terms, $n;
        $n = $n->sub_const(1);
    }

    @terms || return Math::Polynomial->new(1);
    binary_product(@terms)->div_const(factorial($k));
}

sub array_differences (@arr) {

    my @result;

    foreach my $i (1 .. $#arr) {
        CORE::push(@result, $arr[$i] - $arr[$i - 1]);
    }

    @result;
}

sub solve_seq (@arr) {

    my $poly = Math::Polynomial->new();
    my $x    = Math::Polynomial->new(0, 1);

    for (my $k = 0 ; ; ++$k) {
        $poly += poly_binomial($x, $k)->mul_const($arr[0]);
        @arr = array_differences(@arr);
        last if all { $_ == 0 } @arr;
    }

    $poly;
}

if (@ARGV) {
    my @terms = (map { Math::AnyNum->new($_) } grep { /[0-9]/ } map { split(' ') } map { split(/\s*,\s*/) } @ARGV);
    say solve_seq(@terms);
}
else {
    say solve_seq(map { $_**2 } 0 .. 20);                   # (x^2)
    say solve_seq(map { faulhaber_sum($_, 2) } 0 .. 20);    # (1/3 x^3 + 1/2 x^2 + 1/6 x)
}
