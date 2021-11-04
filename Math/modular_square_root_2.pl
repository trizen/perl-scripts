#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 21 July 2018
# https://github.com/trizen

# Find (almost) all solutions to the quadratic congruence:
#   x^2 = a (mod n)

use 5.020;
use warnings;

use experimental qw(signatures);

use List::Util qw(uniq);
use ntheory qw(factor_exp chinese forsetproduct);
use Math::Prime::Util::GMP qw(sqrtmod);
use Math::AnyNum qw(:overload powmod ipow);

sub sqrt_mod_n ($z, $n) {

    my @roots = sub ($z, $n) {

        return 0  if ($n == 1);
        return () if ($n < 1);

        $z %= $n;

        return $n if ($z == 0);

        my %congruences;

        foreach my $factor (factor_exp($n)) {

            my ($p, $e) = @$factor;
            my $pp = ipow($p, $e);

            if ($p eq '2') {

                if ($e == 1) {
                    if ($z & 1) {
                        push @{$congruences{$pp}}, [1, $pp];
                    }
                    else {
                        push @{$congruences{$pp}}, [0, $pp];
                    }
                }
                elsif ($e == 2) {
                    if ($z % 4 == 1) {
                        push @{$congruences{$pp}}, [1, $pp], [3, $pp];
                    }
                    else {
                        push @{$congruences{$pp}}, [0, $pp], [2, $pp];
                    }
                }
                elsif ($e == 3) {
                    if ($z % 8 == 1) {
                        push @{$congruences{$pp}}, [1, $pp], [3, $pp], [5, $pp], [7, $pp];
                    }
                    else {
                        push @{$congruences{$pp}}, [0, $pp], [2, $pp], [4, $pp], [6, $pp];
                    }
                }
                elsif ($z == 1) {
                    push @{$congruences{$pp}}, [1, $pp], [($pp >> 1) - 1, $pp], [($pp >> 1) + 1, $pp], [$pp - 1, $pp];
                }

                foreach my $s (__SUB__->($z, $pp >> 1)) {

                    my $i = ((($s * $s - $z) >> ($e - 1)) % 2);
                    my $r = ($s + ($i << ($e - 2)));

                    push @{$congruences{$pp}}, [$r, $pp], [$pp - $r, $pp];
                }

                next;
            }

            $p = Math::AnyNum->new($p);
            my $x = sqrtmod($z, $p) // next;   # Tonelli-Shanks algorithm
            my $r = $pp / $p;
            my $u = ($pp - 2 * $r + 1) >> 1;
            my $t = (powmod($x, $r, $pp) * powmod($z, $u, $pp)) % $pp;
            push @{$congruences{$pp}}, [$t, $pp], [$pp - $t, $pp];
        }

        my @roots;

        forsetproduct {
            push @roots, chinese(@_);
        } values %congruences;

        return grep { powmod($_, 2, $n) == $z } uniq(@roots);
    }->($z, $n);

    sort { $a <=> $b } @roots;
}

my @tests = ([1104, 6630], [2641, 4465], [993, 2048], [472, 972], [441, 920], [841, 905], [289, 992],);

sub bf_sqrtmod ($z, $n) {
    grep { ($_ * $_) % $n == $z } 1 .. $n;
}

foreach my $t (@tests) {
    my @r = sqrt_mod_n($t->[0], $t->[1]);
    say "x^2 = $t->[0] (mod $t->[1]) = {", join(', ', @r), "}";
    die "error1 for (@$t) -- @r" if (@r != grep { ($_ * $_) % $t->[1] == $t->[0] } @r);
    die "error2 for (@$t) -- @r" if (join(' ', @r) ne join(' ', bf_sqrtmod($t->[0], $t->[1])));
}

say '';

# The algorithm also works for arbitrary large integers
say join(' ', sqrt_mod_n(13**18 * 5**7 - 1, 13**18 * 5**7));    #=> 633398078861605286438568 2308322911594648160422943 6477255756527023177780182 8152180589260066051764557

foreach my $n (1 .. 100) {
    my $m = int(rand(10000));
    my $z = int(rand($m));

    my @a1 = sqrt_mod_n($z, $m);
    my @a2 = bf_sqrtmod($z, $m);

    if ("@a1" ne "@a2") {
        warn "\nerror for ($z, $m):\n\t(@a1) != (@a2)\n";
    }
}

say '';

# Too few solutions for some inputs
say 'x^2 = 1701 (mod 6300) = {' . join(' ', sqrt_mod_n(1701, 6300)) . '}';
say 'x^2 = 1701 (mod 6300) = {' . join(', ', bf_sqrtmod(1701, 6300)) . '}';

# No solutions for some inputs (although solutions do exist)
say join(' ', sqrt_mod_n(306,   810));
say join(' ', sqrt_mod_n(2754,  6561));
say join(' ', sqrt_mod_n(17640, 48465));

__END__
x^2 = 1104 (mod 6630) = {642, 1152, 1968, 2478, 4152, 4662, 5478, 5988}
x^2 = 2641 (mod 4465) = {1501, 2071, 2394, 2964}
x^2 = 993 (mod 2048) = {369, 655, 1393, 1679}
x^2 = 472 (mod 972) = {38, 448, 524, 934}
x^2 = 441 (mod 920) = {21, 71, 159, 209, 251, 301, 389, 439, 481, 531, 619, 669, 711, 761, 849, 899}
x^2 = 841 (mod 905) = {29, 391, 514, 876}
x^2 = 289 (mod 992) = {17, 79, 417, 479, 513, 575, 913, 975}
