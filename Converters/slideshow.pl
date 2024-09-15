#!/usr/bin/perl

# Create a video slideshow from a collection of images, given a glob pattern.

# Usage:
#   perl slideshow.pl 'glob_pattern*.jpg' 'output.mp4'

use 5.036;

system('ffmpeg',
       qw(-framerate 1/2),
       qw(-pattern_type glob -i),
       $ARGV[0], '-vf',
       "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1929:1080:(ow-iw)/2:(oh-ih)/2",
       qw(-tune stillimage -c:v libx264 -s 1920x1080 -crf 18 -r 24),
       $ARGV[1]);
