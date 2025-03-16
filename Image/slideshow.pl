#!/usr/bin/perl

# Create a video slideshow from a collection of images, given a glob pattern.

# Usage:
#   perl slideshow.pl 'glob_pattern*.jpg' 'output.mp4'

use 5.036;
use Getopt::Long qw(GetOptions);

my $width  = 1920;
my $height = 1080;
my $delay  = 2;

GetOptions(
           "width=i"  => \$width,
           "height=i" => \$height,
           "delay=i"  => \$delay
          )
  or die("Error in command line arguments\n");

@ARGV == 2 or die <<"USAGE";
usage: $0 [options] [glob pattern] [output.mp4]

options:

    --width=i   : width of the video (default: $width)
    --height=i  : height of the video (default: $height)
    --delay=i   : delay in seconds between pictures (default: $delay)
USAGE

system('ffmpeg', qw(-framerate),
       join('/', 1, $delay),
       qw(-pattern_type glob -i),
       $ARGV[0], '-vf',
       "scale=${width}:${height}:force_original_aspect_ratio=decrease,pad=${width}:${height}:(ow-iw)/2:(oh-ih)/2",
       qw(-c:v libx264 -s),
       join('x', $width, $height),
       qw(-crf 18 -tune stillimage -r 24),
       $ARGV[1]);
