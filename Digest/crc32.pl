#!usr/bin/perl

# Simple implementation of the Cyclic Redundancy Check (CRC32).

# Reference:
#   https://web.archive.org/web/20240718094514/https://rosettacode.org/wiki/CRC-32

use 5.036;

sub create_table() {
    my @table;
    for my $i (0 .. 255) {
        my $k = $i;
        for (0 .. 7) {
            if ($k & 1) {
                $k >>= 1;
                $k ^= 0xedb88320;
            }
            else {
                $k >>= 1;
            }
        }
        push @table, $k;
    }
    return \@table;
}

sub crc32($str, $crc = 0) {
    state $crc_table = create_table();
    $crc ^= 0xffffffff;
    foreach my $c (unpack("C*", $str)) {
        $crc = ($crc >> 8) ^ $crc_table->[($crc & 0xff) ^ $c];
    }
    return ($crc ^ 0xffffffff);
}

say crc32 "The quick brown fox jumps over the lazy dog";
say crc32("over the lazy dog", crc32("The quick brown fox jumps "));
