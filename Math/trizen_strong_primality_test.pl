#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 02 August 2017
# Edit: 30 November 2019
# https://github.com/trizen

# A very strong primality test (v4), inspired by Fermat's Little Theorem and the AKS test.

# Known counter-example to the weak version:
#   83143326880201568435669099604552661

# When combined with a strong Fermat base-2 primality test, no counter-examples are known.

# See also:
#   https://oeis.org/A175530
#   https://oeis.org/A175531
#   https://oeis.org/A299799

use 5.020;
use strict;
use warnings;

no warnings 'recursion';

use ntheory qw(is_prime powmod is_strong_pseudoprime);
use experimental qw(signatures);

sub mulmod {
    my ($n, $k, $mod) = @_;

    ref($mod)
        ? ((($n % $mod) * $k) % $mod)
        : ntheory::mulmod($n, $k, $mod);
}

# Additional matrix of parameters (also only with one counter-example known: 5902446537594114481):
#   [1, 1,  617, -127],
#   [2, 1, -647,  163],
#   [3, 1, -967,  953],
#   [4, 1, -263, -691],
#   [5, 1, -743,  241],

#
## Creates the `modulo_test*` subroutines.
#
foreach my $g (
    [1, 1, -353, -829],
    [2, 1, -983, -911],
    [3, 1,  149,   83],
    [4, 1,  271,  191],
    [5, 1, -461, -491],
) {

    no strict 'refs';
    *{__PACKAGE__ . '::' . 'modulo_test' . $g->[0]} = sub ($n, $mod) {
        my %cache;

        sub ($n) {

            $n == 0 && return $g->[1];
            $n == 1 && return $g->[2];

            if (exists $cache{$n}) {
                return $cache{$n};
            }

            my $k = $n >> 1;

#<<<
            $cache{$n} = (
                $n % 2 == 0
                    ? (mulmod(__SUB__->($k), __SUB__->($k),   $mod) - mulmod(mulmod($g->[3], __SUB__->($k-1), $mod), __SUB__->($k-1), $mod)) % $mod
                    : (mulmod(__SUB__->($k), __SUB__->($k+1), $mod) - mulmod(mulmod($g->[3], __SUB__->($k-1), $mod), __SUB__->($k),   $mod)) % $mod
            );
#>>>

          }->($n - 1);
    };
}

sub is_probably_prime($n) {

    $n <= 1 && return 0;

    foreach my $p (2, 3, 5, 7, 11, 17, 19, 23, 43, 79, 181, 1151, 6607, 14057) {
        if ($n == $p) {
            return 1;
        }
    }

    is_strong_pseudoprime($n, 2) || return 0;

    my $r1 = modulo_test1($n, $n);
    ($r1 == 1) or ($r1 == $n-1) or return 0;

    my $r2 = modulo_test2($n, $n);
    ($r2 == 1) or ($r2 == $n-1) or return 0;

    my $r3 = modulo_test3($n, $n);
    ($r3 == 1) or ($r3 == $n-1) or return 0;

    my $r4 = modulo_test4($n, $n);
    ($r4 == 1) or ($r4 == $n-1) or return 0;

    my $r5 = modulo_test5($n, $n);
    ($r5 == 1) or ($r5 == $n-1) or return 0;
}

#
## Run a few tests
#

say "=> Testing a few small prime numbers";
say is_probably_prime(6760517005636313)   ? 'prime' : 'error';    #=> prime
say is_probably_prime(204524538079257577) ? 'prime' : 'error';    #=> prime
say is_probably_prime(904935283655003749) ? 'prime' : 'error';    #=> prime

# Big integers
eval {
    require Math::GMPz;

    say "\n=> Testing a few Carmichael numbers...";

    while (defined(my $n = <DATA>)) {
        chomp($n);
        if (is_probably_prime(Math::GMPz->new($n))) {
            say "Counter-example: $n";
        }
    }

    say "\n=> Testing larger prime numbers...";

    say is_probably_prime(Math::GMPz->new('90123127846128741241234935283655003749'))                             ? 'prime' : 'error';    #=> prime
    say is_probably_prime(Math::GMPz->new('793534607085486631526003804503819188867498912352777'))                ? 'prime' : 'error';    #=> prime
    say is_probably_prime(Math::GMPz->new('6297842947207644396587450668076662882608856575233692384596461'))      ? 'prime' : 'error';    #=> prime
    say is_probably_prime(Math::GMPz->new('396090926269155174167385236415542573007935497117155349994523806173')) ? 'prime' : 'error';    #=> prime

    say "\n=> Testing a few composite numbers...";

    say is_probably_prime(Math::GMPz->new('2380296518909971201')) ? 'error' : 'composite';
    say is_probably_prime(Math::GMPz->new('3188618003602886401')) ? 'error' : 'composite';

    say "\n=> Testing a few large Mersenne primes...";

    # Mersenne primes
    say is_probably_prime(Math::GMPz->new(2)**127  - 1) ? 'prime' : 'error';   #=> prime
    say is_probably_prime(Math::GMPz->new(2)**521  - 1) ? 'prime' : 'error';   #=> prime
    say is_probably_prime(Math::GMPz->new(2)**1279 - 1) ? 'prime' : 'error';   #=> prime
    say is_probably_prime(Math::GMPz->new(2)**3217 - 1) ? 'prime' : 'error';   #=> prime
    say is_probably_prime(Math::GMPz->new(2)**4423 - 1) ? 'prime' : 'error';   #=> prime
};

say "\n=> Searching for small counter-examples...";

# Look for counter-examples
foreach my $n (1 .. 15000) {
    if (is_probably_prime($n)) {

        if (not is_prime($n)) {
            warn "Counter-example: $n\n";
        }
    }
    elsif (is_prime($n)) {
        warn "Missed a prime: $n\n";
    }
}

__END__
208969201
1027334881
1574601601
3711456001
23562188821
30304281601
30680814529
58891472641
120871699201
260245228321
359505020161
373523673601
377555665201
774558925921
860293156801
986308202881
1352358402913
3226057632001
6477654268801
6615533841841
7954028515441
9049836479041
9173203300801
9599057610241
27192146983681
40395626998273
46843949912257
52451136349921
74820786179329
122570307044209
227291059980601
360570785364001
443372888629441
539956339242241
921259517831137
1428360123889921
1543272305769601
1738925896140049
5539588182853381
11674038748806721
26857102685439041
32334452526861101
39671149333495681
598963244103226621
842526563598720001
843347325974413121
883253991797747461
934216077330841537
2380296518909971201
3188618003602886401
5151560903656250449
5902446537594114481
9610653088766378881
10021721082510591541
13938032454972692851
64296323802158793601
99270776480238208441
229386598589242644481
512617191379440810961
3104745148145953757281
8273838687436582743601
25214682289344970125061
176639720841995571276421
407333160866845741098841
594984649904873169943321
1107852524534142074314801
5057462719726630861278061
83143326880201568435669099604552661
