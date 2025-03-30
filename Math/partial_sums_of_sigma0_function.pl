#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 09 November 2018
# Edit: 30 March 2025
# https://github.com/trizen

# Algorithm with O(sqrt(n)) complexity for computing the partial-sums of the `sigma_0(k)` function:
#   Sum_{k=1..n} sigma_0(k)

# See also:
#   https://oeis.org/A006218
#   https://en.wikipedia.org/wiki/Divisor_function
#   https://en.wikipedia.org/wiki/Faulhaber%27s_formula
#   https://en.wikipedia.org/wiki/Bernoulli_polynomials
#   https://trizenx.blogspot.com/2018/11/partial-sums-of-arithmetical-functions.html

use 5.036;

sub sigma0_partial_sum_faulhaber ($n) {

    my $s   = int(sqrt($n));
    my $sum = 0;

    foreach my $k (1 .. $s) {
        $sum += 2 * int($n / $k);
    }

    return ($sum - $s * $s);
}

sub sigma0_partial_sum_test ($n) {    # just for testing
    my $sum = 0;
    foreach my $k (1 .. $n) {
        $sum += int($n / $k);
    }
    return $sum;
}

foreach my $m (0 .. 10) {

    my $n = int(rand(1 << (2 * $m)));

    my $t1 = sigma0_partial_sum_test($n);
    my $t2 = sigma0_partial_sum_faulhaber($n);

    say "Sum_{k=1..$n} sigma_0(k) = $t2";

    die "error: $t1 != $t2" if ($t1 != $t2);
}

__END__
Sum_{k=1..0} sigma_0(k) = 0
Sum_{k=1..3} sigma_0(k) = 5
Sum_{k=1..13} sigma_0(k) = 37
Sum_{k=1..30} sigma_0(k) = 111
Sum_{k=1..193} sigma_0(k) = 1049
Sum_{k=1..51} sigma_0(k) = 211
Sum_{k=1..2288} sigma_0(k) = 18059
Sum_{k=1..15985} sigma_0(k) = 157208
Sum_{k=1..10112} sigma_0(k) = 94818
Sum_{k=1..152099} sigma_0(k) = 1838389
Sum_{k=1..446108} sigma_0(k) = 5872025
