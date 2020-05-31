#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 31 May 2020
# https://github.com/trizen

# Fast algorithm for generating esthetic numbers in a given base.

# See also:
#   https://rosettacode.org/wiki/Esthetic_numbers

# OEIS:
#   https://oeis.org/A000975 -- base 2
#   https://oeis.org/A033068 -- base 3
#   https://oeis.org/A033075 -- base 10

use 5.020;
use warnings;
use experimental qw(signatures);

use ntheory qw(fromdigits todigitstring);

sub generate_esthetic ($root, $upto, $callback, $base = 10) {

    my $v = fromdigits($root, $base);

    return if ($v > $upto);
    $callback->($v);

    my $t = $root->[-1];

    __SUB__->([@$root, $t + 1], $upto, $callback, $base) if ($t + 1 < $base);
    __SUB__->([@$root, $t - 1], $upto, $callback, $base) if ($t - 1 >= 0);
}

sub between_esthetic ($from, $upto, $base = 10) {
    my @list;
    foreach my $k (1 .. $base - 1) {
        generate_esthetic([$k], $upto,
            sub($n) { push(@list, $n) if ($n >= $from) }, $base);
    }
    sort { $a <=> $b } @list;
}

sub first_n_esthetic ($n, $base = 10) {
    for (my $m = $n * $n ; 1 ; $m *= $base) {
        my @list = between_esthetic(1, $m, $base);
        return @list[0 .. $n - 1] if @list >= $n;
    }
}

foreach my $base (2 .. 16) {
    say "20 first ${\(sprintf('%2d', $base))}-esthetic numbers: ",
        join(', ', first_n_esthetic(20, $base));
}

say "\nBase 10 esthetic numbers between 100,000,000 and 130,000,000:";
for (my @list = between_esthetic(1e8, 1.3e8) ; @list ;) {
    say join(' ', splice(@list, 0, 9));
}

__END__
20 first  2-esthetic numbers: 1, 2, 5, 10, 21, 42, 85, 170, 341, 682, 1365, 2730, 5461, 10922, 21845, 43690, 87381, 174762, 349525, 699050
20 first  3-esthetic numbers: 1, 2, 3, 5, 7, 10, 16, 21, 23, 30, 32, 48, 50, 64, 70, 91, 97, 145, 151, 192
20 first  4-esthetic numbers: 1, 2, 3, 4, 6, 9, 11, 14, 17, 25, 27, 36, 38, 46, 57, 59, 68, 70, 100, 102
20 first  5-esthetic numbers: 1, 2, 3, 4, 5, 7, 11, 13, 17, 19, 23, 26, 36, 38, 55, 57, 67, 69, 86, 88
20 first  6-esthetic numbers: 1, 2, 3, 4, 5, 6, 8, 13, 15, 20, 22, 27, 29, 34, 37, 49, 51, 78, 80, 92
20 first  7-esthetic numbers: 1, 2, 3, 4, 5, 6, 7, 9, 15, 17, 23, 25, 31, 33, 39, 41, 47, 50, 64, 66
20 first  8-esthetic numbers: 1, 2, 3, 4, 5, 6, 7, 8, 10, 17, 19, 26, 28, 35, 37, 44, 46, 53, 55, 62
20 first  9-esthetic numbers: 1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 19, 21, 29, 31, 39, 41, 49, 51, 59, 61
20 first 10-esthetic numbers: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 21, 23, 32, 34, 43, 45, 54, 56, 65
20 first 11-esthetic numbers: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 23, 25, 35, 37, 47, 49, 59, 61
20 first 12-esthetic numbers: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 14, 25, 27, 38, 40, 51, 53, 64
20 first 13-esthetic numbers: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 27, 29, 41, 43, 55, 57
20 first 14-esthetic numbers: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 16, 29, 31, 44, 46, 59
20 first 15-esthetic numbers: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 17, 31, 33, 47, 49
20 first 16-esthetic numbers: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 18, 33, 35, 50

Base 10 esthetic numbers between 100,000,000 and 130,000,000:
101010101 101010121 101010123 101012101 101012121 101012123 101012321 101012323 101012343
101012345 101210101 101210121 101210123 101212101 101212121 101212123 101212321 101212323
101212343 101212345 101232101 101232121 101232123 101232321 101232323 101232343 101232345
101234321 101234323 101234343 101234345 101234543 101234545 101234565 101234567 121010101
121010121 121010123 121012101 121012121 121012123 121012321 121012323 121012343 121012345
121210101 121210121 121210123 121212101 121212121 121212123 121212321 121212323 121212343
121212345 121232101 121232121 121232123 121232321 121232323 121232343 121232345 121234321
121234323 121234343 121234345 121234543 121234545 121234565 121234567 123210101 123210121
123210123 123212101 123212121 123212123 123212321 123212323 123212343 123212345 123232101
123232121 123232123 123232321 123232323 123232343 123232345 123234321 123234323 123234343
123234345 123234543 123234545 123234565 123234567 123432101 123432121 123432123 123432321
123432323 123432343 123432345 123434321 123434323 123434343 123434345 123434543 123434545
123434565 123434567 123454321 123454323 123454343 123454345 123454543 123454545 123454565
123454567 123456543 123456545 123456565 123456567 123456765 123456767 123456787 123456789
