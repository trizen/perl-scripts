#!/usr/bin/perl

# Author: Trizen
# Date: 10 September 2023
# Edit: 29 February 2024
# https://github.com/trizen

# Compress/decompress files using Burrows-Wheeler Transform (BWT) + Variable Run-Length encoding + LZSS.

# Reference:
#   Data Compression (Summer 2023) - Lecture 13 - BZip2
#   https://youtube.com/watch?v=cvoZbBZ3M2A

use 5.036;
use Getopt::Std    qw(getopts);
use File::Basename qw(basename);
use List::Util     qw(max uniq);
use POSIX          qw(ceil log2);

use constant {
    PKGNAME => 'BWRLZ',
    VERSION => '0.01',
    FORMAT  => 'bwrlz',

    CHUNK_SIZE    => 1 << 17,    # higher value = better compression
    LOOKAHEAD_LEN => 128,
};

# Container signature
use constant SIGNATURE => uc(FORMAT) . chr(1);

# [distance value, offset bits]
my @DISTANCE_SYMBOLS = map { [$_, 0] } (0 .. 4);

until ($DISTANCE_SYMBOLS[-1][0] > CHUNK_SIZE) {
    push @DISTANCE_SYMBOLS, [int($DISTANCE_SYMBOLS[-1][0] * (4 / 3)), $DISTANCE_SYMBOLS[-1][1] + 1];
    push @DISTANCE_SYMBOLS, [int($DISTANCE_SYMBOLS[-1][0] * (3 / 2)), $DISTANCE_SYMBOLS[-1][1]];
}

# [length, offset bits]
my @LENGTH_SYMBOLS = ((map { [$_, 0] } (3 .. 10)));

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
        last if ($k > CHUNK_SIZE);
        $DISTANCE_INDICES[$k] = $i;
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

sub lz77_compression ($str, $uncompressed, $indices, $lengths) {

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

        my $enc_bits_len     = 0;
        my $literal_bits_len = 0;

        if ($n > $min_len) {

            my $dist = $DISTANCE_SYMBOLS[$DISTANCE_INDICES[$la - $p]];
            $enc_bits_len += $dist->[1] + ceil(log2((1 + $distance_count) / (1 + ($distance_freq{$dist->[0]} // 0))));

            my $len_idx = $LENGTH_INDICES[$n - 1];
            my $len     = $LENGTH_SYMBOLS[$len_idx];

            $enc_bits_len += $len->[1] + ceil(log2((1 + $literal_count) / (1 + ($literal_freq{$len_idx + 256} // 0))));

            my %freq;
            foreach my $c (unpack('C*', substr($prefix, $p, $n - 1) . $chars[$la + $n - 1])) {
                ++$freq{$c};
                $literal_bits_len += ceil(log2(($n + $literal_count) / ($freq{$c} + ($literal_freq{$c} // 0))));
            }
        }

        if ($n > $min_len and $enc_bits_len < $literal_bits_len) {

            push @$lengths,      $n - 1;
            push @$indices,      $la - $p;
            push @$uncompressed, undef;

            my $dist_idx = $DISTANCE_INDICES[$la - $p];
            my $dist     = $DISTANCE_SYMBOLS[$dist_idx];

            ++$distance_count;
            ++$distance_freq{$dist->[0]};

            ++$literal_count;
            ++$literal_freq{$LENGTH_INDICES[$n - 1] + 256};

            $la += $n - 1;
            $prefix .= substr($token, 0, -1);
        }
        else {
            my @bytes = unpack('C*', substr($prefix, $p, $n - 1) . $chars[$la + $n - 1]);

            push @$uncompressed, @bytes;
            push @$lengths, (0) x scalar(@bytes);
            push @$indices, (0) x scalar(@bytes);

            ++$literal_freq{$_} for @bytes;

            $literal_count += $n;
            $la            += $n;
            $prefix .= $token;
        }
    }

    return;
}

sub lz77_decompression ($literals, $distances, $lengths) {

    my $chunk  = '';
    my $offset = 0;

    foreach my $i (0 .. $#$literals) {
        if ($lengths->[$i] != 0) {
            $chunk .= substr($chunk, $offset - $distances->[$i], $lengths->[$i]);
            $offset += $lengths->[$i];
        }
        else {
            $chunk .= chr($literals->[$i]);
            $offset += 1;
        }
    }

    return $chunk;
}

sub deflate_encode ($literals, $distances, $lengths, $out_fh) {

    my @len_symbols;
    my @dist_symbols;
    my $offset_bits = '';

    foreach my $j (0 .. $#{$literals}) {

        if ($lengths->[$j] == 0) {
            push @len_symbols, $literals->[$j];
            next;
        }

        my $len  = $lengths->[$j];
        my $dist = $distances->[$j];

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

    my $len_symbols  = decode_huffman_entry($fh);
    my $dist_symbols = decode_huffman_entry($fh);

    my $bits_len = 0;

    foreach my $i (@$dist_symbols) {
        $bits_len += $DISTANCE_SYMBOLS[$i][1];
    }

    foreach my $i (@$len_symbols) {
        if ($i >= 256) {
            $bits_len += $LENGTH_SYMBOLS[$i - 256][1];
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
            push @lengths,   $LENGTH_SYMBOLS[$i - 256][0] + oct('0b' . substr($bits, 0, $LENGTH_SYMBOLS[$i - 256][1], ''));
            push @distances, $DISTANCE_SYMBOLS[$dist][0] + oct('0b' . substr($bits, 0, $DISTANCE_SYMBOLS[$dist][1], ''));
        }
        else {
            push @literals,  $i;
            push @lengths,   0;
            push @distances, 0;
        }
    }

    return (\@literals, \@distances, \@lengths);
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

sub delta_encode ($integers, $double = 0) {

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
        elsif ($double) {
            my $t = sprintf('%b', abs($d) + 1);
            my $l = sprintf('%b', length($t));
            $bitstring .= '1' . (($d < 0) ? '0' : '1') . ('1' x (length($l) - 1)) . '0' . substr($l, 1) . substr($t, 1);
        }
        else {
            my $t = sprintf('%b', abs($d));
            $bitstring .= '1' . (($d < 0) ? '0' : '1') . ('1' x (length($t) - 1)) . '0' . substr($t, 1);
        }
    }

    pack('B*', $bitstring);
}

sub delta_decode ($fh, $double = 0) {

    my @deltas;
    my $buffer = '';
    my $len    = 0;

    for (my $k = 0 ; $k <= $len ; ++$k) {
        my $bit = read_bit($fh, \$buffer);

        if ($bit eq '0') {
            push @deltas, 0;
        }
        elsif ($double) {
            my $bit = read_bit($fh, \$buffer);

            my $bl = 0;
            ++$bl while (read_bit($fh, \$buffer) eq '1');

            my $bl2 = oct('0b1' . join('', map { read_bit($fh, \$buffer) } 1 .. $bl));
            my $int = oct('0b1' . join('', map { read_bit($fh, \$buffer) } 1 .. ($bl2 - 1)));

            push @deltas, ($bit eq '1' ? 1 : -1) * ($int - 1);
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

sub bwt_balanced ($s) {    # O(n * LOOKAHEAD_LEN) space (fast)
#<<<
    [
     map { $_->[1] } sort {
              ($a->[0] cmp $b->[0])
           || ((substr($s, $a->[1]) . substr($s, 0, $a->[1])) cmp(substr($s, $b->[1]) . substr($s, 0, $b->[1])))
     }
     map {
         my $t = substr($s, $_, LOOKAHEAD_LEN);

         if (length($t) < LOOKAHEAD_LEN) {
             $t .= substr($s, 0, ($_ < LOOKAHEAD_LEN) ? $_ : (LOOKAHEAD_LEN - length($t)));
         }

         [$t, $_]
       } 0 .. length($s) - 1
    ];
#>>>
}

sub bwt_encode ($s) {

    my $bwt = bwt_balanced($s);
    my $ret = join('', map { substr($s, $_ - 1, 1) } @$bwt);

    my $idx = 0;
    foreach my $i (@$bwt) {
        $i || last;
        ++$idx;
    }

    return ($ret, $idx);
}

sub bwt_decode ($bwt, $idx) {    # fast inversion

    my @tail = split(//, $bwt);
    my @head = sort @tail;

    my %indices;
    foreach my $i (0 .. $#tail) {
        push @{$indices{$tail[$i]}}, $i;
    }

    my @table;
    foreach my $v (@head) {
        push @table, shift(@{$indices{$v}});
    }

    my $dec = '';
    my $i   = $idx;

    for (1 .. scalar(@head)) {
        $dec .= $head[$i];
        $i = $table[$i];
    }

    return $dec;
}

sub lzss_compression ($chunk, $out_fh) {
    my (@uncompressed, @indices, @lengths);
    lz77_compression($chunk, \@uncompressed, \@indices, \@lengths);

    my $est_ratio = length($chunk) / (scalar(@uncompressed) + scalar(@lengths) + 2 * scalar(@indices));
    say scalar(@uncompressed), ' -> ', $est_ratio;

    deflate_encode(\@uncompressed, \@indices, \@lengths, $out_fh);
}

sub lzss_decompression ($fh, $out_fh) {
    my ($uncompressed, $indices, $lengths) = deflate_decode($fh);
    print $out_fh lz77_decompression($uncompressed, $indices, $lengths);
}

sub run_length ($arr) {

    @$arr || return [];

    my @result     = [$arr->[0], 1];
    my $prev_value = $arr->[0];

    foreach my $i (1 .. $#{$arr}) {

        my $curr_value = $arr->[$i];

        if ($curr_value eq $prev_value) {
            ++$result[-1][1];
        }
        else {
            push(@result, [$curr_value, 1]);
        }

        $prev_value = $curr_value;
    }

    return \@result;
}

sub VLR_encoding ($bytes) {

    my $uncompressed = '';
    my $bitstream    = '';
    my $rle          = run_length($bytes);

    foreach my $cv (@$rle) {
        my ($c, $v) = @$cv;
        $uncompressed .= $c;
        if ($v == 1) {
            $bitstream .= '0';
        }
        else {
            my $t = sprintf('%b', $v);
            $bitstream .= join('', '1' x (length($t) - 1), '0', substr($t, 1));
        }
    }

    return ($uncompressed, pack('B*', $bitstream));
}

sub VLR_decoding ($uncompressed, $bits_fh) {

    my $decoded = '';
    my $buffer  = '';

    foreach my $c (@$uncompressed) {

        my $bl = 0;
        while (read_bit($bits_fh, \$buffer) == 1) {
            ++$bl;
        }

        if ($bl > 0) {
            $decoded .= $c x oct('0b1' . join('', map { read_bit($bits_fh, \$buffer) } 1 .. $bl));
        }
        else {
            $decoded .= $c;
        }
    }

    return $decoded;
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

        my ($bwt,          $idx)     = bwt_encode($chunk);
        my ($uncompressed, $lengths) = VLR_encoding([split(//, $bwt)]);

        print $out_fh pack('N', $idx);

        lzss_compression($uncompressed, $out_fh);
        lzss_compression($lengths,      $out_fh);
    }

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

        my $uncompressed = '';
        my $lengths      = '';

        open my $uc_fh,  '>:raw',  \$uncompressed;
        open my $len_fh, '+>:raw', \$lengths;

        my $idx = unpack('N', join('', map { getc($fh) // die "decompression error" } 1 .. 4));

        lzss_decompression($fh, $uc_fh);     # uncompressed
        lzss_decompression($fh, $len_fh);    # lengths

        seek($len_fh, 0, 0);

        my $dec = VLR_decoding([split(//, $uncompressed)], $len_fh);
        print $out_fh bwt_decode($dec, $idx);
    }

    close $fh;
    close $out_fh;
}

main();
exit(0);
