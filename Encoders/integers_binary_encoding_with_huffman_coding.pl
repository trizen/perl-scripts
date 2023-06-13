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

sub delta_encode ($integers) {

    my @deltas;
    my $prev = 0;

    unshift(@$integers, scalar(@$integers));

    while (@$integers) {
        my $curr = shift(@$integers);
        push @deltas, $curr - $prev;
        $prev = $curr;
    }

    my $bitstring = '';

    foreach my $d (@deltas) {
        if ($d == 0) {
            $bitstring .= '0';
        }
        else {
            my $t = sprintf('%b', abs($d));
            $bitstring .= ('1' . (($d < 0) ? '0' : '1') . ('1' x (length($t) - 1)) . '0' . substr($t, 1));
        }
    }

    pack('B*', $bitstring);
}

sub delta_decode ($fh) {

    my @deltas;
    my $buffer = '';
    my $len    = 0;

    for (my $k = 0 ; $k <= $len ; ++$k) {
        my $bit = read_bit($fh, \$buffer);

        if ($bit eq '0') {
            push @deltas, 0;
        }
        else {
            my $bit = read_bit($fh, \$buffer);
            my $n   = 0;
            ++$n while (read_bit($fh, \$buffer) eq '1');
            my $d = oct('0b1' . join('', map { read_bit($fh, \$buffer) } 1 .. $n));
            push @deltas, ($bit eq '1' ? $d : -$d);
        }

        if ($k == 0) {
            $len = pop(@deltas);
        }
    }

    my @acc;
    my $prev = $len;

    foreach my $d (@deltas) {
        $prev += $d;
        push @acc, $prev;
    }

    return \@acc;
}

# produce encode and decode dictionary from a tree
sub walk ($node, $code, $h, $rev_h) {

    my $c = $node->[0] // return ($h, $rev_h);
    if (ref $c) { walk($c->[$_], $code . $_, $h, $rev_h) for ('0', '1') }
    else        { $h->{$c} = $code; $rev_h->{$code} = $c }

    return ($h, $rev_h);
}

sub mktree_from_freq ($freq) {

    my @nodes = map { [$_, $freq->{$_}] } sort { $a <=> $b } keys %$freq;

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

# make a tree, and return resulting dictionaries
sub mktree ($bytes) {
    my %freq;
    ++$freq{$_} for @$bytes;
    return mktree_from_freq(\%freq);
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

    my %freq;
    ++$freq{$_} for @$bytes;

    my ($h, $rev_h) = mktree($bytes);
    my $enc = huffman_encode($bytes, $h);

    my $max_symbol = max(@$bytes);

    my @freqs;
    my $codes = '';

    foreach my $i (0 .. $max_symbol) {
        push @freqs, $freq{$i} // 0;
    }

    print $out_fh delta_encode(\@freqs);
    print $out_fh pack("N",  length($enc));
    print $out_fh pack("B*", $enc);
}

sub decode_huffman_entry ($fh) {

    my @codes;
    my $codes_len = 0;

    my @freqs = @{delta_decode($fh)};

    my %freq;
    foreach my $i (0 .. $#freqs) {
        if ($freqs[$i]) {
            $freq{$i} = $freqs[$i];
        }
    }

    my (undef, $rev_dict) = mktree_from_freq(\%freq);

    foreach my $k (keys %$rev_dict) {
        $rev_dict->{$k} = chr($rev_dict->{$k});
    }

    my $enc_len = unpack('N', join('', map { getc($fh) } 1 .. 4));

    if ($enc_len > 0) {
        return huffman_decode(read_bits($fh, $enc_len), $rev_dict);
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
Encoded length: 1196
Rawdata length: 3590
