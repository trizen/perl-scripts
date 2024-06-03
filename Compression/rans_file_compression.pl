#!/usr/bin/perl

# File compression with rANS encoding, using big integers.

# Reference:
#   ‎Stanford EE274: Data Compression I 2023 I Lecture 7 - ANS
#   https://youtube.com/watch?v=5Hp4bnvSjng

use 5.036;
use Getopt::Std    qw(getopts);
use File::Basename qw(basename);
use List::Util     qw(max);

use Math::GMPz;

use constant {
              PKGNAME => 'rANS',
              VERSION => '0.01',
              FORMAT  => 'rans',
             };

# Container signature
use constant SIGNATURE => uc(FORMAT) . chr(1);

sub usage ($code = 0) {
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

    exit($code);
}

sub version {
    printf("%s %s\n", PKGNAME, VERSION);
    exit;
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

        decompress($input, $output)
          || die "$0: error: decompression failed!\n";
    }
    elsif ($input !~ $ext || (defined($output) && $output =~ $ext)) {
        $output //= basename($input) . '.' . FORMAT;
        compress($input, $output)
          || die "$0: error: compression failed!\n";
    }
    else {
        warn "$0: don't know what to do...\n";
        usage(1);
    }
}

sub valid_archive ($fh) {

    if (read($fh, (my $sig), length(SIGNATURE), 0) == length(SIGNATURE)) {
        $sig eq SIGNATURE || return;
    }

    return 1;
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

sub cumulative_freq ($freq) {

    my %cf;
    my $total = Math::GMPz->new(0);
    foreach my $c (sort keys %{$freq}) {
        $cf{$c} = $total;
        $total += $freq->{$c};
    }

    return %cf;
}

sub rans_base_enc($freq, $cumul, $M, $x_prev, $s, $block_id, $x) {

    Math::GMPz::Rmpz_div_ui($block_id, $x_prev, $freq->{$s});

    my $r    = Math::GMPz::Rmpz_mod_ui($x, $x_prev, $freq->{$s});
    my $slot = $cumul->{$s} + $r;

    Math::GMPz::Rmpz_mul_ui($x, $block_id, $M);
    Math::GMPz::Rmpz_add_ui($x, $x, $slot);

    return $x;
}

sub encode($input, $freq, $cumul, $M) {

    my $x        = Math::GMPz::Rmpz_init_set_ui(0);
    my $block_id = Math::GMPz::Rmpz_init();
    my $next_x   = Math::GMPz::Rmpz_init();

    foreach my $s (@$input) {
        $x = rans_base_enc($freq, $cumul, $M, $x, $s, $block_id, $next_x);
    }

    return $x;
}

sub rans_base_dec($alphabet, $freq, $cumul, $M, $x, $block_id, $slot, $x_prev) {

    Math::GMPz::Rmpz_tdiv_qr_ui($block_id, $slot, $x, $M);

    my ($left, $right, $mid, $cmp) = (0, $#{$alphabet});

    while (1) {

        $mid = ($left + $right) >> 1;
        $cmp = ($cumul->{$alphabet->[$mid]} <=> $slot) || last;

        if ($cmp < 0) {
            $left = $mid + 1;
            $left > $right and last;
        }
        else {
            $right = $mid - 1;

            if ($left > $right) {
                $mid -= 1;
                last;
            }
        }
    }

    my $s = $alphabet->[$mid];

    Math::GMPz::Rmpz_mul_ui($x_prev, $block_id, $freq->{$s});
    Math::GMPz::Rmpz_add($x_prev, $x_prev, $slot);
    Math::GMPz::Rmpz_sub_ui($x_prev, $x_prev, $cumul->{$s});

    return ($s, $x_prev);
}

sub decode($x, $alphabet, $freq, $cumul, $M) {

    my @dec;
    my $s = undef;

    my $block_id = Math::GMPz::Rmpz_init();
    my $slot     = Math::GMPz::Rmpz_init();
    my $x_prev   = Math::GMPz::Rmpz_init();

    for (1 .. $M) {
        ($s, $x) = rans_base_dec($alphabet, $freq, $cumul, $M, $x, $block_id, $slot, $x_prev);
        push @dec, $s;
    }

    return [reverse @dec];
}

sub compress ($input, $output) {

    # Open the input file
    open my $fh, '<:raw', $input;

    # Open the output file and write the archive signature
    open my $out_fh, '>:raw', $output;
    print {$out_fh} SIGNATURE;

    my $str = do {
        local $/;
        scalar(<$fh>);
    };

    close $fh;

    my (%freq, %cumul);
    my @symbols = unpack('C*', $str);
    ++$freq{$_} for @symbols;

    my @alphabet = sort { $a <=> $b } keys %freq;

    my $t = 0;
    foreach my $s (@alphabet) {
        $cumul{$s} = $t;
        $t += $freq{$s};
    }

    my $M   = $t;
    my $enc = encode(\@symbols, \%freq, \%cumul, $M);

    my $bin        = Math::GMPz::Rmpz_get_str($enc, 2);
    my $max_symbol = max(keys %freq) // 0;

    my @freqs;
    foreach my $k (0 .. $max_symbol) {
        push @freqs, $freq{$k} // 0;
    }

    print {$out_fh} delta_encode(\@freqs);
    print {$out_fh} pack('N',  length($bin));
    print {$out_fh} pack('B*', $bin);
    close $out_fh;
}

sub decompress ($input, $output) {

    # Open and validate the input file
    open my $fh, '<:raw', $input;
    valid_archive($fh) || die "$0: file `$input' is not a \U${\FORMAT}\E archive!\n";

    my @freqs    = @{delta_decode($fh)};
    my $bits_len = unpack('N', join('', map { getc($fh) // die "error" } 1 .. 4));

    # Create the frequency table
    my %freq;
    foreach my $i (0 .. $#freqs) {
        if ($freqs[$i] > 0) {
            $freq{$i} = $freqs[$i];
        }
    }

    # Decode the bits into an integer
    my $enc = Math::GMPz->new(read_bits($fh, $bits_len), 2);

    # Open the output file
    open my $out_fh, '>:raw', $output;

    my @alphabet = sort { $a <=> $b } keys %freq;

    my $t = 0;
    my %cumul;
    foreach my $s (@alphabet) {
        $cumul{$s} = $t;
        $t += $freq{$s};
    }

    my $M       = $t;
    my $symbols = decode($enc, \@alphabet, \%freq, \%cumul, $M);
    print $out_fh pack('C*', @$symbols);
    close $out_fh;
}

main();
exit(0);
