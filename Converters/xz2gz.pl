#!/usr/bin/perl

# Author: Trizen
# Date: 04 June 2024
# https://github.com/trizen

# Convert XZ files to Gzip format.

use 5.036;
use IO::Compress::Gzip   qw();
use IO::Uncompress::UnXz qw();
use Getopt::Long         qw(GetOptions);

use constant {
              CHUNK_SIZE => 1 << 16,    # how many bytes to read per chunk
             };

sub xz2gz ($in_fh, $out_fh) {

    while ($in_fh->read(my $chunk, CHUNK_SIZE)) {
        $out_fh->print($chunk);
    }

    $in_fh->eof   or return;
    $in_fh->close or return;
    $out_fh->close;
}

my $keep_original = 0;
my $overwrite     = 0;

sub usage ($exit_code) {
    print <<"EOT";
usage: $0 [options] [.gz files]

options:

    -k --keep!          : keep the original XZ files (default: $keep_original)
    -f --force!         : overwrite existing files (default: $overwrite)
    -h --help           : print this message and exit

example:

    # Convert a bunch of XZ files to Gzip format
    $0 *.xz
EOT

    exit($exit_code);
}

GetOptions(
           'k|keep!'  => \$keep_original,
           'f|force!' => \$overwrite,
           'h|help'   => sub { usage(0) },
          )
  or usage(1);

@ARGV || usage(2);

foreach my $xz_file (@ARGV) {

    if (not -f $xz_file) {
        warn ":: Not a file: <<$xz_file>>. Skipping...\n";
        next;
    }

    say "\n:: Processing: $xz_file";

    my $gz_file = $xz_file;

    if (   $gz_file =~ s{\.txz\z}{.tgz}i
        or $gz_file =~ s{\.xz\z}{.gz}i) {
        ## ok
    }
    else {
        $gz_file .= '.gz';
    }

    if (-e $gz_file) {
        if (not $overwrite) {
            say "-> File <<$gz_file>> already exists. Skipping...";
            next;
        }
    }

    my $in_fh = IO::Uncompress::UnXz->new($xz_file) or do {
        warn "[!] Probably not an XZ file ($IO::Uncompress::UnXz::UnXzError). Skipping...\n";
        next;
    };

    my $out_fh = IO::Compress::Gzip->new($gz_file)
      or die "[!] Failed to initialize the compressor: $IO::Compress::Gzip::GzipError\n";

    xz2gz($in_fh, $out_fh) || do {
        warn "[!] Something went wrong! Skipping...\n";
        unlink($gz_file);
        next;
    };

    my $old_size = -s $xz_file;
    my $new_size = -s $gz_file;

    say "-> $old_size vs. $new_size";

    if (not $keep_original) {
        say "-> Removing the original XZ file: $xz_file";
        unlink($xz_file) or warn "[!] Can't remove file <<$xz_file>>: $!\n";
    }
}
