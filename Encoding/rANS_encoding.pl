#!/usr/bin/perl

# Basic implementation of rANS encoding.

# Reference:
#   ‎Stanford EE274: Data Compression I 2023 I Lecture 7 - ANS
#   https://youtube.com/watch?v=5Hp4bnvSjng

use 5.036;

package rANS {

    sub new {
        my ($class, $input) = @_;

        my %freq;
        my %cumul;

        ++$freq{$_} for @$input;

        my @alphabet = sort { $a <=> $b } keys %freq;

        my $t = 0;
        foreach my $s (@alphabet) {
            $cumul{$s} = $t;
            $t += $freq{$s};
        }

        my $M = $t;

        bless {
               input    => $input,
               M        => $M,
               freq     => \%freq,
               cumul    => \%cumul,
               alphabet => \@alphabet,
              }, $class;
    }

    sub divint ($x, $y) {
        use integer;
        $x / $y;
    }

    sub divrem ($x, $y) {
        use integer;
        ($x / $y, $x % $y);
    }

    sub rans_base_enc($self, $x_prev, $s) {
        my $block_id = divint($x_prev, $self->{freq}{$s});
        my $slot     = $self->{cumul}{$s} + ($x_prev % $self->{freq}{$s});
        my $x        = ($block_id * $self->{M} + $slot);
        return $x;
    }

    sub encode($self) {
        my $x = 0;
        foreach my $s (@{$self->{input}}) {
            $x = $self->rans_base_enc($x, $s);
        }
        return $x;
    }

    sub rans_base_dec($self, $x) {

        my ($block_id, $slot) = divrem($x, $self->{M});
        my $alphabet = $self->{alphabet};
        my $cumul    = $self->{cumul};

        my ($left, $right, $mid, $cmp) = (0, $#{$alphabet});

        while (1) {

            $mid = ($left + $right) >> 1;
            $cmp = ($cumul->{$alphabet->[$mid]} <=> $slot) || last;

            if ($cmp < 0) {
                $left = $mid + 1;
                $left > $right and last;
            }
            else {
                $right = $mid - 1;

                if ($left > $right) {
                    $mid -= 1;
                    last;
                }
            }
        }

        my $s      = $alphabet->[$mid];
        my $x_prev = ($block_id * $self->{freq}{$s} + $slot - $cumul->{$s});
        return ($s, $x_prev);
    }

    sub decode($self, $x, $n) {
        my @dec;
        my $s = undef;
        for (1 .. $n) {
            ($s, $x) = $self->rans_base_dec($x);
            push @dec, $s;
        }
        return [reverse @dec];
    }
}

my @seq = (1, 2, 1, 7, 8, 2, 2, 1, 3, 3, 1, 1, 1, 2);
my $obj = rANS->new(\@seq);

my $enc = $obj->encode;
my $dec = $obj->decode($enc, scalar(@seq));

say $enc;
say "@$dec";

join(' ', @seq) eq join(' ', @$dec) or die "error";
