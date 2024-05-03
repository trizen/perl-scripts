#!/usr/bin/perl

# Author: Trizen
# Date: 03 May 2024
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

        if ($n > $min_len) {

            push @lengths,   $n - 1;
            push @distances, $la - $p;
            push @literals,  undef;

            $la += $n - 1;
            $prefix .= substr($token, 0, -1);
        }
        else {
            my @bytes = split(//, substr($prefix, $p, $n - 1) . $chars[$la + $n - 1]);

            push @lengths,   (0) x scalar(@bytes);
            push @distances, (0) x scalar(@bytes);
            push @literals, @bytes;

            $la += $n;
            $prefix .= $token;
        }
    }

    return (\@literals, \@distances, \@lengths);
}

sub lzss_decode ($literals, $distances, $lengths) {

    my $chunk  = '';
    my $offset = 0;

    foreach my $i (0 .. $#$literals) {
        if ($lengths->[$i] != 0) {
            $chunk .= substr($chunk, $offset - $distances->[$i], $lengths->[$i]);
            $offset += $lengths->[$i];
        }
        else {
            $chunk .= $literals->[$i];
            $offset += 1;
        }
    }

    return $chunk;
}

my $string = "TOBEORNOTTOBEORTOBEORNOT";

my ($literals, $distances, $lengths) = lzss_encode($string);
my $decoded = lzss_decode($literals, $distances, $lengths);

$string eq $decoded or die "error: <<$string>> != <<$decoded>>";

foreach my $i (0 .. $#$literals) {
    if ($lengths->[$i] == 0) {
        say $literals->[$i];
    }
    else {
        say "[$distances->[$i], $lengths->[$i]]";
    }
}

foreach my $file (__FILE__, $^X) {    # several tests

    my $string = do {
        open my $fh, '<:raw', $file or die "error for <<$file>>: $!";
        local $/;
        <$fh>;
    };

    my ($literals, $distances, $lengths) = lzss_encode($string);
    my $decoded = lzss_decode($literals, $distances, $lengths);

    say "Ratio: ", scalar(@$literals) / scalar(grep { defined($_) } @$literals);

    $string eq $decoded or die "error: <<$string>> != <<$decoded>>";
}

__END__
T
O
B
E
O
R
N
O
T
[9, 6]
[15, 8]
T
Ratio: 1.44887348353553
Ratio: 1.50565184626978
