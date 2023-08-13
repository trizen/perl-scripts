#!/usr/bin/perl

# Author: Trizen
# Date: 13 August 2023
# https://github.com/trizen

# Compress/decompress files using Run-length encoding + Arithmetic Coding.

use 5.036;

use Getopt::Std    qw(getopts);
use File::Basename qw(basename);
use List::Util     qw(max uniq sum);
use Math::GMPz;

use constant {
    PKGNAME => 'RLAC',
    VERSION => '0.01',
    FORMAT  => 'rlac',

    CHUNK_SIZE => 1 << 15,
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

sub cumulative_freq ($freq) {

    my %cf;
    my $total = 0;
    foreach my $c (sort { $a <=> $b } keys %$freq) {
        $cf{$c} = $total;
        $total += $freq->{$c};
    }

    return %cf;
}

sub ac_encode ($bytes_arr) {

    my @chars = @$bytes_arr;

    # The frequency characters
    my %freq;
    ++$freq{$_} for @chars;

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
        Math::GMPz::Rmpz_addmul_ui($L, $pf, $cf{$c});
        Math::GMPz::Rmpz_mul_ui($pf, $pf, $freq{$c});
    }

    # Upper bound
    Math::GMPz::Rmpz_add($L, $L, $pf);

    # Compute the power for left shift
    my $pow = Math::GMPz::Rmpz_sizeinbase($pf, 2) - 1;

    # Set $enc to (U-1) divided by 2^pow
    Math::GMPz::Rmpz_sub_ui($L, $L, 1);
    Math::GMPz::Rmpz_div_2exp($L, $L, $pow);

    # Remove any divisibility by 2
    if ($L > 0 and Math::GMPz::Rmpz_even_p($L)) {
        $pow += Math::GMPz::Rmpz_remove($L, $L, Math::GMPz->new(2));
    }

    my $bin = Math::GMPz::Rmpz_get_str($L, 2);

    return ($bin, $pow, \%freq);
}

sub ac_decode ($bits, $pow2, $freq) {

    # Decode the bits into an integer
    my $enc = Math::GMPz->new($bits, 2);
    Math::GMPz::Rmpz_mul_2exp($enc, $enc, $pow2);

    my $base = sum(values %$freq) // 0;

    if ($base == 0) {
        return [];
    }
    elsif ($base == 1) {
        return [keys %$freq];
    }

    # Create the cumulative frequency table
    my %cf = cumulative_freq($freq);

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

    my $div = Math::GMPz::Rmpz_init();

    my @dec;

    # Decode the input number
    for (my $pow = Math::GMPz->new($base)**($base - 1) ;
         Math::GMPz::Rmpz_sgn($pow) > 0 ;
         Math::GMPz::Rmpz_tdiv_q_ui($pow, $pow, $base)) {

        Math::GMPz::Rmpz_tdiv_q($div, $enc, $pow);

        my $c  = $dict{$div};
        my $fv = $freq->{$c};
        my $cv = $cf{$c};

        Math::GMPz::Rmpz_submul_ui($enc, $pow, $cv);
        Math::GMPz::Rmpz_tdiv_q_ui($enc, $enc, $fv);

        push @dec, $c;
    }

    return \@dec;
}

sub create_ac_entry ($bytes, $out_fh) {

    my ($enc, $pow, $freq) = ac_encode($bytes);

    my @symbols = sort { $a <=> $b } keys(%$freq);

    print $out_fh delta_encode([@symbols]);
    print $out_fh delta_encode([(map { $freq->{$_} } @symbols), $pow, length($enc)], 1);

    print $out_fh pack("B*", $enc);
}

sub decode_ac_entry ($fh) {

    my $symbols = delta_decode($fh);
    my $freqs   = delta_decode($fh, 1);

    my $bits_len = pop(@$freqs);
    my $pow2     = pop(@$freqs);

    my %freq;
    foreach my $i (0 .. $#{$symbols}) {
        $freq{$symbols->[$i]} = $freqs->[$i];
    }

    my $bits = read_bits($fh, $bits_len);

    if ($bits_len > 0) {
        return ac_decode($bits, $pow2, \%freq);
    }

    return [];
}

sub rle4_encode ($bytes) {    # RLE1

    my @rle;
    my $end  = $#{$bytes};
    my $prev = -1;
    my $run  = 0;

    for (my $i = 0 ; $i <= $end ; ++$i) {

        if ($bytes->[$i] == $prev) {
            ++$run;
        }
        else {
            $run = 1;
        }

        push @rle, $bytes->[$i];
        $prev = $bytes->[$i];

        if ($run >= 4) {

            $run = 0;
            $i += 1;

            while ($i <= $end and $bytes->[$i] == $prev) {
                ++$run;
                ++$i;
            }

            push @rle, $run;
            $run = 1;

            if ($i <= $end) {
                $prev = $bytes->[$i];
                push @rle, $bytes->[$i];
            }
        }
    }

    return \@rle;
}

sub rle4_decode ($bytes) {    # RLE1

    my @dec  = $bytes->[0];
    my $end  = $#{$bytes};
    my $prev = $bytes->[0];
    my $run  = 1;

    for (my $i = 1 ; $i <= $end ; ++$i) {

        if ($bytes->[$i] == $prev) {
            ++$run;
        }
        else {
            $run = 1;
        }

        push @dec, $bytes->[$i];
        $prev = $bytes->[$i];

        if ($run >= 4) {
            if (++$i <= $end) {
                $run = $bytes->[$i];
                push @dec, (($prev) x $run);
            }

            $run = 0;
        }
    }

    return \@dec;
}

sub compression ($chunk, $out_fh) {
    my $bytes = [unpack('C*', $chunk)];
    $bytes = rle4_encode($bytes);
    create_ac_entry($bytes, $out_fh);
}

sub decompression ($fh, $out_fh) {
    my $bytes = decode_ac_entry($fh);
    $bytes = rle4_decode($bytes);
    print $out_fh pack('C*', @$bytes);
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
