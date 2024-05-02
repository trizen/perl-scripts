#!/usr/bin/perl

# Author: Trizen
# Date: 02 May 2024
# https://github.com/trizen

# Implementation of LZSS encoding, using an hash table.

use 5.036;

sub lzss_encode ($str) {

    my $la = 0;

    my @chars = split(//, $str);
    my $end   = $#chars;

    my $min_len       = 3;      # minimum match length
    my $max_len       = 255;    # maximum match length
    my $max_chain_len = 16;     # how many recent positions to keep track of

    my (@literals, @distances, @lengths, %table);

    while ($la <= $end) {

        my $best_n = 1;
        my $best_p = $la;

        my $lookahead = substr($str, $la, $min_len);

        if (exists($table{$lookahead}) and length($lookahead) == $min_len) {

            foreach my $p (@{$table{$lookahead}}) {

                my $n = $min_len;

                while ($n <= $max_len and $la + $n <= $end and $chars[$la + $n - 1] eq $chars[$p + $n - 1]) {
                    ++$n;
                }

                if ($n > $best_n) {
                    $best_p = $p;
                    $best_n = $n;
                }
            }

            my $matched = substr($str, $la, $best_n);

            foreach my $i (0 .. length($matched) - $min_len) {

                my $key = substr($matched, $i, $min_len);
                unshift @{$table{$key}}, $la + $i;

                if (scalar(@{$table{$key}}) > $max_chain_len) {
                    pop @{$table{$key}};
                }
            }
        }
        else {
            $table{$lookahead} = [$la];
        }

        --$best_n;

        if ($best_n >= $min_len) {

            push @lengths,   $best_n;
            push @distances, $la - $best_p;
            push @literals,  $chars[$la + $best_n];

            $la += $best_n + 1;
        }
        else {
            my @bytes = @chars[$best_p .. $best_p + $best_n];

            push @lengths,   (0) x scalar(@bytes);
            push @distances, (0) x scalar(@bytes);
            push @literals, @bytes;

            $la += $best_n + 1;
        }
    }

    return (\@literals, \@distances, \@lengths);
}

sub lzss_decode ($literals, $distances, $lengths) {

    my @data;
    my $data_len = 0;

    foreach my $i (0 .. $#$lengths) {

        my $length = $lengths->[$i];
        my $dist   = $distances->[$i];

        foreach my $j (1 .. $length) {
            push @data, $data[$data_len + $j - $dist - 1];
        }

        $data_len += $length + 1;
        push @data, $literals->[$i];
    }

    return join('', @data);
}

my $string = "abbaabbaabaabaaaa";

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
a -- [0, 0]
b -- [0, 0]
b -- [0, 0]
a -- [0, 0]
a -- [4, 6]
a -- [3, 4]
a -- [0, 0]
