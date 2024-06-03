#!/usr/bin/perl

# Author: Trizen
# Date: 19 March 2024
# https://github.com/trizen

use 5.036;
use File::Temp            qw(tempdir tempfile);
use File::Compare         qw(compare);
use File::Basename        qw(basename);
use File::Spec::Functions qw(catfile);
use List::Util            qw(min);
use Time::HiRes           qw(gettimeofday tv_interval);

my %ignored_methods = (
    'tac_file_compression.pl'   => 1,    # slow
    'tacc_file_compression.pl'  => 1,    # slow
    'rans_file_compression.pl'  => 1,    # slow
    'tzip_file_compression.pl'  => 1,    # poor compression / slow
    'tzip2_file_compression.pl' => 1,    # poor compression / slow
    'lzt_file_compression.pl'   => 1,    # poor compression
    'lzhc_file_compression.pl'  => 1,    # very poor compression
    'lzt2_file_compression.pl'  => 1,    # slow
    'bbwr_file_compression.pl'  => 1,    # slow
    'ppmh_file_compression.pl'  => 1,    # slow
                      );

my $input_file       = shift(@ARGV) // die "usage: perl $0 [input file] [regex]\n";
my $regex = shift(@ARGV) // '';

if (not -f $input_file) {
    die "Error for input file <<$input_file>>: $!\n";
}

my $compressed_dir   = tempdir(CLEANUP => 1);
my $decompressed_dir = tempdir(CLEANUP => 1);

my @stats = ({format => 'orig', filename => basename($input_file), compression_time => 0, decompression_time => 0, size => -s $input_file});

sub commify ($n) {
    scalar reverse(reverse($n) =~ s/(\d{3})(?=\d)/$1,/gr);
}

foreach my $file (glob("*_file_compression.pl")) {

    next if $ignored_methods{$file};
    $file =~ /$regex/o or next;

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
printf("%8s %6s %6s %6s %s\n", "SIZE", "RATIO", "COMPRE", "DECOMP", "FILENAME");
foreach my $entry (sort { $a->{size} <=> $b->{size} } @stats) {
    printf("%8s %6.3f %6.3f %6.3f %s\n",
           commify($entry->{size}),
           (-s $input_file) / $entry->{size},
           $entry->{compression_time},
           $entry->{decompression_time},
           $entry->{filename});
}

say '';
my $top = min(20, scalar(@stats) - 1);

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
   2,356  6.088  0.148  0.144 perl.bwad
   2,359  6.081  0.187  0.192 perl.bwlzad2
   2,379  6.029  0.210  0.193 perl.bwlzad
   2,413  5.944  0.053  0.037 perl.bwac
   2,414  5.942  0.056  0.051 perl.bwaz
   2,418  5.932  0.083  0.067 perl.bwlza2
   2,426  5.913  0.090  0.065 perl.bwlza
   2,426  5.913  0.076  0.050 perl.bwt
   2,443  5.871  0.079  0.061 perl.bwlz
   2,591  5.536  0.136  0.043 perl.bwrm
   2,626  5.462  0.134  0.046 perl.bwrl2
   2,653  5.407  0.153  0.073 perl.bwrlz
   2,695  5.322  0.179  0.180 perl.lzsad
   2,751  5.214  0.141  0.052 perl.bwrla
   2,760  5.197  0.135  0.049 perl.bwrl
   2,819  5.088  0.079  0.069 perl.lzsa
   2,831  5.067  0.077  0.041 perl.bwt2
   2,835  5.060  0.104  0.065 perl.bwlz2
   2,836  5.058  0.057  0.042 perl.lzss
   2,865  5.007  0.086  0.048 perl.lzsbw
   2,868  5.001  0.043  0.041 perl.lzaz
   2,870  4.998  0.042  0.035 perl.lzac
   2,877  4.986  0.070  0.059 perl.bwlzss
   2,878  4.984  0.037  0.030 perl.lzhd
   2,905  4.938  0.169  0.077 perl.bwrlz2
   2,980  4.813  0.057  0.028 perl.bww
   3,003  4.777  0.051  0.042 perl.mra
   3,005  4.773  0.055  0.046 perl.bwlzhd
   3,014  4.759  0.135  0.126 perl.lzbwad
   3,025  4.742  0.065  0.046 perl.mrh
   3,027  4.739  0.028  0.023 perl.lzw
   3,028  4.737  0.075  0.040 perl.lzbwd
   3,030  4.734  0.069  0.050 perl.mrlz
   3,072  4.669  0.063  0.037 perl.lzbwh
   3,146  4.559  0.075  0.042 perl.mbwr
   3,176  4.516  0.062  0.040 perl.lzbwa
   3,186  4.502  0.057  0.036 perl.lzbw
   3,214  4.463  0.036  0.031 perl.lzih
   3,230  4.441  0.022  0.029 perl.rlh
   3,321  4.319  0.053  0.042 perl.lza
   3,335  4.301  0.047  0.035 perl.lzh
   3,504  4.094  0.032  0.037 perl.rlac
   4,052  3.540  0.030  0.034 perl.hfm
   4,193  3.421  0.038  0.020 perl.lz77
  14,344  1.000  0.000  0.000 perl

Top 20 fastest compression methods: rlh, lzw, hfm, rlac, lzih, lzhd, lz77, lzac, lzaz, lzh, mra, lza, bwac, bwlzhd, bwaz, lzss, lzbw, bww, lzbwa, lzbwh
Top 20 fastest decompression methods: lz77, lzw, bww, rlh, lzhd, lzih, hfm, lzh, lzac, lzbw, lzbwh, bwac, rlac, lzbwa, lzbwd, bwt2, lzaz, lza, mbwr, mra

Top 20 slowest compression methods: bwlzad, bwlzad2, lzsad, bwrlz2, bwrlz, bwad, bwrla, bwrm, bwrl, lzbwad, bwrl2, bwlz2, bwlza, lzsbw, bwlza2, lzsa, bwlz, bwt2, bwt, mbwr
Top 20 slowest decompression methods: bwlzad, bwlzad2, lzsad, bwad, lzbwad, bwrlz2, bwrlz, lzsa, bwlza2, bwlza, bwlz2, bwlz, bwlzss, bwrla, bwaz, bwt, mrlz, bwrl, lzsbw, bwrl2
