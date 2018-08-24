#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 15 August 2011
# https://github.com/trizen

# Adds auto tags to MP3 audio files from a directory and its subdirectories.

use 5.010;
use strict;
use warnings;

use MP3::Tag;
use File::Find qw(find);

my @dirs = grep { -d $_ } @ARGV;

die "Usage: $0 <dir>\n" unless @dirs;

my @mp3_files;

find(\&wanted_files, @dirs);

sub wanted_files {
    my $file = $File::Find::name;
    push @mp3_files, $file if $file =~ /\.mp3\z/i;
}

foreach my $filename (@mp3_files) {

    say "Processing: $filename";

    my $mp3 = 'MP3::Tag'->new($filename);

    $mp3->config(write_v24 => 1);
    $mp3->autoinfo;
    $mp3->update_tags;
}
