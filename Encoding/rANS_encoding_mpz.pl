#!/usr/bin/perl

# Basic implementation of rANS encoding.

# Reference:
#   ‎Stanford EE274: Data Compression I 2023 I Lecture 7 - ANS
#   https://youtube.com/watch?v=5Hp4bnvSjng

use 5.036;
use Math::GMPz;

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

    sub rans_base_enc($self, $x_prev, $s, $block_id, $x) {

        Math::GMPz::Rmpz_div_ui($block_id, $x_prev, $self->{freq}{$s});

        my $r    = Math::GMPz::Rmpz_mod_ui($x, $x_prev, $self->{freq}{$s});
        my $slot = $self->{cumul}{$s} + $r;

        Math::GMPz::Rmpz_mul_ui($x, $block_id, $self->{M});
        Math::GMPz::Rmpz_add_ui($x, $x, $slot);

        return $x;
    }

    sub encode($self) {

        my $x        = Math::GMPz::Rmpz_init_set_ui(0);
        my $block_id = Math::GMPz::Rmpz_init();
        my $next_x   = Math::GMPz::Rmpz_init();

        foreach my $s (@{$self->{input}}) {
            $x = $self->rans_base_enc($x, $s, $block_id, $next_x);
        }
        return $x;
    }

    sub rans_base_dec($self, $x, $block_id, $slot, $x_prev) {

        Math::GMPz::Rmpz_tdiv_qr_ui($block_id, $slot, $x, $self->{M});

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

        my $s = $alphabet->[$mid];

        Math::GMPz::Rmpz_mul_ui($x_prev, $block_id, $self->{freq}{$s});
        Math::GMPz::Rmpz_add($x_prev, $x_prev, $slot);
        Math::GMPz::Rmpz_sub_ui($x_prev, $x_prev, $cumul->{$s});

        return ($s, $x_prev);
    }

    sub decode($self, $x, $n) {
        my @dec;
        my $s = undef;

        my $block_id = Math::GMPz::Rmpz_init();
        my $slot     = Math::GMPz::Rmpz_init();
        my $x_prev   = Math::GMPz::Rmpz_init();

        for (1 .. $n) {
            ($s, $x) = $self->rans_base_dec($x, $block_id, $slot, $x_prev);
            push @dec, $s;
        }
        return [reverse @dec];
    }
}

my @seq = do {
    open my $fh, '<:raw', __FILE__;
    local $/;
    unpack('C*', <$fh>);
};

my $obj = rANS->new(\@seq);

my $enc = $obj->encode;
my $dec = $obj->decode($enc, scalar(@seq));

say $enc;

join(' ', @seq) eq join(' ', @$dec) or die "error";
