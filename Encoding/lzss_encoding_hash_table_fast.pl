#!/usr/bin/perl

# Author: Trizen
# Date: 02 May 2024
# https://github.com/trizen

# Implementation of LZSS encoding, using an hash table.

# A non-optimal, but very fast approach.

use 5.036;

sub lzss_encode($str) {

    my $la = 0;

    my @symbols = unpack('C*', $str);
    my $end     = $#symbols;

    my $min_len = 4;      # minimum match length
    my $max_len = 258;    # maximum match length

    my (@literals, @distances, @lengths, %table);

    while ($la <= $end) {

        my $best_n = 1;
        my $best_p = $la;

        my $lookahead = substr($str, $la, $min_len);

        if (exists($table{$lookahead})) {

            my $p = $table{$lookahead};
            my $n = $min_len;

            while ($n <= $max_len and $la + $n <= $end and $symbols[$la + $n - 1] == $symbols[$p + $n - 1]) {
                ++$n;
            }

            $best_p = $p;
            $best_n = $n;

            $table{$lookahead} = $la;
        }
        else {
            $table{$lookahead} = $la;
        }

        if ($best_n > $min_len) {

            push @lengths,   $best_n - 1;
            push @distances, $la - $best_p;
            push @literals,  undef;

            $la += $best_n - 1;
        }
        else {

            push @lengths,   (0) x $best_n;
            push @distances, (0) x $best_n;
            push @literals, @symbols[$best_p .. $best_p + $best_n - 1];

            $la += $best_n;
        }
    }

    return (\@literals, \@distances, \@lengths);
}

sub lzss_decode ($literals, $distances, $lengths) {

    my @data;
    my $data_len = 0;

    foreach my $i (0 .. $#$lengths) {

        if ($lengths->[$i] == 0) {
            push @data, $literals->[$i];
            $data_len += 1;
            next;
        }

        my $length = $lengths->[$i];
        my $dist   = $distances->[$i];

        foreach my $j (1 .. $length) {
            push @data, $data[$data_len + $j - $dist - 1];
        }

        $data_len += $length;
    }

    pack('C*', @data);
}

my $string = "abbaabbaabaabaaaa";

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
97
98
98
97
[4, 6]
97
97
98
97
97
97
97
Ratio: 1.36301369863014
Ratio: 1.46043165467626
