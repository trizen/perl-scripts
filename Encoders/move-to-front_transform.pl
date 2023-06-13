#!/usr/bin/perl

# Author: Trizen
# Date: 13 June 2023
# https://github.com/trizen

# The Move to Front transform (MTF).

# Reference:
#   COMP526 Unit 7-6 2020-03-24 Compression - Move-to-front transform
#   https://youtube.com/watch?v=Q2pinaj3i9Y

use 5.036;

sub mtf_encode ($bytes, $alphabet = [0 .. 255]) {

    my @C;

    my @table;
    @table[@$alphabet] = (0 .. $#{$alphabet});

    foreach my $c (@$bytes) {
        push @C, (my $index = $table[$c]);
        unshift(@$alphabet, splice(@{$alphabet}, $index, 1));
        @table[@{$alphabet}[0 .. $index]] = (0 .. $index);
    }

    return \@C;
}

sub mtf_decode ($encoded, $alphabet = [0 .. 255]) {

    my @S;

    foreach my $p (@$encoded) {
        push @S, $alphabet->[$p];
        unshift(@$alphabet, splice(@{$alphabet}, $p, 1));
    }

    return \@S;
}

my $str = "INEFICIENCIES";

my $encoded = mtf_encode([unpack('C*', $str)], [ord('A') .. ord('Z')]);
my $decoded = mtf_decode($encoded, [ord('A') .. ord('Z')]);

say "Encoded: ", "@$encoded";              #=> Encoded: 8 13 6 7 3 6 1 3 4 3 3 3 18
say "Decoded: ", pack('C*', @$decoded);    #=> Decoded: INEFICIENCIES

$str eq pack('C*', @$decoded) or die "error";

{
    open my $fh, '<:raw', __FILE__;
    my $str     = do { local $/; <$fh> };
    my $encoded = mtf_encode([unpack('C*', $str)]);
    my $decoded = mtf_decode($encoded);
    $str eq pack('C*', @$decoded) or die "error";
}
