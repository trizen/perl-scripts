#!/usr/bin/perl

# Author: Trizen
# Date: 19 March 2024
# https://github.com/trizen

use 5.036;
use File::Temp            qw(tempdir tempfile);
use File::Compare         qw(compare);
use File::Basename        qw(basename);
use File::Spec::Functions qw(catfile);
use Time::HiRes           qw(gettimeofday tv_interval);

my %ignored_methods = (
    'tac_file_compression.pl'   => 1,    # slow
    'tacc_file_compression.pl'  => 1,    # slow
    'tzip_file_compression.pl'  => 1,    # poor compression / slow
    'tzip2_file_compression.pl' => 1,    # poor compression / slow
    'lzt_file_compression.pl'   => 1,    # poor compression
    'lzhc_file_compression.pl'  => 1,    # very poor compression
    'lzt2_file_compression.pl'  => 1,    # slow
    'bbwr_file_compression.pl'  => 1,    # slow
    'ppmh_file_compression.pl'  => 1,    # slow
                      );

my $input_file       = shift(@ARGV) // die "usage: perl $0 [input file]\n";
my $compressed_dir   = tempdir(CLEANUP => 1);
my $decompressed_dir = tempdir(CLEANUP => 1);

my @stats = ({format => 'orig', filename => basename($input_file), compression_time => 0, decompression_time => 0, size => -s $input_file});

foreach my $file (glob("*_file_compression.pl")) {

    next if $ignored_methods{$file};

    say "\n:: Testing: $file";
    my ($format) = $file =~ /^([^_]+)/;

    my $basename        = basename($input_file) . '.' . $format;
    my $compressed_file = catfile($compressed_dir, $basename);
    my $compression_t0  = [gettimeofday];
    system($^X, $file, '-i', $input_file, '-o', $compressed_file);
    my $compression_dt = tv_interval($compression_t0);
    $? == 0 or die "compression error for: $file";

    my (undef, $decompressed_file) = tempfile(DIR => $decompressed_dir);
    my $decompression_t0 = [gettimeofday];
    system($^X, $file, '-r', '-e', '-i', $compressed_file, '-o', $decompressed_file);
    my $decompression_dt = tv_interval($decompression_t0);
    $? == 0 or die "decompression error for: $file";

    if (compare($decompressed_file, $input_file) != 0) {
        die "Decompressed file does not match the input file for: $file";
    }

    push @stats,
      {
        format             => $format,
        filename           => $basename,
        compression_time   => $compression_dt,
        decompression_time => $decompression_dt,
        size               => -s $compressed_file,
      };
}

say '';
printf("%7s %6s %6s %6s %s\n", "SIZE", "RATIO", "COMPRE", "DECOMP", "FILENAME");
foreach my $entry (sort { $a->{size} <=> $b->{size} } @stats) {
    printf("%7s %6.3f %6.3f %6.3f %s\n",
           $entry->{size},
           (-s $input_file) / $entry->{size},
           $entry->{compression_time},
           $entry->{decompression_time},
           $entry->{filename});
}

say '';
my $top = 20;

say "Top $top fastest compression methods: ",
  join(', ', map { $_->{format} } (sort { $a->{compression_time} <=> $b->{compression_time} } grep { $_->{compression_time} > 0 } @stats)[0 .. $top - 1]);
say "Top $top fastest decompression methods: ",
  join(', ', map { $_->{format} } (sort { $a->{decompression_time} <=> $b->{decompression_time} } grep { $_->{decompression_time} > 0 } @stats)[0 .. $top - 1]);

say '';
say "Top $top slowest compression methods: ",
  join(', ', map { $_->{format} } (sort { $b->{compression_time} <=> $a->{compression_time} } grep { $_->{compression_time} > 0 } @stats)[0 .. $top - 1]);
say "Top $top slowest decompression methods: ",
  join(', ', map { $_->{format} } (sort { $b->{decompression_time} <=> $a->{decompression_time} } grep { $_->{decompression_time} > 0 } @stats)[0 .. $top - 1]);

__END__
   SIZE  RATIO COMPRE DECOMP FILENAME
   2356  6.088  0.150  0.145 perl.bwad
   2379  6.029  0.211  0.207 perl.bwlzad
   2413  5.944  0.056  0.038 perl.bwac
   2414  5.942  0.056  0.052 perl.bwaz
   2426  5.913  0.086  0.072 perl.bwlza
   2426  5.913  0.052  0.034 perl.bwt
   2443  5.871  0.082  0.067 perl.bwlz
   2591  5.536  0.126  0.043 perl.bwrm
   2626  5.462  0.141  0.049 perl.bwrl2
   2653  5.407  0.154  0.076 perl.bwrlz
   2695  5.322  0.169  0.182 perl.lzsad
   2751  5.214  0.140  0.052 perl.bwrla
   2760  5.197  0.139  0.050 perl.bwrl
   2819  5.088  0.063  0.048 perl.lzsa
   2835  5.060  0.106  0.074 perl.bwlz2
   2836  5.058  0.061  0.050 perl.lzss
   2865  5.007  0.086  0.048 perl.lzsbw
   2868  5.001  0.043  0.042 perl.lzaz
   2870  4.998  0.041  0.035 perl.lzac
   2878  4.984  0.036  0.031 perl.lzhd
   2980  4.813  0.047  0.028 perl.bww
   3003  4.777  0.050  0.040 perl.mra
   3014  4.759  0.132  0.128 perl.lzbwad
   3025  4.742  0.046  0.030 perl.mrh
   3027  4.739  0.034  0.024 perl.lzw
   3028  4.737  0.057  0.035 perl.lzbwd
   3072  4.669  0.061  0.036 perl.lzbwh
   3176  4.516  0.062  0.039 perl.lzbwa
   3186  4.502  0.059  0.037 perl.lzbw
   3214  4.463  0.035  0.030 perl.lzih
   3230  4.441  0.023  0.030 perl.rlh
   3335  4.301  0.047  0.037 perl.lzh
   3504  4.094  0.031  0.041 perl.rlac
   4052  3.540  0.032  0.035 perl.hfm
   4193  3.421  0.038  0.021 perl.lz77
  14344  1.000  0.000  0.000 perl

Top 20 fastest compression methods: rlh, rlac, hfm, lzw, lzih, lzhd, lz77, lzac, lzaz, mrh, bww, lzh, mra, bwt, bwaz, bwac, lzbwd, lzbw, lzbwh, lzss
Top 20 fastest decompression methods: lz77, lzw, bww, lzih, rlh, mrh, lzhd, bwt, lzbwd, lzac, hfm, lzbwh, lzbw, lzh, bwac, lzbwa, mra, rlac, lzaz, bwrm

Top 20 slowest compression methods: bwlzad, lzsad, bwrlz, bwad, bwrl2, bwrla, bwrl, lzbwad, bwrm, bwlz2, lzsbw, bwlza, bwlz, lzsa, lzbwa, lzss, lzbwh, lzbw, lzbwd, bwac
Top 20 slowest decompression methods: bwlzad, lzsad, bwad, lzbwad, bwrlz, bwlz2, bwlza, bwlz, bwrla, bwaz, bwrl, lzss, bwrl2, lzsa, lzsbw, bwrm, lzaz, rlac, mra, lzbwa
