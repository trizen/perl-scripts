#!/usr/bin/perl

# Author: Trizen
# Date: 17 April 2023
# https://github.com/trizen

# Find files from a given directory (and its subdirectories) that have a specific mimetype.

use 5.036;
use File::Find  qw(find);
use Getopt::Std qw(getopts);

sub usage ($exit_code = 0) {
    print <<"EOT";
usage: $0 [options] [files | dirs]

options:

    -t TYPE  : display files with this mimetype (regex)
    -n       : display non-matching files
    -f       : display only files
    -e       : use `exiftool` to determine the MIME types (slow)
    -h       : display this message and exit

examples:

    perl $0 -t video ~/Music              # find video files
    perl $0 -fn -t audio ~/Music          # find non-audio files
    perl $0 -fn -t 'audio|video' ~/Music  # find non audio/video files

EOT
    exit($exit_code);
}

getopts('efhnt:', \my %opts);
$opts{t} || usage(1);
$opts{h} && usage(0);

my $type_re = qr/$opts{t}/;

sub determine_mime_type ($file) {

    if (-d $file) {
        return 'inode/directory';
    }

    if ($opts{e}) {
        my $res = `exiftool \Q$file\E`;
        $? == 0       or return;
        defined($res) or return;
        if ($res =~ m{^MIME\s+Type\s*:\s*(\S+)}mi) {
            return $1;
        }
        return;
    }

    require File::MimeInfo::Magic;
    File::MimeInfo::Magic::mimetype($file);
}

find(
    {
     wanted => sub {

         my $mimetype = determine_mime_type($_) // return;
         my $ok       = ($mimetype =~ $type_re);

         $ok = !$ok if $opts{n};
         $ok = 0    if ($opts{f} and not -f $_);

         if ($ok) {
             say $File::Find::name;
         }
     },
     no_chdir => 1,
    },
    @ARGV
);
