#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 15 August 2011
# Edit: 11 August 2019
# https://github.com/trizen

# Adds auto-tags to MP3 audio files in a given directory and its subdirectories.

use 5.010;
use strict;
use warnings;

use MP3::Tag;
use File::Find qw(find);
use File::Copy qw(copy);
use File::Temp qw(tempfile);
use File::Basename qw(basename);
use Encode qw(encode_utf8 decode_utf8);

my @files = grep { -e $_ } @ARGV;

die "Usage: $0 <dirs|files>\n" unless @files;

my @mp3_files;

find(\&wanted_files, @files);

sub wanted_files {
    my $file = $File::Find::name;
    push @mp3_files, $file if $file =~ /\.mp3\z/i;
}

foreach my $filename (@mp3_files) {

    say "Processing: $filename";

    my (undef, $tmpfile) = tempfile(basename($filename) . ' - XXXXXX', TMPDIR => 1);

    unlink($tmpfile);
    $tmpfile =~ s/ - .{6}\z//;
    copy($filename, $tmpfile);

    my $mp3 = 'MP3::Tag'->new($tmpfile);

    my @fields = qw(artist album title comment);

    $mp3->config(write_v24 => 1);
    $mp3->autoinfo;
    $mp3->update_tags({map { $_ => decode_utf8($mp3->$_) } @fields});
    $mp3->close;

    unlink($filename);
    copy($tmpfile, $filename);
    unlink($tmpfile);
}
