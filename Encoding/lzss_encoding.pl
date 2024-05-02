#!/usr/bin/perl

# Author: Trizen
# Date: 02 May 2024
# https://github.com/trizen

# Simple implementation of LZSS encoding.

use 5.036;

sub lzss_encode ($str) {

    my $la = 0;

    my $prefix = '';
    my @chars  = split(//, $str);
    my $end    = $#chars;

    my $min_len = 3;
    my $max_len = 255;

    my (@literals, @distances, @lengths);

    while ($la <= $end) {

        my $n = 1;
        my $p = length($prefix);
        my $tmp;

        my $token = $chars[$la];

        while (    $n <= $max_len
               and $la + $n <= $end
               and ($tmp = rindex($prefix, $token, $p)) >= 0) {
            $p = $tmp;
            $token .= $chars[$la + $n];
            ++$n;
        }

        --$n;

        if ($n >= $min_len) {

            push @lengths,   $n;
            push @distances, $la - $p;
            push @literals,  $chars[$la + $n];

            $la += $n + 1;
            $prefix .= $token;
        }
        else {
            my @bytes = split(//, substr($prefix, $p, $n) . $chars[$la + $n]);

            push @lengths,   (0) x scalar(@bytes);
            push @distances, (0) x scalar(@bytes);
            push @literals, @bytes;

            $la += $n + 1;
            $prefix .= $token;
        }
    }

    return (\@literals, \@distances, \@lengths);
}

sub lzss_decode ($literals, $distances, $lengths) {

    my $chunk  = '';
    my $offset = 0;

    foreach my $i (0 .. $#$literals) {
        $chunk .= substr($chunk, $offset - $distances->[$i], $lengths->[$i]) . $literals->[$i];
        $offset += $lengths->[$i] + 1;
    }

    return $chunk;
}

my $string = "TOBEORNOTTOBEORTOBEORNOT";

my ($literals, $distances, $lengths) = lzss_encode($string);
my $decoded = lzss_decode($literals, $distances, $lengths);

$string eq $decoded or die "error: <<$string>> != <<$decoded>>";

foreach my $i (0 .. $#$literals) {
    say "$literals->[$i] -- [$distances->[$i], $lengths->[$i]]";
}

foreach my $file (__FILE__, $^X) {    # several tests

    my $string = do {
        open my $fh, '<:raw', $file or die "error for <<$file>>: $!";
        local $/;
        <$fh>;
    };

    my ($literals, $distances, $lengths) = lzss_encode($string);
    my $decoded = lzss_decode($literals, $distances, $lengths);

    $string eq $decoded or die "error: <<$string>> != <<$decoded>>";
}

__END__
T -- [0, 0]
O -- [0, 0]
B -- [0, 0]
E -- [0, 0]
O -- [0, 0]
R -- [0, 0]
N -- [0, 0]
O -- [0, 0]
T -- [0, 0]
T -- [9, 6]
T -- [15, 7]
