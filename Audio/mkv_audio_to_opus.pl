#!/usr/bin/perl

# Convert MKV audio files to OPUS files, in a given directory (and its subdirectories).

# Requires `ffmpeg` and `exiftool`.

use 5.036;
use File::Find            qw(find);
use File::Temp            qw(mktemp);
use File::Copy            qw(move);
use File::Basename        qw(dirname basename);
use File::Spec::Functions qw(catfile curdir);

sub is_mkv_audio ($file) {
    my $res = `exiftool \Q$file\E`;
    $? == 0       or return;
    defined($res) or return;
    $res =~ m{^MIME\s+Type\s*:\s*audio/x-matroska}mi;
}

sub convert ($file) {
    my $tmpfile = mktemp("tempXXXXXXXXXXX") . '.opus';
    say ":: Temporary file: $tmpfile";

    system("ffmpeg", '-loglevel', 'warning', "-i", $file, $tmpfile);
    $? == 0 or return;

    my $dir      = dirname($file);
    my $basename = basename($file) =~ s{\.\w+\z}{.opus}r;
    my $new_file = catfile($dir, $basename);

    unlink($file) or return;
    say ":: Moving: $tmpfile -> $new_file";
    move($tmpfile, $new_file);
}

my @dirs = @ARGV;
@dirs = curdir() if not @ARGV;

find(
    {
     wanted => sub {
         if (-f $_ and is_mkv_audio($_)) {
             say ":: Converting: $_";
             convert($_);
         }
     },
    },
    @dirs
);
