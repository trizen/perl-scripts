#!/usr/bin/perl

# The elliptic-curve factorization method (ECM), due to Hendrik Lenstra, with B2 stage.

# Code translated from the SymPy file "ntheory/ecm.py" (version 1.11.1).

package Point {

    use 5.036;
    use Math::Prime::Util::GMP qw(:all);

    if (!defined(&submod)) {
        *submod = sub ($x, $y, $m) {
            addmod($x, "-$y", $m);
        };
    }

    if (!defined(&muladdmod)) {
        *muladdmod = sub ($x, $y, $z, $m) {
            addmod(mulmod($x, $y, $m), $z, $m);
        };
    }

    sub new {
        my ($class, $x_cord, $z_cord, $a_24, $mod) = @_;
        bless {
               x_cord => $x_cord,
               z_cord => $z_cord,
               a_24   => $a_24,
               mod    => $mod,
              }, $class;
    }

    sub add ($self, $Q, $diff) {
        my $u = mulmod(submod($self->{x_cord}, $self->{z_cord}, $self->{mod}), addmod($Q->{x_cord}, $Q->{z_cord}, $self->{mod}), $self->{mod});
        my $v = mulmod(addmod($self->{x_cord}, $self->{z_cord}, $self->{mod}), submod($Q->{x_cord}, $Q->{z_cord}, $self->{mod}), $self->{mod});
        my ($add, $subt) = (addmod($u, $v, $self->{mod}), submod($u, $v, $self->{mod}));
        my $new_x_cord = mulmod($diff->{z_cord}, mulmod($add, $add, $self->{mod}), $self->{mod});
        my $new_z_cord = mulmod($diff->{x_cord}, mulmod($subt, $subt, $self->{mod}), $self->{mod});
        return Point->new($new_x_cord, $new_z_cord, $self->{a_24}, $self->{mod});
    }

    sub double ($self) {
        my ($u, $v) = (addmod($self->{x_cord}, $self->{z_cord}, $self->{mod}), submod($self->{x_cord}, $self->{z_cord}, $self->{mod}));
        ($u, $v) = (mulmod($u, $u, $self->{mod}), mulmod($v, $v, $self->{mod}));
        my $diff       = submod($u, $v, $self->{mod});
        my $new_x_cord = mulmod($u,    $v,                                                $self->{mod});
        my $new_z_cord = mulmod($diff, muladdmod($self->{a_24}, $diff, $v, $self->{mod}), $self->{mod});
        return Point->new($new_x_cord, $new_z_cord, $self->{a_24}, $self->{mod});
    }

    sub mont_ladder ($self, $k) {

        my $Q = $self;
        my $R = $self->double();

        my @bits = todigits($k, 2);
        shift @bits;

        foreach my $i (@bits) {
            if ($i eq '1') {
                $Q = $R->add($Q, $self);
                $R = $R->double();
            }
            else {
                $R = $Q->add($R, $self);
                $Q = $Q->double();
            }
        }

        return $Q;
    }
}

use 5.036;
use List::Util             qw(uniq);
use Math::Prime::Util::GMP qw(:all);

if (!defined(&submod)) {
    *submod = sub ($x, $y, $m) {
        addmod($x, "-$y", $m);
    };
}

if (!defined(&mulsubmod)) {
    *mulsubmod = sub ($x, $y, $z, $m) {
        addmod(mulmod($x, "-$y", $m), $z, $m);
    };
}

if (!defined(&muladdmod)) {
    *muladdmod = sub ($x, $y, $z, $m) {
        addmod(mulmod($x, $y, $m), $z, $m);
    };
}

sub ecm_one_factor ($n, $B1 = 10_000, $B2 = 100_000, $max_curves = 200) {

    if (($B1 % 2 == 1) or ($B2 % 2 == 1)) {
        die "The Bounds should be even integers";
    }

    is_prime($n) && return $n;

    my $D    = sqrtint($B2);
    my @beta = (0) x ($D + 1);
    my @S    = (0) x ($D + 1);

    my $k = consecutive_integer_lcm($B1);

    for (1 .. $max_curves) {

        # Suyama's paramatrization
        my $sigma = urandomr(6, subint($n, 1));
        my $u     = mulsubmod($sigma, $sigma, 5, $n);
        my $v     = mulmod($sigma, 4, $n);
        my $diff  = submod($v, $u, $n);
        my $u_3   = powmod($u, 3, $n);

        my $inv = invmod(mulmod(mulmod($u_3, $v, $n), 4, $n), $n) || return gcd(lcm($u_3, $v), $n);
        my $C   = mulsubmod(mulmod(powmod($diff, 3, $n), muladdmod(3, $u, $v, $n), $n), $inv, 2, $n);

        my $a24 = divmod(addmod($C, 2, $n), 4, $n);
        my $Q   = Point->new($u_3, powmod($v, 3, $n), $a24, $n);
        $Q = $Q->mont_ladder($k);
        my $g = gcd($Q->{z_cord}, $n);

        # Stage 1 factor
        if ($g > 1 and $g < $n) {
            return $g;
        }

        # Stage 1 failure. Q.z = 0, Try another curve
        elsif ($g == $n) {
            next;
        }

        # Stage 2 - Improved Standard Continuation
        $S[1]    = $Q->double();
        $S[2]    = $S[1]->double();
        $beta[1] = mulmod($S[1]->{x_cord}, $S[1]->{z_cord}, $n);
        $beta[2] = mulmod($S[2]->{x_cord}, $S[2]->{z_cord}, $n);

        foreach my $d (3 .. $D) {
            $S[$d]    = $S[$d - 1]->add($S[1], $S[$d - 2]);
            $beta[$d] = mulmod($S[$d]->{x_cord}, $S[$d]->{z_cord}, $n);
        }

        $g = 1;
        my $B = $B1 - 1;
        my $T = $Q->mont_ladder($B - 2 * $D);
        my $R = $Q->mont_ladder($B);

        for (my $r = $B ; $r <= $B2 ; $r += 2 * $D) {
            my $alpha = mulmod($R->{x_cord}, $R->{z_cord}, $n);

            foreach my $q (sieve_primes($r + 2, 2 * $D + $r)) {
                my $delta = ($q - $r) >> 1;

                $g = mulmod(
                            $g,
                            addmod(
                                   submod(
                                          mulmod(submod($R->{x_cord}, $S[$delta]->{x_cord}, $n), addmod($R->{z_cord}, $S[$delta]->{z_cord}, $n), $n),
                                          $alpha, $n
                                         ),
                                   $beta[$delta],
                                   $n
                                  ),
                            $n
                           );
            }

            # Swap
            ($T, $R) = ($R, $R->add($S[$D], $T));
        }

        $g = gcd($n, $g);

        # Stage 2 Factor found
        if ($g > 1 and $g < $n) {
            return $g;
        }
    }

    # ECM failed, Increase the bounds
    die "Increase the bounds";
}

# Params from:
#   https://www.rieselprime.de/ziki/Elliptic_curve_method

my @ECM_PARAMS = (

    # d      B1     curves
    [10, 360,        7],
    [15, 2000,       25],
    [20, 11000,      90],
    [25, 50000,      300],
    [30, 250000,     700],
    [35, 1000000,    1800],
    [40, 3000000,    5100],
    [45, 11000000,   10600],
    [50, 43000000,   19300],
    [55, 110000000,  49000],
    [60, 260000000,  124000],
    [65, 850000000,  210000],
    [70, 2900000000, 340000],
                 );

sub ecm ($n, $B1 = undef, $B2 = undef, $max_curves = undef) {

    $n <= 1 and die "n must be greater than 1";

    if (!defined($B1)) {
        foreach my $row (@ECM_PARAMS) {
            my ($d, $B1, $curves) = @$row;
            ## say ":: Trying to find a prime factor with $d digits using B1 = $B1 with $curves curves";
            my @f = eval { __SUB__->($n, $B1, $B1 * 50, $curves) };
            return @f if !$@;
        }
    }

    state $primorial = primorial(100_000);

    my @factors;
    my $g = gcd($n, $primorial);

    if ($g > 1) {
        push @factors, factor($g);
        foreach my $p (@factors) {
            $n = divint($n, powint($p, valuation($n, $p)));
        }
    }

    while ($n > 1) {
        my $factor = eval { ecm_one_factor($n, $B1, $B2, $max_curves) };

        if ($@) {
            die "Failed to factor $n: $@";
        }

        push @factors, $factor;
        $n = divint($n, powint($factor, valuation($n, $factor)));
    }

    @factors = uniq(@factors);

    my @final_factors;
    foreach my $factor (@factors) {
        if (is_prime($factor)) {
            push @final_factors, $factor;
        }
        else {
            push @final_factors, __SUB__->($factor, $B1, $B2, $max_curves);
        }
    }

    return sort { $a <=> $b } @final_factors;
}

say join ' * ', ecm('314159265358979323');                #=> 317213509 * 990371647
say join ' * ', ecm('14304849576137459');                 #=> 16100431 * 888476189
say join ' * ', ecm('9804659461513846513');               #=> 4641991 * 2112166839943
say join ' * ', ecm('25645121643901801');                 #=> 5394769 * 4753701529
say join ' * ', ecm('17177619065692036843');              #=> 2957613037 * 5807933239
say join ' * ', ecm('195905123644566489241411490581');    #=> 259719190596553 * 754295911652077

say join ' * ', ecm(addint(powint(2, 64), 1));            #=> 274177 * 67280421310721
say join ' * ', ecm(subint(powint(2, 128), 1));           #=> 3 * 5 * 17 * 257 * 641 * 65537 * 274177 * 6700417 * 67280421310721
say join ' * ', ecm(addint(powint(2, 128), 1));           #=> 59649589127497217 * 5704689200685129054721
