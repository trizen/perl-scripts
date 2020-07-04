#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 15 August 2011
# Edit: 11 August 2019
# https://github.com/trizen

# Removes tags of MP3 audio files in a given directory and its subdirectories.

use 5.010;
use strict;
use warnings;

use MP3::Tag;
use File::Find qw(find);
use File::Copy qw(copy);
use File::Temp qw(tempfile);
use File::Basename qw(basename);

my (@files) = grep { -e $_ } @ARGV;

die "Usage: $0 <dirs|files>\n" unless @files;

my $quiet = scalar grep { /^--?(?:q|quiet)\z/ } @ARGV;

my @mp3_files;

find(\&wanted_files, @files);

sub wanted_files {
    my $file = $File::Find::name;
    push @mp3_files, $file if $file =~ /\.mp3\z/i;
}

foreach my $filename (@mp3_files) {

    my (undef, $tmpfile) = tempfile(basename($filename) . ' - XXXXXX', TMPDIR => 1);

    unlink($tmpfile);
    $tmpfile =~ s/ - .{6}\z//;
    copy($filename, $tmpfile);

    my $mp3 = 'MP3::Tag'->new($tmpfile);

    $mp3->get_tags;

    my $had_tags = 0;

    if (exists $mp3->{'ID3v1'}) {
        say "[ID3v1] Removing tag: $filename" unless $quiet;
        $mp3->{'ID3v1'}->remove_tag;
        $had_tags = 1;
    }

    if (exists $mp3->{'ID3v2'}) {
        say "[ID3v2] Removing tag: $filename" unless $quiet;
        $mp3->{'ID3v2'}->remove_tag;
        $had_tags = 1;
    }

    $mp3->close;

    if ($had_tags) {
        unlink($filename);
        copy($tmpfile, $filename);
    }

    unlink($tmpfile);
}
