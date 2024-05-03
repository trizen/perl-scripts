#!/usr/bin/perl

# Author: Trizen
# Date: 03 May 2024
# https://github.com/trizen

# Symbolic implementation of LZ77 encoding, using an hash table.

use 5.036;

sub lz77_encode_symbolic ($symbols) {

    if (ref($symbols) eq '') {
        return __SUB__->(string2symbols($symbols));
    }

    my $la  = 0;
    my $end = $#$symbols;

    my $min_len       = 4;      # minimum match length
    my $max_len       = 255;    # maximum match length
    my $max_chain_len = 16;     # how many recent positions to keep track of

    my (@literals, @distances, @lengths, %table);

    while ($la <= $end) {

        my $best_n = 1;
        my $best_p = $la;

        my @lookahead_symbols;
        if ($la + $min_len - 1 <= $end) {
            push @lookahead_symbols, @{$symbols}[$la .. $la + $min_len - 1];
        }
        else {
            for (my $j = 0 ; ($j < $min_len and $la + $j <= $end) ; ++$j) {
                push @lookahead_symbols, $symbols->[$la + $j];
            }
        }

        my $lookahead = join(' ', @lookahead_symbols);

        if (exists($table{$lookahead})) {

            foreach my $p (@{$table{$lookahead}}) {

                my $n = $min_len;

                while ($n <= $max_len and $la + $n <= $end and $symbols->[$la + $n - 1] == $symbols->[$p + $n - 1]) {
                    ++$n;
                }

                if ($n > $best_n) {
                    $best_p = $p;
                    $best_n = $n;
                }
            }

            my @matched = @{$symbols}[$la .. $la + $best_n - 1];

            foreach my $i (0 .. scalar(@matched) - $min_len) {

                my $key = join(' ', @matched[$i .. $i + $min_len - 1]);
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
            push @literals,  $symbols->[$la + $best_n];

            $la += $best_n + 1;
        }
        else {
            my @bytes = @{$symbols}[$best_p .. $best_p + $best_n];

            push @lengths,   (0) x scalar(@bytes);
            push @distances, (0) x scalar(@bytes);
            push @literals, @bytes;

            $la += $best_n + 1;
        }
    }

    return (\@literals, \@distances, \@lengths);
}

sub lz77_decode_symbolic ($literals, $distances, $lengths) {

    my @data;
    my $data_len = 0;

    foreach my $i (0 .. $#$lengths) {

        if ($lengths->[$i] != 0) {
            my $length = $lengths->[$i];
            my $dist   = $distances->[$i];

            foreach my $j (1 .. $length) {
                push @data, $data[$data_len + $j - $dist - 1];
            }

            $data_len += $length;
        }

        push @data, $literals->[$i];
        $data_len += 1;
    }

    return \@data;
}

my $string = "abbaabbaabaabaaaa";

my ($literals, $distances, $lengths) = lz77_encode_symbolic([unpack('C*', $string)]);
my $decoded = lz77_decode_symbolic($literals, $distances, $lengths);

$string eq pack('C*', @$decoded) or die "error: <<$string>> != <<@$decoded>>";

foreach my $i (0 .. $#$literals) {
    say "$literals->[$i] -- [$distances->[$i], $lengths->[$i]]";
}

foreach my $file (__FILE__, $^X) {    # several tests

    my $string = do {
        open my $fh, '<:raw', $file or die "error for <<$file>>: $!";
        local $/;
        <$fh>;
    };

    my ($literals, $distances, $lengths) = lz77_encode_symbolic([unpack('C*', $string)]);
    my $decoded = lz77_decode_symbolic($literals, $distances, $lengths);

    $string eq pack('C*', @$decoded) or die "error: <<$string>> != <<@$decoded>>";
}
