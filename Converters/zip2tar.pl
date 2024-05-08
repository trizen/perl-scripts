#!/usr/bin/perl

# Author: Trizen
# Date: 10 April 2024
# https://github.com/trizen

# Convert a ZIP archive to a TAR archive (with optional compression).

# Limitation: the TAR file is created in-memory!

use 5.036;

use Archive::Tar;
use Archive::Tar::Constant;
use Archive::Zip qw(:ERROR_CODES :CONSTANTS);
use Getopt::Long qw(GetOptions);
use Encode       qw(encode_utf8);

sub zip2tar ($zip_file) {

    my $zip = Archive::Zip->new();

    unless ($zip->read($zip_file) == AZ_OK) {
        warn "Probably not a ZIP file: <<$zip_file>>. Skipping...\n";
        return undef;
    }

    my $tar = Archive::Tar->new;

    foreach my $member ($zip->members) {

        if (ref($member) eq 'Archive::Zip::DirectoryMember') {
            my $dirName = encode_utf8($member->fileName);
            $tar->add_data(
                           $dirName, '',
                           {
                            name  => $dirName,
                            size  => 0,
                            mode  => 0755,
                            mtime => $member->lastModTime,
                            type  => Archive::Tar::Constant::DIR,
                           }
                          );
        }
        elsif (ref($member) eq 'Archive::Zip::ZipFileMember') {

            if ($member->isEncrypted) {
                warn "[!] This archive is encrypted! Skipping...\n";
                return undef;
            }

            my $fileName = encode_utf8($member->fileName);
            my $size     = $member->uncompressedSize;

            $member->desiredCompressionMethod(COMPRESSION_STORED);
            $member->rewindData() == AZ_OK or die "error in rewindData()";

            my ($bufferRef, $status) = $member->readChunk($size);
            die "error $status" if ($status != AZ_OK and $status != AZ_STREAM_END);
            $member->endRead();

            my $read_size = length($$bufferRef);

            if ($size != $read_size) {
                die "Error reading member <<$fileName>>: ($size (expected) != $read_size (actual value))";
            }

            $tar->add_data(
                           $fileName,
                           $$bufferRef,
                           {
                            name  => $fileName,
                            size  => $size,
                            mode  => 0644,
                            mtime => $member->lastModTime,
                            type  => Archive::Tar::Constant::FILE,
                           }
                          );
        }
        else {
            die "Unknown member of type: ", ref($member);
        }
    }

    return $tar;
}

my $compression_method = 'none';
my $keep_original      = 0;
my $overwrite          = 0;

sub usage ($exit_code) {
    print <<"EOT";
usage: $0 [options] [zip files]

options:

    -c --compress=s     : compression method (default: $compression_method)
                          valid: none, gz, bz2, xz
    -k --keep!          : keep the original ZIP files (default: $keep_original)
    -f --force!         : overwrite existing files (default: $overwrite)
    -h --help           : print this message and exit

example:

    # Convert a bunch of zip files to tar.gz
    $0 -c=gz *.zip
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

my $tar_suffix       = '';
my $compression_flag = undef;

if ($compression_method eq 'none') {
    ## ok
}
elsif ($compression_method eq 'gz') {
    $tar_suffix .= '.gz';
    $compression_flag = Archive::Tar::Constant::COMPRESS_GZIP;
}
elsif ($compression_method eq 'bz2') {
    $tar_suffix .= '.bz2';
    $compression_flag = Archive::Tar::Constant::COMPRESS_BZIP;
    Archive::Tar->has_bzip2_support or die "Please install: IO::Compress::Bzip2\n";
}
elsif ($compression_method eq 'xz') {
    $tar_suffix       = '.xz';
    $compression_flag = Archive::Tar::Constant::COMPRESS_XZ;
    Archive::Tar->has_xz_support or die "Please install: IO::Compress::Xz\n";
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

        my $tar = zip2tar($zip_file) // next;

        say "-> Creating TAR file: $tar_file";
        $tar->write($tar_file, (defined($compression_flag) ? $compression_flag : ()));

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
