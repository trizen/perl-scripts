#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 03 October 2017
# https://github.com/trizen

# Implementation of the `modular_lambda(x)` and `klein_invariant_j(x)` functions.

# See also:
#   https://oeis.org/A115977
#   https://en.wikipedia.org/wiki/J-invariant
#   https://en.wikipedia.org/wiki/Modular_lambda_function

use 5.014;
use warnings;

use Math::AnyNum qw(:overload pi);

my @A115977 = map { Math::AnyNum->new((split(' '))[-1]) } <DATA>;

sub modular_lambda {
    my ($x) = @_;

    my $sum  = 0;
    my $prev = 0;

    my $q    = exp(pi * i * $x);
    my $eps  = 2**-$Math::AnyNum::PREC;

    $q = $q->real if $q->is_real;

    foreach my $i (0 .. $#A115977) {
        $sum += $A115977[$i] * $q**($i + 1);
        last if ((abs($sum - $prev)) <= $eps);
        $prev = $sum;
    }

    return $sum;
}

sub klein_invariant_j {
    my ($x) = @_;

#<<<
    ( 4 * (1 - modular_lambda($x)     + modular_lambda($x)**2)**3) /
    (27 * (1 - modular_lambda($x))**2 * modular_lambda($x)**2);
#>>>

}

say klein_invariant_j(2 * i);                               # (11/2)^3
say klein_invariant_j(sqrt(-2))->round(-40);                # (5/3)^3
say klein_invariant_j((1 + sqrt(-163)) / 2)->round(-40);    # -53360^3

__END__
1 16
2 -128
3 704
4 -3072
5 11488
6 -38400
7 117632
8 -335872
9 904784
10 -2320128
11 5702208
12 -13504512
13 30952544
14 -68901888
15 149403264
16 -316342272
17 655445792
18 -1331327616
19 2655115712
20 -5206288384
21 10049485312
22 -19115905536
23 35867019904
24 -66437873664
25 121587699568
26 -219997823744
27 393799671680
28 -697765502976
29 1224470430560
30 -2129120769024
31 3669925002752
32 -6273295187968
33 10638472274688
34 -17904375855360
35 29914108051712
36 -49631878364160
37 81796581923552
38 -133940954877440
39 217972711694464
40 -352615521042432
41 567159563764128
42 -907197891465216
43 1443361173729344
44 -2284561115754496
45 3597986508088416
46 -5639173569598464
47 8797049785486592
48 -13661151873466368
49 21121565013141648
50 -32516981110373248
51 49853282901399936
52 -76125157989107712
53 115787750395675104
54 -175446129968544768
55 264860028797210496
56 -398403552976764928
57 597179610339831040
58 -892073853566196480
59 1328153150761957184
60 -1970983069740490752
61 2915677205543637344
