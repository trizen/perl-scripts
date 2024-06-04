#!/usr/bin/perl

# Author: Trizen
# Date: 04 June 2024
# https://github.com/trizen

# Recompress gzip, zip, bzip2, zstd, xz, lzma, lzip, lzf or lzop to another format.

use 5.036;
use Getopt::Long                  qw(GetOptions);
use IO::Uncompress::AnyUncompress qw();

use constant {
              CHUNK_SIZE => 1 << 16,    # how many bytes to read per chunk
             };

my %compressors = (
    'gzip' => {
               class  => 'IO::Compress::Gzip',
               format => 'gz',
              },

    'bzip2' => {
                class  => 'IO::Compress::Bzip2',
                format => 'bz2',
               },

    'lzf' => {
              class  => 'IO::Compress::Lzf',
              format => 'lzf',
             },

    #~ 'lzip' => {  # buggy
    #~ class => 'IO::Compress::Lzip',
    #~ format => 'lz',
    #~ },

    #~ 'lzma' => {  # buggy
    #~ class => 'IO::Compress::Lzma',
    #~ format => 'lzma',
    #~ },

    'lzop' => {
               class  => 'IO::Compress::Lzop',
               format => 'lzop',
              },

    'xz' => {
             class  => 'IO::Compress::Xz',
             format => 'xz',
            },

    'zstd' => {
               class  => 'IO::Compress::Zstd',
               format => 'zst',
              },

    'zip' => {
              class  => 'IO::Compress::Zip',
              format => 'zip',
             },
);

my $compression_method = 'none';
my $keep_original      = 0;
my $overwrite          = 0;

sub usage ($exit_code) {

    local $" = ", ";

    print <<"EOT";
usage: $0 [options] [.gz files]

options:

    -c --compress=s     : select compression method
                          valid: @{[sort keys %compressors]}
    -k --keep!          : keep the original files (default: $keep_original)
    -f --force!         : overwrite existing files (default: $overwrite)
    -h --help           : print this message and exit

example:

    # Convert a bunch of Gzip files to XZ format
    $0 -c=xz *.gz
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

my $compression = $compressors{$compression_method} // do {
    warn "[!] Please select a valid compression method with `-c` option!\n";
    warn "[!] Valid values: ", join(', ', sort keys(%compressors)), "\n";
    exit(1);
};

foreach my $file (@ARGV) {

    if (not -f $file) {
        warn ":: Not a file: <<$file>>. Skipping...\n";
        next;
    }

    say "\n:: Processing: $file";

    my $new_file   = $file;
    my $new_format = $compression->{format};

    if (   $new_file =~ s{\.t\w+\z}{.t$new_format}i
        or $new_file =~ s{\.\w+\z}{.$new_format}i) {
        ## ok
    }
    else {
        $new_file .= ".$new_format";
    }

    if (-e $new_file) {
        if (not $overwrite) {
            say "-> File <<$new_file>> already exists. Skipping...";
            next;
        }
    }

    my $in_fh = IO::Uncompress::AnyUncompress->new($file) or do {
        warn "[!] Probably not a valid compressed file ($IO::Uncompress::AnyUncompress::AnyUncompressError). Skipping...\n";
        next;
    };

    require(($compression->{class} =~ s{::}{/}rg) . '.pm');

    my $out_fh = $compression->{class}->new($new_file)
      or die "[!] Failed to initialize the compressor class: $compression->{class}: $!\n";

    while (read($in_fh, (my $chunk), CHUNK_SIZE)) {
        $out_fh->write($chunk);
    }

    ($in_fh->eof and $in_fh->close and $out_fh->close) || do {
        warn "[!] Something went wrong! Skipping...\n";
        unlink($new_file);
        next;
    };

    my $old_size = -s $file;
    my $new_size = -s $new_file;

    say "-> $old_size vs. $new_size";

    if (not $keep_original) {
        say "-> Removing the original file: $file";
        unlink($file) or warn "[!] Can't remove file <<$file>>: $!\n";
    }
}
