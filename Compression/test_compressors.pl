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
   2356  6.088  0.150  0.144 perl.bwad
   2359  6.081  0.187  0.172 perl.bwlzad2
   2379  6.029  0.202  0.190 perl.bwlzad
   2413  5.944  0.053  0.039 perl.bwac
   2414  5.942  0.057  0.054 perl.bwaz
   2418  5.932  0.087  0.064 perl.bwlza2
   2426  5.913  0.086  0.068 perl.bwlza
   2426  5.913  0.050  0.032 perl.bwt
   2443  5.871  0.082  0.071 perl.bwlz
   2591  5.536  0.128  0.045 perl.bwrm
   2626  5.462  0.132  0.049 perl.bwrl2
   2653  5.407  0.164  0.076 perl.bwrlz
   2695  5.322  0.164  0.179 perl.lzsad
   2751  5.214  0.156  0.061 perl.bwrla
   2760  5.197  0.143  0.063 perl.bwrl
   2819  5.088  0.064  0.049 perl.lzsa
   2831  5.067  0.089  0.051 perl.bwt2
   2835  5.060  0.115  0.067 perl.bwlz2
   2836  5.058  0.057  0.043 perl.lzss
   2865  5.007  0.093  0.048 perl.lzsbw
   2868  5.001  0.043  0.041 perl.lzaz
   2870  4.998  0.044  0.035 perl.lzac
   2878  4.984  0.039  0.030 perl.lzhd
   2905  4.938  0.205  0.102 perl.bwrlz2
   2980  4.813  0.046  0.027 perl.bww
   3003  4.777  0.056  0.041 perl.mra
   3014  4.759  0.130  0.125 perl.lzbwad
   3025  4.742  0.047  0.038 perl.mrh
   3027  4.739  0.028  0.023 perl.lzw
   3028  4.737  0.057  0.036 perl.lzbwd
   3030  4.734  0.079  0.051 perl.mrlz
   3072  4.669  0.062  0.037 perl.lzbwh
   3146  4.559  0.070  0.041 perl.mbwr
   3176  4.516  0.061  0.041 perl.lzbwa
   3186  4.502  0.057  0.037 perl.lzbw
   3214  4.463  0.036  0.029 perl.lzih
   3230  4.441  0.022  0.029 perl.rlh
   3321  4.319  0.057  0.040 perl.lza
   3335  4.301  0.047  0.039 perl.lzh
   3504  4.094  0.032  0.038 perl.rlac
   4052  3.540  0.030  0.034 perl.hfm
   4193  3.421  0.038  0.021 perl.lz77
  14344  1.000  0.000  0.000 perl

Top 20 fastest compression methods: rlh, lzw, hfm, rlac, lzih, lz77, lzhd, lzaz, lzac, bww, lzh, mrh, bwt, bwac, mra, lzss, lza, lzbwd, lzbw, bwaz
Top 20 fastest decompression methods: lz77, lzw, bww, rlh, lzih, lzhd, bwt, hfm, lzac, lzbwd, lzbwh, lzbw, rlac, mrh, bwac, lzh, lza, mra, lzaz, lzbwa

Top 20 slowest compression methods: bwrlz2, bwlzad, bwlzad2, lzsad, bwrlz, bwrla, bwad, bwrl, bwrl2, lzbwad, bwrm, bwlz2, lzsbw, bwt2, bwlza2, bwlza, bwlz, mrlz, mbwr, lzsa
Top 20 slowest decompression methods: bwlzad, lzsad, bwlzad2, bwad, lzbwad, bwrlz2, bwrlz, bwlz, bwlza, bwlz2, bwlza2, bwrl, bwrla, bwaz, mrlz, bwt2, bwrl2, lzsa, lzsbw, bwrm
