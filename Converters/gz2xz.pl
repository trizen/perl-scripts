#!/usr/bin/perl

# Author: Trizen
# Date: 08 May 2024
# https://github.com/trizen

# Convert Gzip files to XZ.

use 5.036;
use IO::Compress::Xz       qw();
use IO::Uncompress::Gunzip qw();
use Getopt::Long           qw(GetOptions);

use constant {
              CHUNK_SIZE => 1 << 16,    # how many bytes to read per chunk
             };

sub gz2xz ($in_fh, $out_fh) {

    while ($in_fh->read(my $chunk, CHUNK_SIZE)) {
        $out_fh->print($chunk);
    }

    $in_fh->eof   or return;
    $in_fh->close or return;
    $out_fh->close;
}

my $compression_method = 'none';
my $keep_original      = 0;
my $overwrite          = 0;

sub usage ($exit_code) {
    print <<"EOT";
usage: $0 [options] [.gz files]

options:

    -k --keep!          : keep the original Gzip files (default: $keep_original)
    -f --force!         : overwrite existing files (default: $overwrite)
    -h --help           : print this message and exit

example:

    # Convert a bunch of Gzip files to XZ format
    $0 *.gz
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

foreach my $gz_file (@ARGV) {
    if (-f $gz_file) {

        say "\n:: Processing: $gz_file";

        my $xz_file = $gz_file;

        if (   $xz_file =~ s{\.tgz\z}{.txz}i
            or $xz_file =~ s{\.gz\z}{.xz}i) {
            ## ok
        }
        else {
            $xz_file .= '.xz';
        }

        if (-e $xz_file) {
            if (not $overwrite) {
                say "-> Tar file <<$xz_file>> already exists. Skipping...";
                next;
            }
        }

        my $in_fh = IO::Uncompress::Gunzip->new($gz_file) or do {
            warn "[!] Probably not a Gzip file ($IO::Uncompress::Gunzip::GunzipError). Skipping...\n";
            next;
        };

        my $out_fh = IO::Compress::Xz->new($xz_file)
          or die "[!] Failed to initialize the compressor: $IO::Compress::Xz::XzError\n";

        gz2xz($in_fh, $out_fh) || do {
            warn "[!] Something went wrong! Skipping...\n";
            unlink($xz_file);
            next;
        };

        my $old_size = -s $gz_file;
        my $new_size = -s $xz_file;

        say "-> $old_size vs. $new_size";

        if (not $keep_original) {
            say "-> Removing the original Gzip file: $gz_file";
            unlink($gz_file) or warn "[!] Can't remove file <<$gz_file>>: $!\n";
        }
    }
    else {
        warn ":: Not a file: <<$gz_file>>. Skipping...\n";
    }
}
