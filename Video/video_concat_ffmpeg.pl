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

my $output_filename = "CONCATENATED.mp4";
my $output_dir      = tempdir(CLEANUP => 1, DIR => curdir());

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

my $mp4_version = undef;

my $i = 1;
my ($fh, $filename) = new_tempfile();

foreach my $file (@ARGV) {

    my $info    = ImageInfo($file);
    my $version = $info->{'MajorBrand'};

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
