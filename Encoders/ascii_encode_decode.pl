#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 25 July 2012
# https://github.com/trizen

# A simple ASCII encoder-decoder.

# What's special is that you can delete words from the encoded text, and still be able to decode it.
# You can also insert or append encoded words to an encoded string and decode it later.

use 5.010;
use strict;
use warnings;

sub encode_decode ($$) {
    my ($encode, $text) = @_;

    my $i = 1;
    my $output = '';

  LOOP_1: foreach my $c (map ord, split //, $text) {
        foreach my $o ([32, 121]) {
            if ($c > $o->[0] && $c <= $o->[1]) {

                my $ord = $encode
                        ? $c + ($i % 2 ? $i : -$i)
                        : $c - ($i % 2 ? $i : -$i);

                if ($ord > $o->[1]) {
                    $ord = $o->[0] + ($ord - $o->[1]);
                }
                elsif ($ord <= $o->[0]) {
                    $ord = $o->[1] - ($o->[0] - $ord);
                }
                $output .= chr $ord;
                ++$i; next LOOP_1;
            }
        }
        $output .= chr;
        $i = 1;
    }

    return $output;
}

my $enc = encode_decode(1, q{test});
my $dec = encode_decode(0, $enc);

say "Enc: ", $enc;
say "Dec: ", $dec;

__END__
# Encoding
my $encoded = encode_decode(1, "Just another ")
            . encode_decode(1, "Perl hacker,");

# Decoding
my $decoded = encode_decode(0, $encoded);

say $encoded;
say $decoded;

__END__

my $text = "Just another Perl hacker,";

# Encoding
my $encoded = encode_decode(1, $text );

# Decoding
my $decoded = encode_decode(0, $encoded);
