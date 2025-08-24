#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 24 August 2025
# https://github.com/trizen

# Split a video file into multiple parts of length `n` seconds, or into `n` equal parts.

# Requires: ffmpeg

use 5.036;
use Getopt::Long qw(GetOptions);

my $parts           = undef;
my $duration        = undef;
my $output_template = "PART_%04d.mp4";

sub usage($exit_code = 0) {

    print <<"EOT";
usage: $0 [options] [video.mp4]

options:

    --parts=i     : split into `i` equal parts
    --duration=i  : split into segments of length `i` seconds
    --template=s  : output filename template (default: $output_template)
    --help        : display this message and exit

example:

    # Split video.mp4 into 3 equal parts
    perl $0 --parts=3 video.mp4

    # Split video.mp4 into equal parts of 10 seconds length
    perl $0 --duration=10 video.mp4
EOT

    exit($exit_code);
}

GetOptions(
           "duration=i" => \$duration,
           "parts=i"    => \$parts,
           "template=s" => \$output_template,
           "h|help"     => sub { usage() },
          )
  or die("Error in command line arguments\n");

if (!defined($parts) and !defined($duration)) {
    usage(1);
}

my $input_video = shift(@ARGV) // usage(2);

if (not -f $input_video) {
    die "Not a file <<$input_video>>: $!";
}

if (defined($parts)) {
    $duration = `ffprobe -v error -show_entries format=duration -of csv=p=0 \Q$input_video\E`;
    chomp($duration);
    $duration /= $parts;
}

system(qw(ffmpeg -loglevel fatal -i), $input_video,                                qw(-acodec copy -f segment -segment_time),
       $duration,                     qw(-vcodec copy -reset_timestamps 1 -map 0), $output_template);

if ($? == 0) {
    say ":: Done!";
}
else {
    die "Something went wrong! ffmpeg exit code: $?";
}
