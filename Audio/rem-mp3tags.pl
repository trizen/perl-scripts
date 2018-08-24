#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 15 August 2011
# https://github.com/trizen

# Removes tags of MP3 audio files from a directory and its subdirectories.

use 5.010;
use strict;
use warnings;

use MP3::Tag;
use File::Find qw(find);

my (@dirs) = grep { -d $_ } @ARGV;

die "Usage: $0 <dir>\n" unless @dirs;

my $quiet = scalar grep { /^--?(?:q|quiet)\z/ } @ARGV;

my @mp3_files;

find(\&wanted_files, @dirs);

sub wanted_files {
    my $file = $File::Find::name;
    push @mp3_files, $file if $file =~ /\.mp3\z/i;
}

foreach my $filename (@mp3_files) {

    my $mp3 = 'MP3::Tag'->new($filename);

    $mp3->get_tags;

    if (exists $$mp3{'ID3v1'}) {
        say "[ID3v1] Removing tag: $filename" unless $quiet;
        $$mp3{'ID3v1'}->remove_tag;
        $mp3->close;
    }

    if (exists $$mp3{'ID3v2'}) {
        say "[ID3v2] Removing tag: $filename" unless $quiet;
        $$mp3{'ID3v2'}->remove_tag;
        $mp3->close;
    }
}
