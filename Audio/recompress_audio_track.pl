#!/usr/bin/perl

# Author: Trizen
# Date: 06 September 2023
# https://github.com/trizen

# Make video files smaller, by recompressing the audio track to the OPUS format (40kbps), using ffmpeg.

# Requires the following tools:
#   ffmpeg
#   exiftool

# Usage:
#   perl recompress_audio_track.pl [files | directories]

use 5.036;
use File::Temp            qw(mktemp);
use File::Find            qw(find);
use File::Copy            qw(move);
use File::Basename        qw(dirname basename);
use File::Spec::Functions qw(catfile);

sub is_video_file ($file) {
    my $res = `exiftool \Q$file\E`;
    $? == 0       or return;
    defined($res) or return;
    $res =~ m{^MIME\s+Type\s*:\s*video/}mi;
}

sub recompress_audio_track ($video_file) {

    say ":: Extracting audio track...";
    my $orig_audio_file = mktemp("tempXXXXXXXXXXX") . '.mkv';
    system("ffmpeg", "-loglevel", "warning", "-i", $video_file, "-vn", "-acodec", "copy", $orig_audio_file);

    $? == 0 or do {
        unlink($orig_audio_file);
        return;
    };

    say ":: Recompressing audio track...";
    my $new_audio_file = mktemp("tempXXXXXXXXXXX") . '.opus';
    system("ffmpeg", "-loglevel", "warning", "-i", $orig_audio_file, "-vn", "-sn", "-dn", "-c:a", "libopus", "-b:a", "40K", $new_audio_file);

    $? == 0 or do {
        unlink($new_audio_file);
        return;
    };

    # When the original file is smaller, keep the original file
    if ((-s $orig_audio_file) <= (-s $new_audio_file)) {
        say ":: The original audio track is smaller... Will keep it...";
        unlink($new_audio_file);
        $new_audio_file = $orig_audio_file;
    }

    say ":: Merging the recompressed audio track with the video...";
    my $new_video_file = mktemp("tempXXXXXXXXXXX") . '.mkv';
    system("ffmpeg", "-loglevel", "warning", "-i", $video_file, "-i", $new_audio_file,
           "-map_metadata", "0", "-map", "0:v", "-map", "1:a", "-map", "0:s?", "-c", "copy", $new_video_file);

    $? == 0 or do {
        unlink($new_audio_file);
        unlink($new_video_file);
        return;
    };

    my $dir              = dirname($video_file);
    my $basename         = basename($video_file) =~ s{\.\w+\z}{.mkv}r;
    my $final_video_file = catfile($dir, $basename);

    if ($final_video_file !~ /\.mkv\z/) {
        $final_video_file .= '.mkv';
    }

    my $original_size = -s $orig_audio_file;
    my $new_size      = -s $new_audio_file;

    printf(":: Saved: %.2f MB (%.2f%%)\n", ($original_size - $new_size) / 1024**2, ($original_size - $new_size) / $original_size * 100);

    unlink($video_file);
    unlink($new_audio_file);
    unlink($orig_audio_file);

    move($new_video_file, $final_video_file);
}

my @dirs = @ARGV;

if (not @dirs) {
    die "usage: $0 [files | directories]\n";
}

find(
    {
     wanted => sub {
         if (-f $_ and is_video_file($_)) {
             say "\n:: Processing: $_";
             recompress_audio_track($_);
         }
     },
    },
    @dirs
);
