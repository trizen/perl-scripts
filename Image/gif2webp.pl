#!/usr/bin/perl

# Author: Trizen
# Date: 14 October 2023
# https://github.com/trizen

# Convert GIF animations to WEBP animations, using the `gif2webp` tool from "libwebp".

# The original GIF files are deleted.

use 5.036;
use File::Find   qw(find);
use Getopt::Long qw(GetOptions);

my $gif2webp_cmd = "gif2webp";    # `gif2webp` command
my $use_exiftool = 0;             # true to use `exiftool` instead of `File::MimeInfo::Magic`

`$gif2webp_cmd -h`
  or die "Error: `$gif2webp_cmd` tool from 'libwebp' is not installed!\n";

sub gif2webp ($file) {

    my $orig_file = $file;
    my $webp_file = $file;

    if ($webp_file =~ s/\.gif\z/.webp/i) {
        ## ok
    }
    else {
        $webp_file .= '.webp';
    }

    if (-e $webp_file) {
        warn "[!] File <<$webp_file>> already exists...\n";
        next;
    }

    system($gif2webp_cmd, '-lossy', $orig_file, '-o', $webp_file);

    if ($? == 0 and (-e $webp_file) and ($webp_file ne $orig_file)) {
        unlink($orig_file);
    }
    else {
        return;
    }

    return 1;
}

sub determine_mime_type ($file) {

    if ($file =~ /\.gif\z/i) {
        return "image/gif";
    }

    if ($use_exiftool) {
        my $res = `exiftool \Q$file\E`;
        $? == 0       or return;
        defined($res) or return;
        if ($res =~ m{^MIME\s+Type\s*:\s*(\S+)}mi) {
            return $1;
        }
        return;
    }

    require File::MimeInfo::Magic;
    File::MimeInfo::Magic::magic($file);
}

my %types = (
             'image/gif' => {
                             call => \&gif2webp,
                            },
            );

GetOptions('exiftool!' => \$use_exiftool,)
  or die "Error in command-line arguments!";

@ARGV or die <<"USAGE";
usage: perl $0 [options] [dirs | files]

options:

    --exiftool : use `exiftool` to determine the MIME type (default: $use_exiftool)

USAGE

find(
    {
     no_chdir => 1,
     wanted   => sub {

         (-f $_) || return;
         my $type = determine_mime_type($_) // return;

         if (exists $types{$type}) {
             $types{$type}{call}->($_);
         }
     }
    } => @ARGV
);

say ":: Done!";
