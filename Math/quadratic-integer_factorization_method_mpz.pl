#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 28 June 2020
# https://github.com/trizen

# A simple factorization method, using quadratic integers.
# Similar in flavor to Pollard's p-1 and Williams's p+1 methods.

# See also:
#   https://en.wikipedia.org/wiki/Quadratic_integer

use 5.020;
use warnings;

use Math::GMPz;
use ntheory qw(:all);
use experimental qw(signatures);

sub quadratic_powmod ($a, $b, $w, $n, $m) {

    state $t = Math::GMPz::Rmpz_init_nobless();

    my $x = Math::GMPz::Rmpz_init_set_ui(1);
    my $y = Math::GMPz::Rmpz_init_set_ui(0);

    do {

        if ($n & 1) {
            # (x, y) = ((a*x + b*y*w) % m, (a*y + b*x) % m)
            Math::GMPz::Rmpz_mul_ui($t, $b, $w);
            Math::GMPz::Rmpz_mul($t, $t, $y);
            Math::GMPz::Rmpz_addmul($t, $a, $x);
            Math::GMPz::Rmpz_mul($y, $y, $a);
            Math::GMPz::Rmpz_addmul($y, $x, $b);
            Math::GMPz::Rmpz_mod($x, $t, $m);
            Math::GMPz::Rmpz_mod($y, $y, $m);
        }

        # (a, b) = ((a*a + b*b*w) % m, (2*a*b) % m)
        Math::GMPz::Rmpz_mul($t, $a, $b);
        Math::GMPz::Rmpz_mul_2exp($t, $t, 1);
        Math::GMPz::Rmpz_powm_ui($a, $a, 2, $m);
        Math::GMPz::Rmpz_powm_ui($b, $b, 2, $m);
        Math::GMPz::Rmpz_addmul_ui($a, $b, $w);
        Math::GMPz::Rmpz_mod($b, $t, $m);

    } while ($n >>= 1);

    Math::GMPz::Rmpz_set($a, $x);
    Math::GMPz::Rmpz_set($b, $y);
}

sub quadratic_factorization ($n, $B, $a = 3, $b = 4, $w = 2) {

    if (ref($n) ne 'Math::GMPz') {
        $n = Math::GMPz->new("$n");
    }

    $a = Math::GMPz::Rmpz_init_set_ui($a);
    $b = Math::GMPz::Rmpz_init_set_ui($b);

    my $g = Math::GMPz::Rmpz_init();

    my $lnB = log($B);

    foreach my $p (@{primes(sqrtint($B))}) {
        quadratic_powmod($a, $b, $w, $p**int($lnB / log($p)), $n);
    }

    foreach my $p (@{primes(sqrtint($B) + 1, $B)}) {

        quadratic_powmod($a, $b, $w, $p, $n);
        Math::GMPz::Rmpz_gcd($g, $b, $n);

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

    until (is_prime($n)) {

        my ($a, $b, $w) = (int(rand(1e6)), int(rand(1e6)), int(rand(1e6)));

        #say "\n# Trying with parameters = ($a, $b, $w)";
        my $p = quadratic_factorization($n, 500_000, $a, $b, $w);

        if ($p > 1) {
            say "-> Found factor: $p";
            $n /= $p;
        }
    }
}

__END__
:: Factoring: 4687127904923490705199145598250386612169614860009202665502614423768156352727760127429892667212102542891417456048601608730032271
-> Found factor: 12993757635350024510533
-> Found factor: 31935028572177122017
-> Found factor: 441214532298715667413
-> Found factor: 515113549791151291993
-> Found factor: 896466791041143516471427

:: Factoring: 2593364104508085171532503084981517253915662037671433715309875378319680421662639847819831785007087909697206133969480076353307875655764139224094652151
-> Found factor: 2490501032020173490009
-> Found factor: 1927199759971282921
-> Found factor: 58637507352579687279739
-> Found factor: 765996534730183701229
-> Found factor: 4393290631695328772611
-> Found factor: 85625333993726265061

:: Factoring: 850794313761232105411847937800407457007819033797145693534409492587965757152430334305470463047097051354064302867874781454865376206137258603646386442018830837206634789761772899105582760694829533973614585552733
-> Found factor: 556010720288850785597
-> Found factor: 341190041753756943379
-> Found factor: 33311699120128903709
-> Found factor: 7672247345452118779313
-> Found factor: 182229202433843943841
-> Found factor: 5658991130760772523
-> Found factor: 386663601339343857313
-> Found factor: 55554864549706093104640631
-> Found factor: 775828538119834346827
