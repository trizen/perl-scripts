#!/usr/bin/perl

# Author: Trizen
# Date: 10 June 2023
# https://github.com/trizen

# Encode and decode a random list of integers into a binary string, using a DEFLATE-like approach + Huffman coding.

use 5.036;
use List::Util qw(max shuffle);

use constant {MAX_INT => 0b11111111111111111111111111111111};

# [distance value, offset bits]
my @DISTANCE_SYMBOLS = ([0, 0], [1, 0], [2, 0], [3, 0], [4, 0]);

until ($DISTANCE_SYMBOLS[-1][0] > MAX_INT) {
    push @DISTANCE_SYMBOLS, [int($DISTANCE_SYMBOLS[-1][0] * (4 / 3)), $DISTANCE_SYMBOLS[-1][1] + 1];
    push @DISTANCE_SYMBOLS, [int($DISTANCE_SYMBOLS[-1][0] * (3 / 2)), $DISTANCE_SYMBOLS[-1][1]];
}

sub read_bit ($fh, $bitstring) {

    if (($$bitstring // '') eq '') {
        $$bitstring = unpack('b*', getc($fh) // return undef);
    }

    chop($$bitstring);
}

sub read_bits ($fh, $bits_len) {

    my $data = '';
    read($fh, $data, $bits_len >> 3);
    $data = unpack('B*', $data);

    while (length($data) < $bits_len) {
        $data .= unpack('B*', getc($fh) // return undef);
    }

    if (length($data) > $bits_len) {
        $data = substr($data, 0, $bits_len);
    }

    return $data;
}

sub elias_encoding ($integers) {    # all ints >= 1

    my $bitstring = '';
    foreach my $k (scalar(@$integers), @$integers) {
        if ($k == 1) {
            $bitstring .= '0';
        }
        else {
            my $t = sprintf('%b', $k - 1);
            $bitstring .= ('1' x length($t)) . '0' . substr($t, 1);
        }
    }

    pack('B*', $bitstring);
}

sub elias_decoding ($fh) {

    my @ints;
    my $len = 0;
    my $buffer;

    for (my $k = 0 ; $k <= $len ; ++$k) {

        my $bit_len = 0;
        while (read_bit($fh, \$buffer) eq '1') {
            ++$bit_len;
        }

        if ($bit_len > 0) {
            push @ints, 1 + oct('0b' . '1' . join('', map { read_bit($fh, \$buffer) } 1 .. ($bit_len - 1)));
        }
        else {
            push @ints, 1;
        }

        if ($k == 0) {
            $len = pop(@ints);
        }
    }

    return \@ints;
}

sub encode_integers ($integers) {

    my @counts;
    my $count           = 0;
    my $bits_width      = 1;
    my $bits_max_symbol = 1 << $bits_width;
    my $processed_len   = 0;

    foreach my $k (@$integers) {
        while ($k >= $bits_max_symbol) {

            if ($count > 0) {
                push @counts, [$bits_width, $count];
                $processed_len += $count;
            }

            $count = 0;
            $bits_max_symbol *= 2;
            $bits_width      += 1;
        }
        ++$count;
    }

    push @counts, grep { $_->[1] > 0 } [$bits_width, scalar(@$integers) - $processed_len];

    my $compressed = elias_encoding([map { @$_ } @counts]);

    my $bits = '';
    foreach my $pair (@counts) {
        my ($blen, $len) = @$pair;
        foreach my $symbol (splice(@$integers, 0, $len)) {
            $bits .= sprintf("%0*b", $blen, $symbol);
        }
    }

    $compressed .= pack('B*', $bits);
    return $compressed;
}

sub decode_integers ($fh) {

    my $ints = elias_decoding($fh);

    my @counts;
    my $bits_len = 0;

    while (@$ints) {
        my ($blen, $len) = splice(@$ints, 0, 2);
        push @counts, [$blen, $len];
        $bits_len += $blen * $len;
    }

    my $bits = read_bits($fh, $bits_len);

    my @chunks;
    foreach my $pair (@counts) {
        my ($blen, $len) = @$pair;
        foreach my $chunk (unpack(sprintf('(a%d)*', $blen), substr($bits, 0, $blen * $len, ''))) {
            push @chunks, oct('0b' . $chunk);
        }
    }

    return \@chunks;
}

# produce encode and decode dictionary from a tree
sub walk ($node, $code, $h, $rev_h) {

    my $c = $node->[0] // return ($h, $rev_h);
    if (ref $c) { walk($c->[$_], $code . $_, $h, $rev_h) for ('0', '1') }
    else        { $h->{$c} = $code; $rev_h->{$code} = $c }

    return ($h, $rev_h);
}

# make a tree, and return resulting dictionaries
sub mktree ($bytes) {
    my (%freq, @nodes);

    ++$freq{$_} for @$bytes;
    @nodes = map { [$_, $freq{$_}] } sort { $a <=> $b } keys %freq;

    do {    # poor man's priority queue
        @nodes = sort { $a->[1] <=> $b->[1] } @nodes;
        my ($x, $y) = splice(@nodes, 0, 2);
        if (defined($x)) {
            if (defined($y)) {
                push @nodes, [[$x, $y], $x->[1] + $y->[1]];
            }
            else {
                push @nodes, [[$x], $x->[1]];
            }
        }
    } while (@nodes > 1);

    walk($nodes[0], '', {}, {});
}

sub huffman_encode ($bytes, $dict) {
    my $enc = '';
    for (@$bytes) {
        $enc .= $dict->{$_} // die "bad char: $_";
    }
    return $enc;
}

sub huffman_decode ($bits, $hash) {
    local $" = '|';
    $bits =~ s/(@{[sort { length($a) <=> length($b) } keys %{$hash}]})/$hash->{$1}/gr;    # very fast
}

sub create_huffman_entry ($bytes, $out_fh) {

    my ($h, $rev_h) = mktree($bytes);
    my $enc = huffman_encode($bytes, $h);

    my $max_symbol = max(@$bytes);

    my @lengths;
    my $codes = '';

    foreach my $i (0 .. $max_symbol) {
        my $c = $h->{$i} // '';
        $codes .= $c;
        push @lengths, length($c);
    }

    print $out_fh encode_integers(\@lengths);
    print $out_fh pack("B*", $codes);
    print $out_fh pack("N",  length($enc));
    print $out_fh pack("B*", $enc);
}

sub decode_huffman_entry ($fh) {

    my @codes;
    my $codes_len = 0;

    my @lengths = @{decode_integers($fh)};

    foreach my $i (0 .. $#lengths) {
        my $l = $lengths[$i];
        if ($l > 0) {
            $codes_len += $l;
            push @codes, [$i, $l];
        }
    }

    my $codes_bin = read_bits($fh, $codes_len);

    my %rev_dict;
    foreach my $pair (@codes) {
        my $code = substr($codes_bin, 0, $pair->[1], '');
        $rev_dict{$code} = chr($pair->[0]);
    }

    my $enc_len = unpack('N', join('', map { getc($fh) } 1 .. 4));

    if ($enc_len > 0) {
        return huffman_decode(read_bits($fh, $enc_len), \%rev_dict);
    }

    return '';
}

sub encode_integers_deflate_like ($integers) {

    my @symbols;
    my $offset_bits = '';

    foreach my $dist (@$integers) {
        foreach my $i (0 .. $#DISTANCE_SYMBOLS) {
            if ($DISTANCE_SYMBOLS[$i][0] > $dist) {
                push @symbols, $i - 1;

                if ($DISTANCE_SYMBOLS[$i - 1][1] > 0) {
                    $offset_bits .= sprintf('%0*b', $DISTANCE_SYMBOLS[$i - 1][1], $dist - $DISTANCE_SYMBOLS[$i - 1][0]);
                }
                last;
            }
        }
    }

    my $str = '';
    open(my $out_fh, '>:raw', \$str);
    create_huffman_entry(\@symbols, $out_fh);
    print $out_fh pack('B*', $offset_bits);
    return $str;
}

sub decode_integers_deflate_like ($str) {

    open(my $fh, '<:raw', \$str);

    my @symbols  = unpack('C*', decode_huffman_entry($fh));
    my $bits_len = 0;

    foreach my $i (@symbols) {
        $bits_len += $DISTANCE_SYMBOLS[$i][1];
    }

    my $bits = read_bits($fh, $bits_len);

    my @distances;
    foreach my $i (@symbols) {
        push @distances, $DISTANCE_SYMBOLS[$i][0] + oct('0b' . substr($bits, 0, $DISTANCE_SYMBOLS[$i][1], ''));
    }

    return \@distances;
}

my @integers = shuffle(map { int(rand($_)) } 1 .. 1000);
my $str      = encode_integers_deflate_like([@integers]);

say "Encoded length: ", length($str);
say "Rawdata length: ", length(join(' ', @integers));

my $decoded = decode_integers_deflate_like($str);

join(' ', @integers) eq join(' ', @$decoded) or die "Decoding error";

__END__
Encoded length: 1209
Rawdata length: 3624
