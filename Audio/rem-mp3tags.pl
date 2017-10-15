#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 15 August 2011
# https://github.com/trizen

# Removes tags of MP3 audio files from a directory and its subdirectories.

use strict;
use warnings;
use File::Find ('find');

my (@dirs) = grep({ -d $_ } @ARGV);

die "Usage: $0 <dir>\n" unless @dirs;

my $quiet = do {
    grep { /^-+(?:q|quiet)$/ } @ARGV;
  }
  ? 1 : 0;

require MP3::Tag;

my @mp3_files;

my $is_mp3 = qr/\.mp3$/i;

find(\&wanted_files, @dirs);

sub wanted_files {
    my $file = $File::Find::name;
    push @mp3_files, $file if $file =~ /$is_mp3/;
}

foreach my $filename (@mp3_files) {

    my $mp3 = 'MP3::Tag'->new($filename);

    $mp3->get_tags;

    if (exists $$mp3{'ID3v1'}) {
        print "[ID3v1] Removing tag: $filename\n" unless $quiet;
        $$mp3{'ID3v1'}->remove_tag;
        $mp3->close;
    }

    if (exists $$mp3{'ID3v2'}) {
        print "[ID3v2] Removing tag: $filename\n" unless $quiet;
        $$mp3{'ID3v2'}->remove_tag;
        $mp3->close;
    }
}
