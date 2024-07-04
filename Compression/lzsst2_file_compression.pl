#!/usr/bin/perl

# Author: Trizen
# Date: 17 June 2023
# Edit: 04 July 2024
# https://github.com/trizen

# Compress/decompress files using LZ77 compression (LZSS variant with hash tables with lazy matching) + Huffman coding.

# Encoding the literals and the pointers using a DEFLATE-like approach.
# This version is memory-friendly, supporting arbitrary large chunk sizes.

# References:
#   Data Compression (Summer 2023) - Lecture 11 - DEFLATE (gzip)
#   https://youtube.com/watch?v=SJPvNi4HrWQ
#
#   DEFLATE Compressed Data Format Specification version 1.3
#   https://datatracker.ietf.org/doc/html/rfc1951

use 5.036;

use Getopt::Std    qw(getopts);
use File::Basename qw(basename);
use List::Util     qw(max);

use constant {
    PKGNAME => 'LZSST2',
    VERSION => '0.01',
    FORMAT  => 'lzsst2',

    CHUNK_SIZE => 1 << 19,    # higher value = better compression
};

# Container signature
use constant SIGNATURE => uc(FORMAT) . chr(1);

sub usage {
    my ($code) = @_;
    print <<"EOH";
usage: $0 [options] [input file] [output file]

options:
        -e            : extract
        -i <filename> : input filename
        -o <filename> : output filename
        -r            : rewrite output

        -v            : version number
        -h            : this message

examples:
         $0 document.txt
         $0 document.txt archive.${\FORMAT}
         $0 archive.${\FORMAT} document.txt
         $0 -e -i archive.${\FORMAT} -o document.txt

EOH

    exit($code // 0);
}

sub version {
    printf("%s %s\n", PKGNAME, VERSION);
    exit;
}

sub valid_archive {
    my ($fh) = @_;

    if (read($fh, (my $sig), length(SIGNATURE), 0) == length(SIGNATURE)) {
        $sig eq SIGNATURE || return;
    }

    return 1;
}

sub main {
    my %opt;
    getopts('ei:o:vhr', \%opt);

    $opt{h} && usage(0);
    $opt{v} && version();

    my ($input, $output) = @ARGV;
    $input  //= $opt{i} // usage(2);
    $output //= $opt{o};

    my $ext = qr{\.${\FORMAT}\z}io;
    if ($opt{e} || $input =~ $ext) {

        if (not defined $output) {
            ($output = basename($input)) =~ s{$ext}{}
              || die "$0: no output file specified!\n";
        }

        if (not $opt{r} and -e $output) {
            print "'$output' already exists! -- Replace? [y/N] ";
            <STDIN> =~ /^y/i || exit 17;
        }

        decompress_file($input, $output)
          || die "$0: error: decompression failed!\n";
    }
    elsif ($input !~ $ext || (defined($output) && $output =~ $ext)) {
        $output //= basename($input) . '.' . FORMAT;
        compress_file($input, $output)
          || die "$0: error: compression failed!\n";
    }
    else {
        warn "$0: don't know what to do...\n";
        usage(1);
    }
}

sub find_distance_index ($dist, $distance_symbols) {
    foreach my $i (0 .. $#{$distance_symbols}) {
        if ($distance_symbols->[$i][0] > $dist) {
            return $i - 1;
        }
    }
}

sub make_deflate_symbols ($size) {

    # [distance value, offset bits]
    my @DISTANCE_SYMBOLS = map { [$_, 0] } (0 .. 4);

    until ($DISTANCE_SYMBOLS[-1][0] > $size) {
        push @DISTANCE_SYMBOLS, [int($DISTANCE_SYMBOLS[-1][0] * (4 / 3)), $DISTANCE_SYMBOLS[-1][1] + 1];
        push @DISTANCE_SYMBOLS, [int($DISTANCE_SYMBOLS[-1][0] * (3 / 2)), $DISTANCE_SYMBOLS[-1][1]];
    }

    # [length, offset bits]
    my @LENGTH_SYMBOLS = ((map { [$_, 0] } (4 .. 10)));

    {
        my $delta = 1;
        until ($LENGTH_SYMBOLS[-1][0] > 163) {
            push @LENGTH_SYMBOLS, [$LENGTH_SYMBOLS[-1][0] + $delta, $LENGTH_SYMBOLS[-1][1] + 1];
            $delta *= 2;
            push @LENGTH_SYMBOLS, [$LENGTH_SYMBOLS[-1][0] + $delta, $LENGTH_SYMBOLS[-1][1]];
            push @LENGTH_SYMBOLS, [$LENGTH_SYMBOLS[-1][0] + $delta, $LENGTH_SYMBOLS[-1][1]];
            push @LENGTH_SYMBOLS, [$LENGTH_SYMBOLS[-1][0] + $delta, $LENGTH_SYMBOLS[-1][1]];
        }
        push @LENGTH_SYMBOLS, [258, 0];
    }

    my @LENGTH_INDICES;

    foreach my $i (0 .. $#LENGTH_SYMBOLS) {
        my ($min, $bits) = @{$LENGTH_SYMBOLS[$i]};
        foreach my $k ($min .. $min + (1 << $bits) - 1) {
            $LENGTH_INDICES[$k] = $i;
        }
    }

    return (\@DISTANCE_SYMBOLS, \@LENGTH_INDICES, \@LENGTH_SYMBOLS);
}

sub find_match ($str_ref, $la, $min_len, $max_len, $end, $table, $symbols) {

    my $best_n = 1;
    my $best_p = $la;

    my $lookahead = substr($$str_ref, $la, $min_len);

    if (exists($table->{$lookahead})) {

        foreach my $p (@{$table->{$lookahead}}) {

            my $n = $min_len;

            while ($n <= $max_len and $la + $n <= $end and $symbols->[$la + $n - 1] == $symbols->[$p + $n - 1]) {
                ++$n;
            }

            if ($n > $best_n) {
                $best_p = $p;
                $best_n = $n;
            }
        }
    }

    return ($best_n, $best_p);
}

sub lz77_compression($str) {

    my $la = 0;

    my @symbols = unpack('C*', $str);
    my $end     = $#symbols;

    my $min_len       = 4;      # minimum match length
    my $max_len       = 258;    # maximum match length
    my $max_chain_len = 48;     # how many recent positions to keep track of

    my (@literals, @distances, @lengths, %table);

    while ($la <= $end) {

        my $lookahead1 = substr($str, $la,     $min_len);
        my $lookahead2 = substr($str, $la + 1, $min_len);

        my ($n1, $p1) = (1, $la);
        my ($n2, $p2) = (1, $la + 1);

        if (exists($table{$lookahead1})) {
            ($n1, $p1) = find_match(\$str, $la, $min_len, $max_len, $end, \%table, \@symbols);
        }

        if (exists($table{$lookahead2})) {
            ($n2, $p2) = find_match(\$str, $la + 1, $min_len, $max_len, $end, \%table, \@symbols);
        }

        my $best_n    = $n1;
        my $best_p    = $p1;
        my $lookahead = $lookahead1;

        # When a longer match is found at position la+1,
        # emit a literal followed by the longer match.
        # https://datatracker.ietf.org/doc/html/rfc1951#section-4

        if ($n2 > $n1 and $p1 < $p2) {

            push @lengths,   (0);
            push @distances, (0);
            push @literals, @symbols[$la .. $la];

            $la += 1;

            $best_n    = $n2;
            $best_p    = $p2;
            $lookahead = $lookahead2;
        }

        my $matched = substr($str, $la, $best_n);

        foreach my $i (0 .. length($matched) - $min_len) {

            my $key = substr($matched, $i, $min_len);
            unshift @{$table{$key}}, $la + $i;

            if (scalar(@{$table{$key}}) > $max_chain_len) {
                pop @{$table{$key}};
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
            push @literals, @symbols[$best_p .. $best_p + $best_n - 1];

            $la += $best_n;
        }
    }

    return (\@literals, \@distances, \@lengths);
}

sub lz77_decompression ($literals, $distances, $lengths) {

    my $data     = '';
    my $data_len = 0;

    foreach my $i (0 .. $#$lengths) {

        if ($lengths->[$i] == 0) {
            $data .= chr($literals->[$i]);
            ++$data_len;
            next;
        }

        my $length = $lengths->[$i];
        my $dist   = $distances->[$i];

        if ($dist >= $length) {    # non-overlapping matches
            $data .= substr($data, $data_len - $dist, $length);
        }
        elsif ($dist == 1) {       # run-length of last character
            $data .= substr($data, -1) x $length;
        }
        else {                     # overlapping matches
            foreach my $i (1 .. $length) {
                $data .= substr($data, $data_len + $i - $dist - 1, 1);
            }
        }

        $data_len += $length;
    }

    return $data;
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
            $bitstring .= '1' . (($d < 0) ? '0' : '1') . ('1' x (length($t) - 1)) . '0' . substr($t, 1);
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

# make a tree, and return resulting dictionaries
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

sub huffman_encode ($bytes, $dict) {
    join('', @{$dict}{@$bytes});
}

sub huffman_decode ($bits, $hash) {
    local $" = '|';
    [split(' ', $bits =~ s/(@{[sort { length($a) <=> length($b) } keys %{$hash}]})/$hash->{$1} /gr)];    # very fast
}

sub create_huffman_entry ($bytes, $out_fh) {

    my %freq;
    ++$freq{$_} for @$bytes;

    my ($h, $rev_h) = mktree_from_freq(\%freq);
    my $enc = huffman_encode($bytes, $h);

    my $max_symbol = max(keys %freq) // 0;

    my @freqs;
    foreach my $i (0 .. $max_symbol) {
        push @freqs, $freq{$i} // 0;
    }

    print $out_fh delta_encode(\@freqs);
    print $out_fh pack("N",  length($enc));
    print $out_fh pack("B*", $enc);
}

sub decode_huffman_entry ($fh) {

    my @freqs = @{delta_decode($fh)};

    my %freq;
    foreach my $i (0 .. $#freqs) {
        if ($freqs[$i]) {
            $freq{$i} = $freqs[$i];
        }
    }

    my (undef, $rev_dict) = mktree_from_freq(\%freq);

    my $enc_len = unpack('N', join('', map { getc($fh) // die "error" } 1 .. 4));

    if ($enc_len > 0) {
        return huffman_decode(read_bits($fh, $enc_len), $rev_dict);
    }

    return [];
}

sub deflate_encode ($size, $literals, $distances, $lengths, $out_fh) {

    my ($DISTANCE_SYMBOLS, $LENGTH_INDICES, $LENGTH_SYMBOLS) = make_deflate_symbols($size);

    my @len_symbols;
    my @dist_symbols;
    my $offset_bits = '';

    foreach my $k (0 .. $#{$literals}) {

        if ($lengths->[$k] == 0) {
            push @len_symbols, $literals->[$k];
            next;
        }

        my $len  = $lengths->[$k];
        my $dist = $distances->[$k];

        {
            my $len_idx = $LENGTH_INDICES->[$len];
            my ($min, $bits) = @{$LENGTH_SYMBOLS->[$len_idx]};

            push @len_symbols, $len_idx + 256;

            if ($bits > 0) {
                $offset_bits .= sprintf('%0*b', $bits, $len - $min);
            }
        }

        {
            my $dist_idx = find_distance_index($dist, $DISTANCE_SYMBOLS);
            my ($min, $bits) = @{$DISTANCE_SYMBOLS->[$dist_idx]};

            push @dist_symbols, $dist_idx;

            if ($bits > 0) {
                $offset_bits .= sprintf('%0*b', $bits, $dist - $min);
            }
        }
    }

    print $out_fh pack('N', $size);
    create_huffman_entry(\@len_symbols,  $out_fh);
    create_huffman_entry(\@dist_symbols, $out_fh);
    print $out_fh pack('B*', $offset_bits);
}

sub deflate_decode ($fh) {

    my $size = unpack('N', join('', map { getc($fh) // return undef } 1 .. 4));
    my ($DISTANCE_SYMBOLS, $LENGTH_INDICES, $LENGTH_SYMBOLS) = make_deflate_symbols($size);

    my $len_symbols  = decode_huffman_entry($fh);
    my $dist_symbols = decode_huffman_entry($fh);

    my $bits_len = 0;

    foreach my $i (@$dist_symbols) {
        $bits_len += $DISTANCE_SYMBOLS->[$i][1];
    }

    foreach my $i (@$len_symbols) {
        if ($i >= 256) {
            $bits_len += $LENGTH_SYMBOLS->[$i - 256][1];
        }
    }

    my $bits = read_bits($fh, $bits_len);

    my @literals;
    my @lengths;
    my @distances;

    my $j = 0;

    foreach my $i (@$len_symbols) {
        if ($i >= 256) {
            my $dist = $dist_symbols->[$j++];
            push @literals,  undef;
            push @lengths,   $LENGTH_SYMBOLS->[$i - 256][0] + oct('0b' . substr($bits, 0, $LENGTH_SYMBOLS->[$i - 256][1], ''));
            push @distances, $DISTANCE_SYMBOLS->[$dist][0] + oct('0b' . substr($bits, 0, $DISTANCE_SYMBOLS->[$dist][1], ''));
        }
        else {
            push @literals,  $i;
            push @lengths,   0;
            push @distances, 0;
        }
    }

    return (\@literals, \@distances, \@lengths);
}

# Compress file
sub compress_file ($input, $output) {

    open my $fh, '<:raw', $input
      or die "Can't open file <<$input>> for reading: $!";

    my $header = SIGNATURE;

    # Open the output file for writing
    open my $out_fh, '>:raw', $output
      or die "Can't open file <<$output>> for write: $!";

    # Print the header
    print $out_fh $header;

    # Compress data
    while (read($fh, (my $chunk), CHUNK_SIZE)) {

        my ($literals, $distances, $lengths) = lz77_compression($chunk);
        my $est_ratio = length($chunk) / (scalar(@$literals) + scalar(@$lengths) + 2 * scalar(@$distances));
        say scalar(@$literals), ' -> ', $est_ratio;

        deflate_encode(length($chunk), $literals, $distances, $lengths, $out_fh);
    }

    # Close the file
    close $out_fh;
}

# Decompress file
sub decompress_file ($input, $output) {

    # Open and validate the input file
    open my $fh, '<:raw', $input
      or die "Can't open file <<$input>> for reading: $!";

    valid_archive($fh) || die "$0: file `$input' is not a \U${\FORMAT}\E v${\VERSION} archive!\n";

    # Open the output file
    open my $out_fh, '>:raw', $output
      or die "Can't open file <<$output>> for writing: $!";

    while (!eof($fh)) {
        my ($literals, $distances, $lengths) = deflate_decode($fh);
        print $out_fh lz77_decompression($literals, $distances, $lengths);
    }

    # Close the file
    close $fh;
    close $out_fh;
}

main();
exit(0);
