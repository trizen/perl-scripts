#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 11 February 2016
# Edit: 08 June 2023
# https://github.com/trizen

# Arithmetic coding compressor for small files.

# See also:
#   https://en.wikipedia.org/wiki/Arithmetic_coding#Arithmetic_coding_as_a_generalized_change_of_radix

use 5.020;
use strict;
use autodie;
use warnings;

use Getopt::Std    qw(getopts);
use File::Basename qw(basename);
use experimental   qw(signatures);

use Math::GMPz;

use constant {
              PKGNAME => 'TAC Compressor',
              VERSION => '0.03',
              FORMAT  => 'tac',
             };

use constant {SIGNATURE => uc(FORMAT) . chr(3)};

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

    my $compressed = chr(scalar @counts);

    foreach my $pair (@counts) {
        my ($blen, $len) = @$pair;
        $compressed .= chr($blen);
        $compressed .= pack('N', $len);
    }

    my $bits = '';
    foreach my $pair (@counts) {
        my ($blen, $len) = @$pair;

        foreach my $symbol (splice(@$integers, 0, $len)) {
            $bits .= sprintf("%0*b", $blen, $symbol);
        }

        if (length($bits) % 8 == 0) {
            $compressed .= pack('B*', $bits);
            $bits = '';
        }
    }

    if ($bits ne '') {
        $compressed .= pack('B*', $bits);
    }

    return $compressed;
}

sub decode_integers ($fh) {

    my $count_len = ord(getc($fh));

    my @counts;
    my $bits_len = 0;

    for (1 .. $count_len) {
        my $blen = ord(getc($fh));
        my $len  = unpack('N', join('', map { getc($fh) } 1 .. 4));
        push @counts, [$blen + 0, $len + 0];
        $bits_len += $blen * $len;
    }

    my $bits = read_bits($fh, $bits_len);

    my @chunks;
    foreach my $pair (@counts) {
        my ($blen, $len) = @$pair;
        $len > 0 or next;
        foreach my $chunk (unpack(sprintf('(a%d)*', $blen), substr($bits, 0, $blen * $len, ''))) {
            push @chunks, oct('0b' . $chunk);
        }
    }

    return \@chunks;
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

    my @chars = split(//, $str);

    # The frequency characters
    my %freq;
    $freq{$_}++ for @chars;

    # Create the cumulative frequency table
    my %cf = cumulative_freq(\%freq);

    # Limit and base
    my $base = Math::GMPz->new(scalar @chars);

    # Lower bound
    my $L = Math::GMPz->new(0);

    # Product of all frequencies
    my $pf = Math::GMPz->new(1);

    # Each term is multiplied by the product of the
    # frequencies of all previously occurring symbols
    foreach my $c (@chars) {
        Math::GMPz::Rmpz_mul($L, $L, $base);
        Math::GMPz::Rmpz_addmul($L, $pf, $cf{$c});
        Math::GMPz::Rmpz_mul_ui($pf, $pf, $freq{$c});
    }

    # Upper bound
    my $U = $L + $pf;

    # Compute the power for left shift
    my $pow = Math::GMPz::Rmpz_sizeinbase($pf, 2) - 1;

    # Set $enc to (U-1) divided by 2^pow
    my $enc = ($U - 1) >> $pow;

    # Remove any divisibility by 2
    if ($enc > 0 and Math::GMPz::Rmpz_even_p($enc)) {
        $pow += Math::GMPz::Rmpz_remove($enc, $enc, Math::GMPz->new(2));
    }

    my $bin = Math::GMPz::Rmpz_get_str($enc, 2);

    my $encoded = '';
    $encoded .= chr(scalar(keys %freq) - 1);    # number of unique chars
    $encoded .= pack('N', length($bin));

    my @freqs;

    foreach my $k (sort { ($freq{$a} <=> $freq{$b}) || ($a cmp $b) } keys %freq) {
        push @freqs, $freq{$k};
        $encoded .= $k;
    }

    push @freqs, $pow;
    $encoded .= encode_integers(\@freqs);

    print {$out_fh} $encoded;
    print {$out_fh} pack('B*', $bin);
    close $out_fh;
}

sub decompress ($input, $output) {

    # Open and validate the input file
    open my $fh, '<:raw', $input;
    valid_archive($fh) || die "$0: file `$input' is not a \U${\FORMAT}\E archive!\n";

    my $num_symbols = ord(getc($fh));
    my $bits_len    = unpack('N', join('', map { getc($fh) } 1 .. 4));

    read($fh, (my $str), 1 + $num_symbols) == 1 + $num_symbols
      or die "Can't read symbols...";

    my @chars = split(//, $str);
    my @freqs = @{decode_integers($fh)};
    my $pow2  = pop(@freqs);

    if (scalar(@chars) != scalar(@freqs)) {
        die "Invalid encoding...";
    }

    # Create the frequency table (char => freq)
    my %freq;
    foreach my $i (0 .. $#chars) {
        $freq{$chars[$i]} = $freqs[$i];
    }

    # Decode the bits into an integer
    my $enc = Math::GMPz->new(read_bits($fh, $bits_len), 2);

    $enc <<= $pow2;

    my $base = 0;
    $base += $_ for values %freq;

    # Create the cumulative frequency table
    my %cf = cumulative_freq(\%freq);

    # Create the dictionary
    my %dict;
    while (my ($k, $v) = each %cf) {
        $dict{$v} = $k;
    }

    # Fill the gaps in the dictionary
    my $lchar;
    foreach my $i (0 .. $base - 1) {
        if (exists $dict{$i}) {
            $lchar = $dict{$i};
        }
        elsif (defined $lchar) {
            $dict{$i} = $lchar;
        }
    }

    # Open the output file
    open my $out_fh, '>:raw', $output;

    my $div = Math::GMPz::Rmpz_init();

    # Decode the input number
    for (my $pow = Math::GMPz->new($base)**($base - 1) ;
         Math::GMPz::Rmpz_sgn($pow) > 0 ;
         Math::GMPz::Rmpz_tdiv_q_ui($pow, $pow, $base)) {

        Math::GMPz::Rmpz_tdiv_q($div, $enc, $pow);

        my $c  = $dict{$div};
        my $fv = $freq{$c};
        my $cv = $cf{$c};

        Math::GMPz::Rmpz_submul($enc, $pow, $cv);
        Math::GMPz::Rmpz_tdiv_q_ui($enc, $enc, $fv);

        print {$out_fh} $c;
    }

    close $out_fh;
}

main();
exit(0);
