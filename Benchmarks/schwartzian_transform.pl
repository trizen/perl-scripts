#!/usr/bin/perl

# Performance comparison of Schwartzian transform.

# See also:
#   https://en.wikipedia.org/wiki/Schwartzian_transform

use 5.010;
use Benchmark qw(cmpthese);

my @alpha = map { chr($_) } 32 .. 127;
my @arr = (
    map {
        join('', map { $alpha[rand @alpha] } 1 .. 140)
      } 1 .. 100
);

cmpthese(
    -1,
    {
     schwartz => sub {
         my @sorted = map { $_->[1] }
           sort { $a->[0] cmp $b->[0] }
           map { [lc($_), $_] } @arr;
         @sorted;
     },
     without_schwartz => sub {
         my @sorted = sort { lc($a) cmp lc($b) } @arr;
         @sorted;
     },
    }
);

__END__
                   Rate without_schwartz         schwartz
without_schwartz 4403/s               --             -53%
schwartz         9309/s             111%               --
