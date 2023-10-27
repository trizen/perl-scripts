#!/usr/bin/perl

# The elliptic-curve factorization method (ECM), due to Hendrik Lenstra, with B2 stage.

# Code translated from the SymPy file "ntheory/ecm.py" (version 1.11.1).

# This implementation requires the latest GitHub version of Math::Prime::Util::GMP.

package Point {

    use 5.036;
    use ntheory                qw(todigitstring);
    use Math::Prime::Util::GMP qw(:all);

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

        foreach my $i (split(//, substr(todigitstring($k, 2), 1))) {
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
use Math::Prime::Util::GMP qw(:all);
use List::Util             qw(uniq);

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

sub ecm ($n, $B1 = 10_000, $B2 = 100_000, $max_curves = 200) {

    $n <= 1 and die "n must be greater than 1";

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

say join ' * ', ecm("314159265358979323",  100, 1000);    #=> 317213509 * 990371647
say join ' * ', ecm("14304849576137459",   100, 1000);    #=> 16100431 * 888476189
say join ' * ', ecm("9804659461513846513", 100, 1000);    #=> 4641991 * 2112166839943
say join ' * ', ecm("25645121643901801",   100, 1000);    #=> 5394769 * 4753701529

say join ' * ', ecm(addint(powint(2, 64), 1),  100,   1000);      #=> 274177 * 67280421310721
say join ' * ', ecm(subint(powint(2, 128), 1), 100,   1000);      #=> 3 * 5 * 17 * 257 * 641 * 65537 * 274177 * 6700417 * 67280421310721
say join ' * ', ecm(addint(powint(2, 128), 1), 10000, 100000);    #=> 59649589127497217 * 5704689200685129054721 (takes ~10 seconds)
