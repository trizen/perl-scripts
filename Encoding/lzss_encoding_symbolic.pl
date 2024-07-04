#!/usr/bin/perl

# Author: Trizen
# Date: 02 May 2024
# https://github.com/trizen

# Symbolic implementation of LZSS encoding, using an hash table.

use 5.036;

sub lzss_encode_symbolic ($symbols) {

    my $la  = 0;
    my $end = $#$symbols;

    my $min_len       = 4;                # minimum match length
    my $max_len       = 255;              # maximum match length
    my $max_dist      = (1 << 16) - 1;    # maximum match distance
    my $max_chain_len = 16;               # how many recent positions to keep track of

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

                if ($la - $p > $max_dist) {
                    last;
                }

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

        if ($best_n == 1) {
            $table{$lookahead} = [$la];
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
            push @literals, @$symbols[$best_p .. $best_p + $best_n - 1];

            $la += $best_n;
        }
    }

    return (\@literals, \@distances, \@lengths);
}

sub lzss_decode_symbolic ($literals, $distances, $lengths) {

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

    return \@data;
}

my $string = "abbaabbaabaabaaaa";

my ($literals, $distances, $lengths) = lzss_encode_symbolic([unpack('C*', $string)]);
my $decoded = lzss_decode_symbolic($literals, $distances, $lengths);

$string eq pack('C*', @$decoded) or die "error: <<$string>> != <<@$decoded>>";

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

    my ($literals, $distances, $lengths) = lzss_encode_symbolic([unpack('C*', $string)]);
    my $decoded = lzss_decode_symbolic($literals, $distances, $lengths);

    say "Ratio: ", scalar(@$literals) / scalar(grep { defined($_) } @$literals);

    $string eq pack('C*', @$decoded) or die "error: <<$string>> != <<@$decoded>>";
}

__END__
97
98
98
97
[4, 6]
[3, 5]
97
97
Ratio: 1.38851802403204
Ratio: 1.44651830581479
