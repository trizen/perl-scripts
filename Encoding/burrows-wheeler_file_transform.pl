#!/usr/bin/perl

# Author: Trizen
# Date: 14 June 2023
# Edit: 17 September 2023
# https://github.com/trizen

# Apply the Burrows–Wheeler transform on a file.
# https://rosettacode.org/wiki/Burrows–Wheeler_transform

# References:
#   Data Compression (Summer 2023) - Lecture 12 - The Burrows-Wheeler Transform (BWT)
#   https://youtube.com/watch?v=rQ7wwh4HRZM
#
#   Data Compression (Summer 2023) - Lecture 13 - BZip2
#   https://youtube.com/watch?v=cvoZbBZ3M2A

use 5.036;

use Getopt::Std    qw(getopts);
use File::Basename qw(basename);

use constant {
              LOOKAHEAD_LEN => 128,    # lower values are usually faster
             };

sub bwt_sort ($s) {    # O(n * LOOKAHEAD_LEN) space (fast)
    my $len      = length($s);
    my $double_s = $s . $s;                  # Pre-compute doubled string

    # Schwartzian transform with optimized sorting
    return [
        map  { $_->[1] }
        sort { ($a->[0] cmp $b->[0]) || (substr($double_s, $a->[1], $len) cmp substr($double_s, $b->[1], $len)) }
        map {
            my $pos = $_;
            my $end = $pos + LOOKAHEAD_LEN;

            # Handle wraparound efficiently
            my $t =
              ($end <= $len)
              ? substr($s,        $pos, LOOKAHEAD_LEN)
              : substr($double_s, $pos, LOOKAHEAD_LEN);

            [$t, $pos]
          } 0 .. $len - 1
    ];
}

sub bwt_encode ($s) {

    my $bwt = bwt_sort($s);

    my $ret = '';
    my $idx = 0;

    my $i = 0;
    foreach my $pos (@$bwt) {
        $ret .= substr($s, $pos - 1, 1);
        $idx = $i if !$pos;
        ++$i;
    }

    return ($ret, $idx);
}

sub bwt_decode ($bwt, $idx) {    # fast inversion: O(n * log(n))

    my @tail = split(//, $bwt);
    my @head = sort @tail;

    if ($idx > $#head) {
        die "Invalid bwt-index: $idx (must be <= $#head)\n";
    }

    my %indices;
    foreach my $i (0 .. $#tail) {
        push @{$indices{$tail[$i]}}, $i;
    }

    my @table;
    foreach my $v (@head) {
        push @table, shift(@{$indices{$v}});
    }

    my $dec = '';
    my $i   = $idx;

    for (1 .. scalar(@head)) {
        $dec .= $head[$i];
        $i = $table[$i];
    }

    return $dec;
}

getopts('dh', \my %opts);

if ($opts{h} or !@ARGV) {
    die "usage: $0 [-d] [input file] [output file]\n";
}

my $input_file  = $ARGV[0];
my $output_file = $ARGV[1] // (basename($input_file) . ($opts{d} ? '.dec' : '.bw'));

my $content = do {
    open my $fh, '<:raw', $input_file
      or die "Can't open file <<$input_file>> for reading: $!";
    local $/;
    <$fh>;
};

if ($opts{d}) {    # decode mode
    my $idx = unpack('N', substr($content, 0, 4, ''));
    my $dec = bwt_decode($content, $idx);

    open my $out_fh, '>:raw', $output_file
      or die "Can't open file <<$output_file>> for writing: $!";

    print $out_fh $dec;
}
else {
    my ($bwt, $idx) = bwt_encode($content);

    open my $out_fh, '>:raw', $output_file
      or die "Can't open file <<$output_file>> for writing: $!";

    print $out_fh pack('N', $idx);
    print $out_fh $bwt;
}
