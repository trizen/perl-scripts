#!/usr/bin/perl

# Author: Trizen
# Date: 11 August 2023
# https://github.com/trizen

# Compress/decompress files using Prediction by partial-matching (PPM) + Huffman coding.

# Reference:
#   Data Compression (Summer 2023) - Lecture 16 - Adaptive Methods
#   https://youtube.com/watch?v=YKv-w8bXi9c

use 5.036;

use Getopt::Std    qw(getopts);
use File::Basename qw(basename);
use List::Util     qw(max uniq);

use constant {
    PKGNAME => 'PPMH',
    VERSION => '0.01',
    FORMAT  => 'ppmh',

    CHUNK_SIZE      => 1 << 16,
    ESCAPE_SYMBOL   => 256,       # escape symbol
    CONTEXTS_NUM    => 4,         # maximum number of contexts
    INITIAL_CONTEXT => 1,         # start in this context
    VERBOSE         => 0,         # verbose/debug mode

    PPM_MODE     => chr(0),
    VLR_MODE     => chr(1),
    HUFFMAN_MODE => chr(2),
};

use constant {SIGNATURE => uc(FORMAT) . chr(1)};

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
            my $t = sprintf('%b', abs($d));
            my $l = sprintf('%b', length($t) + 1);
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

            my $bl2 = oct('0b1' . join('', map { read_bit($fh, \$buffer) } 1 .. $bl)) - 1;
            my $int = oct('0b1' . join('', map { read_bit($fh, \$buffer) } 1 .. ($bl2 - 1)));

            push @deltas, ($bit eq '1' ? $int : -$int);
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

sub encode_alphabet ($alphabet) {

    my %table;
    @table{@$alphabet} = ();

    my $populated = 0;
    my @marked;

    for (my $i = 0 ; $i <= 255 ; $i += 32) {

        my $enc = 0;
        foreach my $j (0 .. 31) {
            if (exists($table{$i + $j})) {
                $enc |= 1 << $j;
            }
        }

        $populated <<= 1;

        if ($enc != 0) {
            $populated |= 1;
            push @marked, $enc;
        }
    }

    my $delta = delta_encode([@marked], 1);

    say "Uniq symbs : ", scalar(@$alphabet);
    say "Max symbol : ", max(@$alphabet);
    say "Populated  : ", sprintf('%08b', $populated);
    say "Marked     : @marked";
    say "Delta len  : ", length($delta);

    my $encoded = '';
    $encoded .= chr($populated);
    $encoded .= $delta;
    return $encoded;
}

sub decode_alphabet ($fh) {

    my @populated = split(//, sprintf('%08b', ord(getc($fh))));
    my $marked    = delta_decode($fh, 1);

    my @alphabet;
    for (my $i = 0 ; $i <= 255 ; $i += 32) {
        if (shift(@populated)) {
            my $m = shift(@$marked);
            foreach my $j (0 .. 31) {
                if ($m & 1) {
                    push @alphabet, $i + $j;
                }
                $m >>= 1;
            }
        }
    }

    return \@alphabet;
}

sub freq ($arr) {
    my %freq;
    ++$freq{$_} for @$arr;
    return \%freq;
}

sub ppm_encode ($symbols, $alphabet) {

    my @enc;
    my @prev;
    my $s = join(' ', @prev);

    my @ctx = ({$s => {freq => freq($alphabet)}},);

    foreach my $i (1 .. CONTEXTS_NUM) {
        push @ctx, {$s => {freq => freq([ESCAPE_SYMBOL])}};
    }

    foreach my $c (@ctx) {
        $c->{$s}{tree} = (mktree_from_freq($c->{$s}{freq}))[0];
    }

    my $prev_ctx = INITIAL_CONTEXT;

    foreach my $symbol (@$symbols) {

        foreach my $k (reverse(0 .. $prev_ctx)) {
            $s = join(' ', @prev[max($#prev - $k + 2, 0) .. $#prev]);

            if (!exists($ctx[$k]{$s})) {
                $ctx[$k]{$s}{freq} = freq([ESCAPE_SYMBOL]);
            }

            if (exists($ctx[$k]{$s}{freq}{$symbol})) {

                if ($k != 0) {
                    $ctx[$k]{$s}{tree} = (mktree_from_freq($ctx[$k]{$s}{freq}))[0];
                    ++$ctx[$k]{$s}{freq}{$symbol};
                }

                say STDERR "Encoding $symbol with context=$k using $ctx[$k]{$s}{tree}{$symbol} and prefix ($s)" if VERBOSE;
                push @enc, $ctx[$k]{$s}{tree}{$symbol};
                ++$prev_ctx if ($prev_ctx < $#ctx);

                push @prev, $symbol;
                shift(@prev) if (scalar(@prev) >= CONTEXTS_NUM);
                last;
            }

            --$prev_ctx;
            $ctx[$k]{$s}{tree} = (mktree_from_freq($ctx[$k]{$s}{freq}))[0];
            push @enc, $ctx[$k]{$s}{tree}{(ESCAPE_SYMBOL)};
            say STDERR "Escaping from context = $k with $ctx[$k]{$s}{tree}{(ESCAPE_SYMBOL)}" if VERBOSE;
            $ctx[$k]{$s}{freq}{$symbol} = 1;
        }
    }

    return join('', @enc);
}

sub ppm_decode ($enc, $alphabet) {

    my @out;
    my @prev;
    my $prefix = '';
    my $s      = join(' ', @prev);

    my @ctx = ({$s => {freq => freq($alphabet)}},);

    foreach my $i (1 .. CONTEXTS_NUM) {
        push @ctx, {$s => {freq => freq([ESCAPE_SYMBOL])}},;
    }

    foreach my $c (@ctx) {
        $c->{$s}{tree} = (mktree_from_freq($c->{$s}{freq}))[1];
    }

    my $prev_ctx = my $context = INITIAL_CONTEXT;
    my @key      = @prev;

    foreach my $bit (split(//, $enc)) {

        $prefix .= $bit;

        if (!exists($ctx[$context]{$s})) {
            $ctx[$context]{$s}{freq} = freq([ESCAPE_SYMBOL]);
            $ctx[$context]{$s}{tree} = (mktree_from_freq($ctx[$context]{$s}{freq}))[1];
        }

        if (exists($ctx[$context]{$s}{tree}{$prefix})) {
            my $symbol = $ctx[$context]{$s}{tree}{$prefix};
            if ($symbol == ESCAPE_SYMBOL) {
                --$context;
                shift(@key) if (scalar(@key) >= $context);
                $s = join(' ', @key);
            }
            else {
                push @out, $symbol;
                foreach my $k (max($context, 1) .. $prev_ctx) {
                    my $s = join(' ', @prev[max($#prev - $k + 2, 0) .. $#prev]);
                    $ctx[$k]{$s}{freq} //= freq([ESCAPE_SYMBOL]);
                    ++$ctx[$k]{$s}{freq}{$symbol};
                    $ctx[$k]{$s}{tree} = (mktree_from_freq($ctx[$k]{$s}{freq}))[1];
                }
                ++$context if ($context < $#ctx);
                $prev_ctx = $context;
                push @prev, $symbol;
                shift(@prev) if (scalar(@prev) >= CONTEXTS_NUM);
                @key = @prev[max($#prev - $context + 2, 0) .. $#prev];
                $s   = join(' ', @key);
            }
            $prefix = '';
        }
    }

    return \@out;
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

sub binary_vrl_encoding ($str) {

    my @bits      = split(//, $str);
    my $bitstring = $bits[0];

    foreach my $rle (@{run_length(\@bits)}) {
        my ($c, $v) = @$rle;

        if ($v == 1) {
            $bitstring .= '0';
        }
        else {
            my $t = sprintf('%b', $v - 1);
            $bitstring .= join('', '1' x length($t), '0', substr($t, 1));
        }
    }

    return $bitstring;
}

sub binary_vrl_decoding ($bitstring) {

    open my $fh, '<:raw', \$bitstring;

    my $decoded = '';
    my $bit     = getc($fh);

    while (!eof($fh)) {

        $decoded .= $bit;

        my $bl = 0;
        while (getc($fh) == 1) {
            ++$bl;
        }

        if ($bl > 0) {
            $decoded .= $bit x oct('0b1' . join('', map { getc($fh) } 1 .. $bl - 1));
        }

        $bit = ($bit eq '1' ? '0' : '1');
    }

    return $decoded;
}

sub huffman_encode ($bytes, $dict) {
    join('', @{$dict}{@$bytes});
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
    say "Max symbol : $max_symbol\n";

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
    say "Encoded length: $enc_len\n";

    if ($enc_len > 0) {
        return [split(' ', huffman_decode(read_bits($fh, $enc_len), $rev_dict))];
    }

    return [];
}

sub compression ($chunk, $out_fh) {

    my @bytes        = unpack('C*', $chunk);
    my @alphabet     = sort { $a <=> $b } uniq(@bytes);
    my $alphabet_enc = encode_alphabet(\@alphabet);

    my $enc = ppm_encode(\@bytes, \@alphabet);
    printf("Before VRL : %s (saving %.2f%%)\n", length($enc), (length($chunk) - length($enc) / 8) / length($chunk) * 100);

    my $vrl_enc = binary_vrl_encoding($enc);
    printf("After VRL  : %s (saving %.2f%%)\n\n", length($vrl_enc), (length($chunk) - length($vrl_enc) / 8) / length($chunk) * 100);

    my $mode = PPM_MODE;

    if (length($vrl_enc) < length($enc)) {
        $mode = VLR_MODE;
        $enc  = $vrl_enc;
    }
    else {
        $mode = PPM_MODE;
    }

    if (length($enc) / 8 > length($chunk)) {
        $mode = HUFFMAN_MODE;
    }

    print $out_fh $mode;

    if ($mode eq HUFFMAN_MODE) {
        create_huffman_entry(\@bytes, $out_fh);
    }
    else {
        print $out_fh pack('N', length($enc));
        print $out_fh $alphabet_enc;
        print $out_fh pack('B*', $enc);
    }
}

sub decompression ($fh, $out_fh) {

    my $mode = getc($fh);

    if ($mode eq HUFFMAN_MODE) {
        say "Decoding Huffman entry...";
        print $out_fh pack('C*', @{decode_huffman_entry($fh)});
        return 1;
    }

    my $enc_len  = unpack('N', join('', map { getc($fh) // return undef } 1 .. 4));
    my $alphabet = decode_alphabet($fh);

    say "Length = $enc_len";
    say "Alphabet size: ", scalar(@$alphabet);

    my $bitstring = read_bits($fh, $enc_len);

    if ($mode eq VLR_MODE) {
        say "Decoding VRL...";
        $bitstring = binary_vrl_decoding($bitstring);
    }

    say '';
    print $out_fh pack('C*', @{ppm_decode($bitstring, $alphabet)});
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
