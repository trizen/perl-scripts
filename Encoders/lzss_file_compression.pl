#!/usr/bin/perl

# Author: Trizen
# Date: 17 June 2023
# https://github.com/trizen

# Compress/decompress files using LZ77 compression (LZSS variant) + Huffman coding.

# Encoding the literals and the pointers using a DEFLATE-like approach.

# Reference:
#   Data Compression (Summer 2023) - Lecture 11 - DEFLATE (gzip)
#   https://youtube.com/watch?v=SJPvNi4HrWQ

use 5.036;

use Getopt::Std    qw(getopts);
use File::Basename qw(basename);
use List::Util     qw(max);
use POSIX          qw(ceil log2);

use constant {
    PKGNAME => 'LZSS',
    VERSION => '0.01',
    FORMAT  => 'lzss',

    CHUNK_SIZE => 1 << 16,    # higher value = better compression
};

use constant {SIGNATURE => uc(FORMAT) . chr(1)};

# [distance value, offset bits]
my @DISTANCE_SYMBOLS = map { [$_, 0] } (0 .. 4);

until ($DISTANCE_SYMBOLS[-1][0] > CHUNK_SIZE) {
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

my @DISTANCE_INDICES;

foreach my $i (0 .. $#DISTANCE_SYMBOLS) {
    my ($min, $bits) = @{$DISTANCE_SYMBOLS[$i]};
    foreach my $k ($min .. $min + (1 << $bits) - 1) {
        $DISTANCE_INDICES[$k] = $i;
        last if ($k >= CHUNK_SIZE);
    }
}

my @LENGTH_INDICES;

foreach my $i (0 .. $#LENGTH_SYMBOLS) {
    my ($min, $bits) = @{$LENGTH_SYMBOLS[$i]};
    foreach my $k ($min .. $min + (1 << $bits) - 1) {
        $LENGTH_INDICES[$k] = $i;
    }
}

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

sub lz77_compression ($str, $uncompressed, $indices, $lengths, $has_backreference) {

    my $la = 0;

    my $prefix = '';
    my @chars  = split(//, $str);
    my $end    = $#chars;

    my $min_len = $LENGTH_SYMBOLS[0][0];
    my $max_len = $LENGTH_SYMBOLS[-1][0];

    my %literal_freq;
    my %distance_freq;

    my $literal_count  = 0;
    my $distance_count = 0;

    while ($la <= $end) {

        my $n = 1;
        my $p = 0;
        my $tmp;

        my $token = $chars[$la];

        while (    $n <= $max_len
               and $la + $n <= $end
               and ($tmp = index($prefix, $token, $p)) >= 0) {
            $p = $tmp;
            $token .= $chars[$la + $n];
            ++$n;
        }

        --$n;

        my $enc_bits_len     = 0;
        my $literal_bits_len = 0;

        if ($n >= $min_len) {

            my $dist = $DISTANCE_SYMBOLS[$DISTANCE_INDICES[$la - $p]];
            $enc_bits_len += $dist->[1] + ceil(log2((1 + $distance_count) / (1 + ($distance_freq{$dist->[0]} // 0))));

            my $len_idx = $LENGTH_INDICES[$n];
            my $len     = $LENGTH_SYMBOLS[$len_idx];

            $enc_bits_len += $len->[1] + ceil(log2((1 + $literal_count) / (1 + ($literal_freq{$len_idx + 256} // 0))));

            my %freq;
            foreach my $c (unpack('C*', substr($prefix, $p, $n))) {
                ++$freq{$c};
                $literal_bits_len += ceil(log2(($n + $literal_count) / ($freq{$c} + ($literal_freq{$c} // 0))));
            }
        }

        if ($n >= $min_len and $enc_bits_len < $literal_bits_len) {

            push @$lengths,           $n;
            push @$indices,           $la - $p;
            push @$has_backreference, 1;
            push @$uncompressed,      ord($chars[$la + $n]);

            my $dist_idx = $DISTANCE_INDICES[$la - $p];
            my $dist     = $DISTANCE_SYMBOLS[$dist_idx];

            ++$distance_count;
            ++$distance_freq{$dist->[0]};

            ++$literal_freq{$LENGTH_INDICES[$n] + 256};
            ++$literal_freq{ord $chars[$la + $n]};

            $literal_count += 2;
            $la            += $n + 1;
            $prefix .= $token;
        }
        else {
            my @bytes = unpack('C*', substr($prefix, $p, $n) . $chars[$la + $n]);

            push @$has_backreference, (0) x ($n + 1);
            push @$uncompressed, @bytes;
            ++$literal_freq{$_} for @bytes;

            $literal_count += $n + 1;
            $la            += $n + 1;
            $prefix .= $token;
        }
    }

    return;
}

sub lz77_decompression ($uncompressed, $indices, $lengths) {

    my $chunk  = '';
    my $offset = 0;

    foreach my $i (0 .. $#{$uncompressed}) {
        $chunk .= substr($chunk, $offset - $indices->[$i], $lengths->[$i]) . chr($uncompressed->[$i]);
        $offset += $lengths->[$i] + 1;
    }

    return $chunk;
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
    my $enc = '';
    for (@$bytes) {
        $enc .= $dict->{$_} // die "bad char: $_";
    }
    return $enc;
}

sub huffman_decode ($bits, $hash) {
    local $" = '|';
    $bits =~ s/(@{[sort { length($a) <=> length($b) } keys %{$hash}]})/$hash->{$1} /gr;    # very fast
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

    my $enc_len = unpack('N', join('', map { getc($fh) } 1 .. 4));

    if ($enc_len > 0) {
        return [split(' ', huffman_decode(read_bits($fh, $enc_len), $rev_dict))];
    }

    return [];
}

sub deflate_encode ($literals, $distances, $lengths, $has_backreference, $out_fh) {

    my @len_symbols;
    my @dist_symbols;
    my $offset_bits = '';

    my $j = 0;
    foreach my $k (0 .. $#{$literals}) {

        my $lit = $literals->[$k];
        push @len_symbols, $lit;

        $has_backreference->[$k] || next;

        my $len  = $lengths->[$j];
        my $dist = $distances->[$j];

        $j += 1;

        {
            my $len_idx = $LENGTH_INDICES[$len];
            my ($min, $bits) = @{$LENGTH_SYMBOLS[$len_idx]};

            push @len_symbols, $len_idx + 256;

            if ($bits > 0) {
                $offset_bits .= sprintf('%0*b', $bits, $len - $min);
            }
        }

        {
            my $dist_idx = $DISTANCE_INDICES[$dist];
            my ($min, $bits) = @{$DISTANCE_SYMBOLS[$dist_idx]};

            push @dist_symbols, $dist_idx;

            if ($bits > 0) {
                $offset_bits .= sprintf('%0*b', $bits, $dist - $min);
            }
        }
    }

    create_huffman_entry(\@len_symbols,  $out_fh);
    create_huffman_entry(\@dist_symbols, $out_fh);
    print $out_fh pack('B*', $offset_bits);
}

sub deflate_decode ($fh) {

    my @len_symbols  = @{decode_huffman_entry($fh)};
    my @dist_symbols = @{decode_huffman_entry($fh)};

    my $bits_len = 0;

    foreach my $i (@dist_symbols) {
        $bits_len += $DISTANCE_SYMBOLS[$i][1];
    }

    foreach my $i (@len_symbols) {
        if ($i >= 256) {
            $bits_len += $LENGTH_SYMBOLS[$i - 256][1];
        }
    }

    my $bits = read_bits($fh, $bits_len);

    my @literals;
    my @lengths;
    my @distances;

    my $j = 0;

    foreach my $i (@len_symbols) {
        if ($i >= 256) {
            my $dist = $dist_symbols[$j++];
            $lengths[-1]   = $LENGTH_SYMBOLS[$i - 256][0] + oct('0b' . substr($bits, 0, $LENGTH_SYMBOLS[$i - 256][1], ''));
            $distances[-1] = $DISTANCE_SYMBOLS[$dist][0] + oct('0b' . substr($bits, 0, $DISTANCE_SYMBOLS[$dist][1], ''));
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

        my (@uncompressed, @indices, @lengths, @has_backreference);
        lz77_compression($chunk, \@uncompressed, \@indices, \@lengths, \@has_backreference);

        my $est_ratio = length($chunk) / (scalar(@uncompressed) + scalar(@lengths) + 2 * scalar(@indices));
        say scalar(@uncompressed), ' -> ', $est_ratio;

        deflate_encode(\@uncompressed, \@indices, \@lengths, \@has_backreference, $out_fh);
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
        my ($uncompressed, $indices, $lengths) = deflate_decode($fh);
        print $out_fh lz77_decompression($uncompressed, $indices, $lengths);
    }

    # Close the file
    close $fh;
    close $out_fh;
}

main();
exit(0);
