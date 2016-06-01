#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 01 June 2016
# Website: https://github.com/trizen

# An attempt at creating a new algorithm for finding
# integer solutions to the following equation: x^3 + y^3 + z^3 = n

# The concept of the algorithm is to use modular exponentiation,
# based on the relation:
#
#       (x^3 mod n) + (y^3 mod n) + (z^3 mod n) = 2n
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

use ntheory qw(powmod);
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

#~ my $n = 75;
#~ my $x = -435203231;
#~ my $y = 435203083;
#~ my $z = 4381159;

#~ my $n = 39;
#~ my $x = -159380;
#~ my $y = 134476;
#~ my $z = 117367;

my @partitions = get_partitions(2 * $n);

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
                ($k % $n == sum0(@{$s->{pos}{steps}}[0 .. $_]) + $s->{pos}{start})
                  or ($k % $n == sum0(@{$s->{neg}{steps}}[0 .. $_]) + $s->{neg}{start})
            }
            (-1 .. int(@{$s->{pos}{steps}} / 2));

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

# pp \@valid;
