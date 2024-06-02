#!/usr/bin/perl

# Author: Trizen
# Date: 11 May 2024
# Edit: 02 June 2024
# https://github.com/trizen

# Compress/decompress files using LZ77 compression (LZSS variant with hash tables), inspired by LZ4, combined with Huffman coding.

# References:
#   https://github.com/lz4/lz4/blob/dev/doc/lz4_Frame_format.md
#   https://github.com/lz4/lz4/blob/dev/doc/lz4_Block_format.md

use 5.036;
use Getopt::Std    qw(getopts);
use File::Basename qw(basename);
use List::Util     qw(max);

use constant {
    PKGNAME => 'LZBH',
    VERSION => '0.01',
    FORMAT  => 'lzbh',

    MIN_MATCH_LEN  => 4,                # minimum match length
    MAX_MATCH_LEN  => ~0,               # maximum match length
    MAX_MATCH_DIST => (1 << 17) - 1,    # maximum match distance
    MAX_CHAIN_LEN  => 48,               # higher value = better compression

    CHUNK_SIZE => 1 << 18,
};

# Container signature
use constant SIGNATURE => uc(FORMAT) . chr(1);

# [distance value, offset bits]
my @DISTANCE_SYMBOLS = map { [$_, 0] } (0 .. 4);

until ($DISTANCE_SYMBOLS[-1][0] > MAX_MATCH_DIST) {
    push @DISTANCE_SYMBOLS, [int($DISTANCE_SYMBOLS[-1][0] * (4 / 3)), $DISTANCE_SYMBOLS[-1][1] + 1];
    push @DISTANCE_SYMBOLS, [int($DISTANCE_SYMBOLS[-1][0] * (3 / 2)), $DISTANCE_SYMBOLS[-1][1]];
}

my @DISTANCE_INDICES;

foreach my $i (0 .. $#DISTANCE_SYMBOLS) {
    my ($min, $bits) = @{$DISTANCE_SYMBOLS[$i]};
    foreach my $k ($min .. $min + (1 << $bits) - 1) {
        last if ($k > MAX_MATCH_DIST);
        $DISTANCE_INDICES[$k] = $i;
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

sub encode_distances ($distances, $out_fh) {

    my @symbols;
    my $offset_bits = '';

    foreach my $dist (@$distances) {

        my $i = $DISTANCE_INDICES[$dist];
        my ($min, $bits) = @{$DISTANCE_SYMBOLS[$i]};

        push @symbols, $i;

        if ($bits > 0) {
            $offset_bits .= sprintf('%0*b', $bits, $dist - $min);
        }
    }

    create_huffman_entry(\@symbols, $out_fh);
    print $out_fh pack('B*', $offset_bits);
}

sub decode_distances ($fh) {

    my $symbols  = decode_huffman_entry($fh);
    my $bits_len = 0;

    foreach my $i (@$symbols) {
        $bits_len += $DISTANCE_SYMBOLS[$i][1];
    }

    my $bits = read_bits($fh, $bits_len);

    my @distances;
    foreach my $i (@$symbols) {
        push @distances, $DISTANCE_SYMBOLS[$i][0] + oct('0b' . substr($bits, 0, $DISTANCE_SYMBOLS[$i][1], ''));
    }

    return \@distances;
}

sub lzss_encode($str) {

    my $la = 0;

    my @symbols = unpack('C*', $str);
    my $end     = $#symbols;

    my $min_len       = MIN_MATCH_LEN;     # minimum match length
    my $max_len       = MAX_MATCH_LEN;     # maximum match length
    my $max_dist      = MAX_MATCH_DIST;    # maximum match distance
    my $max_chain_len = MAX_CHAIN_LEN;     # how many recent positions to keep track of

    my (@literals, @distances, @lengths, %table);

    while ($la <= $end) {

        my $best_n = 1;
        my $best_p = $la;

        my $lookahead = substr($str, $la, $min_len);

        if (exists($table{$lookahead})) {

            foreach my $p (@{$table{$lookahead}}) {

                if ($la - $p > $max_dist) {
                    last;
                }

                my $n = $min_len;

                while ($n <= $max_len and $la + $n <= $end and $symbols[$la + $n - 1] == $symbols[$p + $n - 1]) {
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

sub lzbh_encode($chunk) {

    my ($literals, $distances, $lengths) = lzss_encode($chunk);

    my $literals_end = $#{$literals};
    my (@symbols, @len_symbols, @match_symbols, @dist_symbols);

    for (my $i = 0 ; $i <= $literals_end ; ++$i) {

        my $j = $i;
        while ($i <= $literals_end and defined($literals->[$i])) {
            ++$i;
        }

        my $literals_length = $i - $j;
        my $match_len       = $lengths->[$i] // 0;

        push @match_symbols, (($literals_length >= 7 ? 7 : $literals_length) << 5) | ($match_len >= 31 ? 31 : $match_len);

        $literals_length -= 7;
        $match_len       -= 31;

        while ($literals_length >= 0) {
            push @len_symbols, ($literals_length >= 255 ? 255 : $literals_length);
            $literals_length -= 255;
        }

        push @symbols, @{$literals}[$j .. $i - 1];

        while ($match_len >= 0) {
            push @match_symbols, ($match_len >= 255 ? 255 : $match_len);
            $match_len -= 255;
        }

        push @dist_symbols, $distances->[$i] // 0;
    }

    return (\@symbols, \@len_symbols, \@match_symbols, \@dist_symbols);
}

sub lzbh_decode($symbols, $len_symbols, $match_symbols, $dist_symbols) {

    my $data     = '';
    my $data_len = 0;

    my @symbols       = @$symbols;
    my @len_symbols   = @$len_symbols;
    my @match_symbols = @$match_symbols;
    my @dist_symbols  = @$dist_symbols;

    while (@symbols) {

        my $len_byte = shift(@match_symbols);

        my $literals_length = $len_byte >> 5;
        my $match_len       = $len_byte & 0b11111;

        if ($literals_length == 7) {
            while (1) {
                my $byte_len = shift(@len_symbols);
                $literals_length += $byte_len;
                last if $byte_len != 255;
            }
        }

        if ($literals_length > 0) {
            $data .= pack("C*", splice(@symbols, 0, $literals_length));
            $data_len += $literals_length;
        }

        if ($match_len == 31) {
            while (1) {
                my $byte_len = shift(@match_symbols);
                $match_len += $byte_len;
                last if $byte_len != 255;
            }
        }

        my $dist = shift(@dist_symbols);

        if ($dist == 1) {
            $data .= substr($data, -1) x $match_len;
        }
        elsif ($dist >= $match_len) {
            $data .= substr($data, $data_len - $dist, $match_len);
        }
        else {
            foreach my $i (1 .. $match_len) {
                $data .= substr($data, $data_len + $i - $dist - 1, 1);
            }
        }

        $data_len += $match_len;
    }

    return $data;
}

sub compression($chunk, $out_fh) {
    my ($symbols, $len_symbols, $match_symbols, $dist_symbols) = lzbh_encode($chunk);
    create_huffman_entry($symbols,       $out_fh);
    create_huffman_entry($len_symbols,   $out_fh);
    create_huffman_entry($match_symbols, $out_fh);
    encode_distances($dist_symbols, $out_fh);
}

sub decompression($fh, $out_fh) {

    while (!eof($fh)) {

        my $symbols       = decode_huffman_entry($fh);
        my $len_symbols   = decode_huffman_entry($fh);
        my $match_symbols = decode_huffman_entry($fh);
        my $dist_symbols  = decode_distances($fh);

        print $out_fh lzbh_decode($symbols, $len_symbols, $match_symbols, $dist_symbols);
    }
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
        compression($chunk, $out_fh);
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
        decompression($fh, $out_fh);
    }

    # Close the file
    close $fh;
    close $out_fh;
}

main();
exit(0);
