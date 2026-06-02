#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 21 August 2025
# https://github.com/trizen

# Concatenate multiple MP4 video files, given as arguments, into one single file called "CONCATENATED.mp4".

# Requires: ffmpeg

use 5.036;
use File::Temp            qw(tempfile tempdir);
use File::Path            qw(make_path);
use File::Spec::Functions qw(catfile curdir);
use Image::ExifTool       qw(ImageInfo);
use Getopt::Long          qw(GetOptions);

my $portrait        = 0;
my $landscape       = 0;
my $output_filename = "CONCATENATED.mp4";
my $output_dir      = tempdir(CLEANUP => 1, DIR => curdir());

GetOptions(
           'p|portrait!'  => \$portrait,
           'l|landscape!' => \$landscape,
           'o|output=s'   => \$output_filename,
           'h|help'       => sub { usage(0) },
          )
  or die("Error in command line arguments\n");

sub usage ($exit_code = 0) {
    print <<"HELP";
usage: $0 [options] [MP4 files]

options:
    -o --out=s      : output filename (default: $output_filename)
    -p --portrait   : video portrait mode
    -l --landscape  : video landscape mode
    -h --help       : print this message and exit

example:

    $0 --landscape *.mp4
HELP
    exit($exit_code);
}

sub new_tempfile {
    my ($fh, $filename) = tempfile("tmpfileXXXXX", SUFFIX => '.txt', UNLINK => 1);
    return ($fh, $filename);
}

sub make_video_filename($i) {
    catfile($output_dir, sprintf('output_%05d.mp4', $i));
}

sub make_ffmpeg_filename_entry($file) {
    sprintf("file '%s'\n", $file);
}

sub ffmpeg_concat_files ($filename, $output_filename) {
    system('ffmpeg', '-loglevel', 'fatal', '-f', 'concat', '-i', $filename, '-c:v', 'copy', '-c:a', 'aac', '-y', $output_filename);
    $? == 0 or die "Stopped with exit code = $?";
}

if (!@ARGV) {
    warn "\nERROR: No input filenames given!\n\n";
    usage(2);
}

if (!$portrait and !$landscape) {
    warn "\nERROR: Specify a video mode with `--portrait` or `--landscape` options!\n\n";
    usage(1);
}

my $mp4_version = undef;

my $i = 1;
my ($fh, $filename) = new_tempfile();

foreach my $file (@ARGV) {

    my $info     = ImageInfo($file);
    my $version  = $info->{'MajorBrand'} // die "Not an MP4 file: $file\n";
    my $rotation = $info->{'Rotation'};

    if ($landscape) {
        $rotation eq '0' or do {
            warn "Skipping file: <<$file>> (has rotation $rotation)\n";
            next;
        };
    }
    elsif ($portrait) {
        $rotation eq '90' or $rotation eq '270' or do {
            warn "Skipping file: <<$file>> (has rotation $rotation)\n";
            next;
        };
    }

    $mp4_version //= $version;

    if ($version ne $mp4_version) {
        $mp4_version = undef;
        ffmpeg_concat_files($filename, make_video_filename($i));
        ($fh, $filename) = new_tempfile();
        ++$i;
    }

    print $fh make_ffmpeg_filename_entry($file);
}

ffmpeg_concat_files($filename, make_video_filename($i));

($fh, $filename) = new_tempfile();

foreach my $k (1 .. $i) {
    my $file = make_video_filename($k);
    print $fh make_ffmpeg_filename_entry($file);
}

close $fh;
ffmpeg_concat_files($filename, $output_filename);
