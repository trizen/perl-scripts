#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 09 February 2016
# Website: https://github.com/trizen

# A proof of concept of a new XOR encryption algorithm, which is
# believed to be unbreakable under common methods. (with no proof, yet)

# Under development!

package Encoding::UnbreakableXOR {

    use 5.22.0;
    use strict;
    use warnings;

    no warnings 'recursion';
    use Memoize qw(memoize);

    use experimental qw(bitwise);

    memoize('_fib');
    memoize('_lucas');

    sub new {
        my ($class, $token, $key) = @_;

        my %attr = (
                    token => $token,
                    key   => $key,
                    lt    => length($token),
                    lk    => length($key),
                   );

        bless \%attr, $class;
    }

    sub _fib {
        my ($n) = @_;
        return 0 if $n == 0;
        return 1 if $n == 1;
        _fib($n - 1) + _fib($n - 2);
    }

    sub _lucas {
        my ($n) = @_;
        return 2 if $n == 0;
        return 1 if $n == 1;
        _lucas($n - 1) + _lucas($n - 2);
    }

    sub xor {
        my ($self, $i) = @_;
        my $j = $self->{lk};
        substr($self->{token}, $i * $self->{lk}, $self->{lk}) ^. reverse(
            substr(
                $i > 0 ? ($self->{chunks}[$i - 1] ^. $self->{key}) : $self->{key} ^. join(
                    '',
                    reverse sort map {
                        chr((_fib((ord($_) + 27) % 43) + _lucas((ord($_) + 31) % 41) + (++$j) * (-1)**$j) % 256)
                      } split(//, $self->{key})
                ),
                0,
                $self->{lt} - $i * $self->{lk}
                  )
        );
    }

    sub encode {
        my ($self) = @_;

        local $self->{chunks} = [];
        foreach my $i (0 .. $self->{lt} / $self->{lk}) {
            push @{$self->{chunks}}, $self->xor($i);
        }

        join('', @{$self->{chunks}});
    }

    sub decode {
        my ($self) = @_;

        local $self->{chunks} = [];

        my $bin = '';
        foreach my $i (0 .. $self->{lt} / $self->{lk}) {
            $bin .= $self->xor($i);
            push @{$self->{chunks}}, substr($self->{token}, $i * $self->{lk}, $self->{lk});
        }
        return $bin;
    }
}

use 5.22.0;

use strict;
use warnings;

use Data::Dump qw(quote);

my $token = 'The quick brown fox jumps over the lazy dog';
my $key   = "my secret key";

say "=> Info:";
say "TXT: ", quote($token);
say "KEY: ", quote($key);

say '';

my $enc_obj = Encoding::UnbreakableXOR->new($token, $key);
my $enc = $enc_obj->encode;

my $dec_obj = Encoding::UnbreakableXOR->new($enc, $key);
my $dec = $dec_obj->decode;

say "=> Chars:";
say "ENC: ", quote($enc);
say "DEC: ", quote($dec);

say '';

say "=> Bytes:";
say "ENC: ", join(' ', map { sprintf("%3d", $_) } unpack("C*", $enc));
say "DEC: ", join(' ', map { sprintf("%3d", $_) } unpack("C*", $dec));
