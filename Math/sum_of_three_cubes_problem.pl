#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 01 June 2016
# Website: https://github.com/trizen

# An attempt at creating a new algorithm for finding
# integer solutions to the following equation: x^3 + y^3 + z^3 = n

# The concept of the algorithm is to use modular exponentiation,
# based on the relations:
#
#       (x^3 mod n) + (y^3 mod n) + (z^3 mod n) = n
# or:
#       (x^3 mod n) + (y^3 mod n) + (z^3 mod n) = 2n       ; this is more common (?)
#

# This leads to the following conjecture:
#       x = a * n + k
#       y = b * n + j
#
# for every term x and y in a valid equation: x^3 + y^3 + z^3 = n

# Less generally, we can say:
#
#       x = a * n + s1 + psum(P(k))
#       y = b * n + s2 + psum(P(k))

# where `s1` and `s2` are the starting points for the corresponding terms
# and `psum(P(k))` is a partial sum of the remainders of n in the form: (k^3 mod n).

# Example:
#    39 = 134476^3 + 117367^3 - 159380^3
#
#    39 = 1 + 13 + 25
#
#    P(1)  = {15, 6, 18}                ; returned by get_pos_steps(39, 1)
#    P(13) = {35}                       ; returned by get_pos_steps(39, 13)
#    P(25) = {6, 15, 18}                ; returned by get_pos_steps(39, 25)
#
#    s1 = 1                             ; returned by get_pos_steps(39, 1)
#    s2 = 4                             ; returned by get_pos_steps(39, 25)
#    s3 = 13                            ; returned by get_pos_steps(39, 13)
#
#    117367 = a * 39 + s1 + 15
#    134476 = b * 39 + s2 + 0
#   -159380 = c * 39 + s3 + 0
#
# then we find:
#    a =  3009
#    b =  3448
#    c = -4087
#
# which results to:
#    117367 =  3009 * 39 + 16
#    134476 =  3448 * 39 + 4
#   -159380 = -4087 * 39 + 13
#

# For n=74:
#
#   2*74 = 68 + 29 + 51
#
#   P(68) = {2, 52, 20}
#   P(29) = {18, 24, 32}
#   P(51) = {8, 6, 60}
#
#   s1 = 6
#   s2 = 5
#   s3 = 17
#
#   x = a * 74 + s1 + (2 + 52)
#   y = b * 74 + s2 + (0)
#   z = c * 74 + s3 + (18)
#
#   x = a * 74 + 60
#   y = b * 74 + 5
#   z = c * 74 + 35
#
#   a =  894997732304
#   b =  3830406833753
#   c = -3846625575080

# We can also easily observe that any valid solution satisfies:
#
#    is_cube(x^3 + y^3 - n) or
#    is_cube(x^3 - y^3 - n)
#

# Currently, in this code, we show how to calculate the steps
# of a given term and how to collect and filter potential valid solutions.

# To actually find a solution, more work is required...

# Inspired by:
#      https://www.youtube.com/watch?v=wymmCdLdPvM

# See also:
#   http://mathoverflow.net/questions/138886/which-integers-can-be-expressed-as-a-sum-of-three-cubes-in-infinitely-many-ways

use 5.014;
use strict;
use warnings;

#use integer;
#use Math::BigNum qw(:constant);

use ntheory qw(powmod is_power);
use List::Util qw(pairmap any sum0);

use Data::Dump qw(pp);

# (a^3 % 33) + (b^3 % 33) + (c^3 % 33) = 66

sub get_pos_steps {
    my ($n, $k) = @_;

    my @steps;
    foreach my $i (1 .. 2 * $n) {
        if (powmod($i, 3, $n) == $k) {
            push @steps, $i;
        }
    }

    ($steps[0], [map { $steps[$_] - $steps[$_ - 1] } 1 .. $#steps]);
}

sub get_neg_steps {
    my ($n, $k) = @_;

    my @steps;
    foreach my $i (1 .. 2 * $n) {
        if (powmod(-$i, 3, $n) == $k) {
            push @steps, -$i;
        }
    }

    ($steps[0], [map { $steps[$_] - $steps[$_ - 1] } 1 .. $#steps]);
}

sub get_partitions {
    my ($n) = @_;

    my @p;
    my %seen;
    foreach my $i (1 .. $n) {
        foreach my $j ($i .. $n - $i) {
            foreach my $k ($j .. $n - $j - $i) {
                if ($i + $j + $k == $n) {
                    my $v = join(' ', sort { $a <=> $b } ($i, $j, $k));
                    next if (exists $seen{$v});
                    $seen{$v} = 1;
                    push @p, [$i, $j, $k];
                }
            }
        }
    }

    return @p;
}

#use Math::BigNum qw(:constant);

#~ my $n = 33;
#~ my $x = 0;
#~ my $y = 0;
#~ my $z = 0;

#~ my $n = 42;
#~ my $x = 0;
#~ my $y = 0;
#~ my $z = 0;

my $n = 74;
my $x = 66229832190556;
my $y = 283450105697727;
my $z = -284650292555885;

#~ my $n = 30;
#~ my $x = 2_220_422_932;
#~ my $y = -2_218_888_517;
#~ my $z = -283_059_965;

#~ my $n = 52;
#~ my $x = -61922712865;
#~ my $y = 23961292454;
#~ my $z = 60702901317;

#~ my $n = 75;
#~ my $x = -435203231;
#~ my $y = 435203083;
#~ my $z = 4381159;

#~ my $n = 75;
#~ my $x = 2_576_191_140_760;
#~ my $y = 1_217_343_443_218;
#~ my $z = -2_663_786_047_493;

#~ my $n = 75;
#~ my $x = 59_897_299_698_355;
#~ my $y = -47_258_398_396_091;
#~ my $z = -47_819_328_945_509;

#~ my $n = 87;
#~ my $x = 4271;
#~ my $y =-4126;
#~ my $z = -1972;

#~ my $n = 39;
#~ my $x = -159380;
#~ my $y = 134476;
#~ my $z = 117367;

#$x **= 3;
#$y **= 3;
#$z **= 3;

my @partitions = (get_partitions($n), get_partitions(2 * $n));
my @valid;

F1: foreach my $p (@partitions) {
    my @data;
    foreach my $k (@{$p}) {
        my $ok = 0;
        my $data = {k => $k};

        {
            my ($start, $steps) = get_pos_steps($n, $k);
            if (defined($start)) {
                $ok ||= 1;
                $data->{pos} = {
                                start => $start,
                                steps => $steps,
                               };
            }
        }

        {
            my ($start, $steps) = get_neg_steps($n, $k);
            if (defined($start)) {
                $ok ||= 1;
                $data->{neg} = {
                                start => $start,
                                steps => $steps,
                               };
            }
        }
        $ok || next F1;
        push @data, $data;
    }
    push @valid, \@data;
}

#
## Experimenting with various optimization ideas
#
foreach my $solution (@valid) {
    my $count = 0;
    foreach my $k ($x, $y, $z) {
        ++$count if any {
            my $s = $_;

            any {
                (($k % $n) == sum0(@{$s->{pos}{steps}}[0 .. $_]) + $s->{pos}{start})
                  or (($k % (-$n)) == sum0(@{$s->{neg}{steps}}[0 .. $_]) + $s->{neg}{start})
            }
            (-1 .. int(@{$s->{pos}{steps}} / 2) - 1);

            #~ any {
            #~ ($k % sum(@{$s->{pos}{steps}}[0 .. $_]) == $s->{pos}{start})
            #~ or ($k % sum(@{$s->{neg}{steps}}[0 .. $_]) == $s->{neg}{start})
            #~ }
            #~ int(@{$s->{pos}{steps}} / 2) .. $#{$s->{pos}{steps}};

            #(any      { $k % $_ == $s->{pos}{start} } @{$s->{pos}{steps}})
            #or (any { $k % $_ == $s->{neg}{start} } @{$s->{neg}{steps}})
        }
        @{$solution};
    }
    if ($count >= 3) {
        pp $solution;
    }
}

say scalar @valid;

my %seen;
pp [sort {$a <=> $b} grep{!$seen{$_}++} map { map {$_->{pos}{start}}@{$_} } @valid];
