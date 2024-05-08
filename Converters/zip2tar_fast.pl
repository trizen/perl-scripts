#!/usr/bin/perl

# Author: Trizen
# Date: 10 April 2024
# https://github.com/trizen

# Convert a ZIP archive to a TAR archive (with optional compression).

# Using `zip2tarcat` from LittleUtils:
#   https://sourceforge.net/projects/littleutils/

# Converts and recompresses a ZIP file, without storing the entire archive in memory.

use 5.036;
use Getopt::Long qw(GetOptions);

use constant {
              CHUNK_SIZE => 1 << 16,    # how many bytes to read per chunk
             };

my $zip2tarcat_cmd = 'zip2tarcat';    # command to zip2tarcat

sub zip2tar ($zip_file, $out_fh) {

    open(my $fh, '-|:raw', $zip2tarcat_cmd, $zip_file)
      or die "Cannot pipe into <<$zip2tarcat_cmd>>: $!";

    while (read($fh, (my $chunk), CHUNK_SIZE)) {
        $out_fh->print($chunk);
    }

    $out_fh->close;
    close $fh;
}

my $compression_method = 'none';
my $keep_original      = 0;
my $overwrite          = 0;

sub usage ($exit_code) {
    print <<"EOT";
usage: $0 [options] [zip files]

options:

    -c --compress=s     : compression method (default: $compression_method)
                          valid: none, xz, gz, bz2, lzo, lzip, zstd
    -k --keep!          : keep the original ZIP files (default: $keep_original)
    -f --force!         : overwrite existing files (default: $overwrite)
    -h --help           : print this message and exit

example:

    # Convert a bunch of zip files to tar.xz
    perl $0 -c=xz *.zip
EOT

    exit($exit_code);
}

GetOptions(
           'c|compress=s' => \$compression_method,
           'k|keep!'      => \$keep_original,
           'f|force!'     => \$overwrite,
           'h|help'       => sub { usage(0) },
          )
  or usage(1);

@ARGV || usage(2);

my $tar_suffix        = '';
my $compression_class = undef;

if ($compression_method eq 'none') {
    require IO::Handle;
}
elsif ($compression_method =~ /^(?:gz|gzip)\z/) {
    require IO::Compress::Gzip;
    $tar_suffix .= '.gz';
    $compression_class = 'IO::Compress::Gzip';
}
elsif ($compression_method =~ /^(?:bz2|bzip2)\z/) {
    require IO::Compress::Bzip2;
    $tar_suffix .= '.bz2';
    $compression_class = 'IO::Compress::Bzip2';
}
elsif ($compression_method =~ /^(?:xz)\z/) {
    require IO::Compress::Xz;
    $tar_suffix        = '.xz';
    $compression_class = 'IO::Compress::Xz';
}
elsif ($compression_method =~ /^(?:lzo|lzop)\z/) {
    require IO::Compress::Lzop;
    $tar_suffix        = '.lzo';
    $compression_class = 'IO::Compress::Lzop';
}
elsif ($compression_method =~ /^(?:lz|lzip)\z/) {
    require IO::Compress::Lzip;
    $tar_suffix        = '.lz';
    $compression_class = 'IO::Compress::Lzip';
}
elsif ($compression_method =~ /^(?:zstandard|zstd?)\z/) {
    require IO::Compress::Zstd;
    $tar_suffix        = '.zst';
    $compression_class = 'IO::Compress::Zstd';
}
else {
    die "Unknown compression method: <<$compression_method>>\n";
}

foreach my $zip_file (@ARGV) {
    if (-f $zip_file) {

        say "\n:: Processing: $zip_file";
        my $tar_file = ($zip_file =~ s{\.zip\z}{}ri) . '.tar' . $tar_suffix;

        if (-e $tar_file) {
            if (not $overwrite) {
                say "-> Tar file <<$tar_file>> already exists. Skipping...";
                next;
            }
        }

        my $out_fh;
        if (defined($compression_class)) {
            $out_fh = $compression_class->new($tar_file)
              or do {
                warn "[!] Failed to initialize the compressor: $!. Skipping...\n";
                next;
              };
        }
        else {
            open $out_fh, '>:raw', $tar_file
              or do {
                warn "[!] Can't create tar file <<$tar_file>>: $!\n";
                next;
              };
        }

        zip2tar($zip_file, $out_fh) || do {
            warn "[!] Something went wrong! Skipping...\n";
            unlink($tar_file);
            next;
        };

        my $old_size = -s $zip_file;
        my $new_size = -s $tar_file;

        say "-> $old_size vs. $new_size";

        if (not $keep_original) {
            say "-> Removing the original ZIP file: $zip_file";
            unlink($zip_file) or warn "[!] Can't remove file <<$zip_file>>: $!\n";
        }
    }
    else {
        warn ":: Not a file: <<$zip_file>>. Skipping...\n";
    }
}
