#!/usr/bin/perl

# Rough performance comparison of some compression modules on a given file given as an argument.

use 5.010;
use strict;
use warnings;

use Time::HiRes qw(gettimeofday tv_interval);

my $data_str = do {
    open(my $fh, '<:raw', $ARGV[0])
      or die "Can't open file <<$ARGV[0]>> for reading: $!";
    local $/;
    <$fh>;
};

say "Raw : ", length($data_str);
say '';

eval {
    my $t0 = [gettimeofday];
    require IO::Compress::Gzip;
    IO::Compress::Gzip::gzip(\$data_str, \my $data_gzip);

    say "Gzip: ", length($data_gzip);
    say "Time: ", tv_interval($t0, [gettimeofday]);
    say '';
};

eval {
    my $t0 = [gettimeofday];
    require IO::Compress::Bzip2;
    IO::Compress::Bzip2::bzip2(\$data_str, \my $data_bzip2);

    say "Bzip: ", length($data_bzip2);
    say "Time: ", tv_interval($t0, [gettimeofday]);
    say '';
};

eval {
    my $t0 = [gettimeofday];
    require IO::Compress::RawDeflate;
    IO::Compress::RawDeflate::rawdeflate(\$data_str, \my $data_raw_deflate);

    say "RDef: ", length($data_raw_deflate);
    say "Time: ", tv_interval($t0, [gettimeofday]);
    say '';
};

eval {
    my $t0 = [gettimeofday];
    require IO::Compress::Deflate;
    IO::Compress::Deflate::deflate(\$data_str, \my $data_deflate);

    say "Defl: ", length($data_deflate);
    say "Time: ", tv_interval($t0, [gettimeofday]);
    say '';
};

eval {
    my $t0 = [gettimeofday];
    require IO::Compress::Zip;
    IO::Compress::Zip::zip(\$data_str, \my $data_zip);

    say "Zip : ", length($data_zip);
    say "Time: ", tv_interval($t0, [gettimeofday]);
    say '';
};

eval {
    my $t0 = [gettimeofday];
    require IO::Compress::Zstd;
    IO::Compress::Zstd::zstd(\$data_str, \my $data_zstd);

    say "Zstd: ", length($data_zstd);
    say "Time: ", tv_interval($t0, [gettimeofday]);
    say '';
};

0 && eval {
    my $t0 = [gettimeofday];
    require IO::Compress::Brotli;
    my $data_bro = IO::Compress::Brotli::bro($data_str);

    say "Brot: ", length($data_bro);
    say "Time: ", tv_interval($t0, [gettimeofday]);
    say '';
};
