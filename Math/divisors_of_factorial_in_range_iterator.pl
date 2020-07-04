#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 18 December 2018
# https://github.com/trizen

# Generate the divisors of n! in a given range, using a closure iterator.

# See also:
#   https://en.wikipedia.org/wiki/Smooth_number

use 5.020;
use warnings;

use experimental qw(signatures);
use ntheory qw(vecmin primes todigits vecsum valuation factorial);

sub divisors_of_factorial_iterator ($f, $low, $high) {

    my @primes = map { [$_, ($f - vecsum(todigits($f, $_))) / ($_ - 1)] } @{primes($f)};

    my @s = map { [1] } 1 .. @primes;

    sub {
        my $n = 0;

        while ($n < $low) {

            $n = vecmin(map { $_->[0] } @s);

            foreach my $i (0 .. $#primes) {
                shift(@{$s[$i]}) if ($s[$i][0] == $n);
                my $p = $primes[$i][0];
                last if valuation($n, $p) >= $primes[$i][1];
                push(@{$s[$i]}, $n * $p);
            }
        }

        return undef if ($n > $high);
        return $n;
    }
}

my $n    = 30;
my $low  = 10**8;
my $high = 10**12;

my $iter = divisors_of_factorial_iterator($n, $low, $high);

my $sum = 0;
for (my $n = $iter->() ; defined($n) ; $n = $iter->()) {
    $sum += $n;
}
say "Sum of divisors of $n! between $low and $high = $sum";

__END__
Sum of divisors of 30! between 100000000 and 1000000000000 = 53791918385367774
