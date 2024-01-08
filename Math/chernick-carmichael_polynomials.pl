#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 16 February 2020
# https://github.com/trizen

# Generate the polynomials for the extended Chernick-Carmichael numbers with n prime factors.

# OEIS sequence:
#   https://oeis.org/A318646 -- The least Chernick's "universal form" Carmichael number with n prime factors.

# See also:
#   https://oeis.org/wiki/Carmichael_numbers
#   https://www.ams.org/journals/bull/1939-45-04/S0002-9904-1939-06953-X/home.html

# The ratios sum([C(n+1)]) / sum([C(n)]), are given by the OEIS sequence A083705,
#   https://oeis.org/A083705
# where sum([C(n)]) is the sum of the coefficients of the n-th Chernick-Carmichael polynomial,

use 5.020;
use warnings;
use experimental qw(signatures);

use Math::Polynomial;
use List::Util qw(reduce);
use Math::AnyNum qw(:overload sum prod);

sub chernick_carmichael_factors ($n) {
    reduce { $a * $b } (
        Math::Polynomial->new(1, 6), Math::Polynomial->new(1, 12),
        map { Math::Polynomial->new(1, 9 << $_) } 1 .. $n - 2
    );
}

say "=> Polynomials:";
foreach my $n (3 .. 10) {
    say "C($n) = ", chernick_carmichael_factors($n);
}

say "\n=> Sum of coefficients:";
foreach my $n (3 .. 10) {
    say "sum([C($n)]) = ", sum(chernick_carmichael_factors($n)->coeff);
}

say "\n=> Product of coefficients:";
foreach my $n (3 .. 10) {
    say "prod([C($n)]) = ", prod(chernick_carmichael_factors($n)->coeff);
}

__END__
=> Polynomials:
C(3) = (1296 x^3 + 396 x^2 + 36 x + 1)
C(4) = (46656 x^4 + 15552 x^3 + 1692 x^2 + 72 x + 1)
C(5) = (3359232 x^5 + 1166400 x^4 + 137376 x^3 + 6876 x^2 + 144 x + 1)
C(6) = (483729408 x^6 + 171320832 x^5 + 20948544 x^4 + 1127520 x^3 + 27612 x^2 + 288 x + 1)
C(7) = (139314069504 x^7 + 49824129024 x^6 + 6204501504 x^5 + 345674304 x^4 + 9079776 x^3 + 110556 x^2 + 576 x + 1)
C(8) = (80244904034304 x^8 + 28838012387328 x^7 + 3623616995328 x^6 + 205312900608 x^5 + 5575625280 x^4 + 72760032 x^3 + 442332 x^2 + 1152 x + 1)
C(9) = (92442129447518208 x^9 + 33301635174236160 x^8 + 4203244791005184 x^7 + 240144078495744 x^6 + 6628433223168 x^5 + 89395182144 x^4 + 582326496 x^3 + 1769436 x^2 + 2304 x + 1)
C(10) = (212986666247081951232 x^10 + 76819409570887630848 x^9 + 9717577633650180096 x^8 + 557495201645199360 x^7 + 15512054224674816 x^6 + 212594932882944 x^5 + 1431075428928 x^4 + 4659107040 x^3 + 7077852 x^2 + 4608 x + 1)

=> Sum of coefficients:
sum([C(3)]) = 1729
sum([C(4)]) = 63973
sum([C(5)]) = 4670029
sum([C(6)]) = 677154205
sum([C(7)]) = 195697565245
sum([C(8)]) = 112917495146365
sum([C(9)]) = 130193871903758845
sum([C(10)]) = 300096874738164137725

=> Product of coefficients:
prod([C(3)]) = 18475776
prod([C(4)]) = 88394777100288
prod([C(5)]) = 532962603198108087091200
prod([C(6)]) = 15566146576014516344690540671590727680
prod([C(7)]) = 8607729694274768470180293645913878477204634698636066816
prod([C(8)]) = 355900510244809815184693136856938085570466396628469022965807673827511731486720
prod([C(9)]) = 4371202733642080997695663760838408017640388301504244892063249651693811055142174806499598124164351828951040
prod([C(10)]) = 63565858610074701536163462529753569644918704418351291678528316792385645865008717295355264067966620308836237036012393969126437841481288908800
