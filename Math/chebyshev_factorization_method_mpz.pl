#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 22 June 2020
# https://github.com/trizen

# A simple factorization method, using the Chebyshev T_n(x) polynomials, based on the identity:
#   T_{m n}(x) = T_m(T_n(x))

# where:
#   T_n(x) = (1/2) * V_n(2x, 1)

# where V_n(P, Q) is the Lucas V sequence.

# See also:
#   https://oeis.org/A001075
#   https://en.wikipedia.org/wiki/Lucas_sequence
#   https://en.wikipedia.org/wiki/Iterated_function
#   https://en.wikipedia.org/wiki/Chebyshev_polynomials

use 5.020;
use warnings;

use Math::GMPz;
use ntheory qw(todigits primes);
use experimental qw(signatures);

sub fast_lucasVmod ($P, $n, $m) {    # assumes Q = 1

    my ($V1, $V2) = (Math::GMPz::Rmpz_init_set_ui(2), Math::GMPz::Rmpz_init_set($P));
    my ($Q1, $Q2) = (Math::GMPz::Rmpz_init_set_ui(1), Math::GMPz::Rmpz_init_set_ui(1));

    foreach my $bit (todigits($n, 2)) {

        Math::GMPz::Rmpz_mul($Q1, $Q1, $Q2);
        Math::GMPz::Rmpz_mod($Q1, $Q1, $m);

        if ($bit) {
            Math::GMPz::Rmpz_mul($V1, $V1, $V2);
            Math::GMPz::Rmpz_powm_ui($V2, $V2, 2, $m);
            Math::GMPz::Rmpz_submul($V1, $Q1, $P);
            Math::GMPz::Rmpz_submul_ui($V2, $Q2, 2);
            Math::GMPz::Rmpz_mod($V1, $V1, $m);
        }
        else {
            Math::GMPz::Rmpz_set($Q2, $Q1);
            Math::GMPz::Rmpz_mul($V2, $V2, $V1);
            Math::GMPz::Rmpz_powm_ui($V1, $V1, 2, $m);
            Math::GMPz::Rmpz_submul($V2, $Q1, $P);
            Math::GMPz::Rmpz_submul_ui($V1, $Q2, 2);
            Math::GMPz::Rmpz_mod($V2, $V2, $m);
        }
    }

    Math::GMPz::Rmpz_mod($V1, $V1, $m);

    return $V1;
}

sub chebyshev_factorization ($n, $B, $A = 127) {

    # The Chebyshev factorization method, taking
    # advantage of the smoothness of p-1 or p+1.

    if (ref($n) ne 'Math::GMPz') {
        $n = Math::GMPz->new("$n");
    }

    my $x = Math::GMPz::Rmpz_init_set_ui($A);
    my $i = Math::GMPz::Rmpz_init_set_ui(2);

    Math::GMPz::Rmpz_invert($i, $i, $n);

    my sub chebyshevTmod ($A, $x) {
        Math::GMPz::Rmpz_mul_2exp($x, $x, 1);
        Math::GMPz::Rmpz_set($x, fast_lucasVmod($x, $A, $n));
        Math::GMPz::Rmpz_mul($x, $x, $i);
        Math::GMPz::Rmpz_mod($x, $x, $n);
    }

    my $g      = Math::GMPz::Rmpz_init();
    my $lnB    = log($B);
    my $primes = primes(2, $B);

    foreach my $p (@$primes) {

        chebyshevTmod($p**int($lnB / log($p)), $x);    # T_k(x) (mod n)

        Math::GMPz::Rmpz_sub_ui($g, $x, 1);
        Math::GMPz::Rmpz_gcd($g, $g, $n);

        if (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0) {
            return 1 if (Math::GMPz::Rmpz_cmp($g, $n) == 0);
            return $g;
        }
    }

    return 1;
}

foreach my $n (
#<<<
    Math::GMPz->new("4687127904923490705199145598250386612169614860009202665502614423768156352727760127429892667212102542891417456048601608730032271"),
    Math::GMPz->new("2593364104508085171532503084981517253915662037671433715309875378319680421662639847819831785007087909697206133969480076353307875655764139224094652151"),
    Math::GMPz->new("850794313761232105411847937800407457007819033797145693534409492587965757152430334305470463047097051354064302867874781454865376206137258603646386442018830837206634789761772899105582760694829533973614585552733"),
#>>>
  ) {

    say "\n:: Factoring: $n";

    my $x = 127;
    until (ntheory::is_prime($n)) {
        my $p = chebyshev_factorization($n, 500_000, $x);

        if ($p > 1) {
            say "[$x] Found factor: $p";
            $n /= $p;
        }
        else {
            ++$x;
        }
    }
}

__END__
:: Factoring: 4687127904923490705199145598250386612169614860009202665502614423768156352727760127429892667212102542891417456048601608730032271
[127] Found factor: 31935028572177122017
[127] Found factor: 441214532298715667413
[127] Found factor: 12993757635350024510533
[127] Found factor: 515113549791151291993
[127] Found factor: 55439300969660624677

:: Factoring: 2593364104508085171532503084981517253915662037671433715309875378319680421662639847819831785007087909697206133969480076353307875655764139224094652151
[127] Found factor: 1927199759971282921
[127] Found factor: 765996534730183701229
[127] Found factor: 2490501032020173490009
[127] Found factor: 31978310730830342979559
[128] Found factor: 58637507352579687279739
[128] Found factor: 4393290631695328772611

:: Factoring: 850794313761232105411847937800407457007819033797145693534409492587965757152430334305470463047097051354064302867874781454865376206137258603646386442018830837206634789761772899105582760694829533973614585552733
[127] Found factor: 556010720288850785597
[127] Found factor: 33311699120128903709
[127] Found factor: 182229202433843943841
[127] Found factor: 55554864549706093104640631
[127] Found factor: 5658991130760772523
[127] Found factor: 1021051300200039481
[127] Found factor: 386663601339343857313
[128] Found factor: 341190041753756943379
[128] Found factor: 7672247345452118779313
