#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 26 August 2015
# Edit: 05 June 2021
# https://github.com/trizen

# Find images that look similar, given a main image.

# Blog post:
#   https://trizenx.blogspot.com/2015/08/finding-similar-images.html

use 5.020;
use strict;
use warnings;

use experimental qw(bitwise signatures);

use Image::Magick qw();
use List::Util qw(sum);
use File::Find qw(find);
use Getopt::Long qw(GetOptions);

my $width      = 32;
my $height     = 32;
my $percentage = 60;

my $fuzzy_matching = 0;
my $copy_to        = undef;

my $resize_to = $width . 'x' . $height;

my @img_formats = qw(
  jpeg
  jpg
  png
);

sub help ($code = 0) {
    local $" = ",";
    print <<"EOT";
usage: $0 [options] [main image] [dir]

options:
    -p  --percentage=i  : minimum similarity percentage (default: $percentage)
    -r  --resize-to=s   : resize images to this resolution (default: $resize_to)
    -f  --fuzzy!        : use fuzzy matching (default: $fuzzy_matching)
    -c  --copy-to=s     : copy similar images into this directory

example:
    perl $0 -p 75 -r '8x8' main.jpg ~/Pictures
EOT

    exit($code);
}

GetOptions(
           'p|percentage=i' => \$percentage,
           'r|resize-to=s'  => \$resize_to,
           'f|fuzzy!'       => \$fuzzy_matching,
           'c|copy-to=s'    => \$copy_to,
           'h|help'         => sub { help(0) },
          )
  or die("Error in command line arguments");

($width, $height) = split(/\h*x\h*/i, $resize_to);

my $size = $width * $height;

my $img_formats_re = do {
    local $" = '|';
    qr/\.(@img_formats)\z/i;
};

sub avg ($x, $y, $z) {
    ($x + $y + $z) / 3;
}

sub alike_percentage ($x, $y) {
    ((($x ^. $y) =~ tr/\0//) / $size)**2 * 100;
}

sub fingerprint ($image) {

    my $img = Image::Magick->new;
    $img->Read(filename => $image) && return;
    $img->AdaptiveResize(width => $width, height => $height) && return;

    my @pixels = $img->GetPixels(
                                 map       => 'RGB',
                                 x         => 0,
                                 y         => 0,
                                 width     => $width,
                                 height    => $height,
                                 normalize => 1,
                                );

    my $i = 0;
    my @averages;

    while (@pixels) {

        my $x = int($i % $width);
        my $y = int($i / $width);

        push @averages, avg(splice(@pixels, 0, 3));

        ++$i;
    }

    my $avg = sum(@averages) / @averages;
    join('', map { $_ < $avg ? 1 : 0 } @averages);
}

sub find_similar_images ($callback, $main_image, @paths) {

    my @files;

    find {
        no_chdir => 1,
        wanted   => sub {
            (/$img_formats_re/o && -f) || return;

            push @files,
              {
                fingerprint => fingerprint($_) // return,
                filename    => $_,
              };
        }
    } => @paths;

    my $main_fingerprint = fingerprint($main_image) // return;

    if ($fuzzy_matching) {

        my %seen    = ($main_fingerprint => 1);
        my @similar = ($main_fingerprint);

        my @similar_files;

        while (@similar) {

            my $similar_fingerprint = shift(@similar);

            foreach my $file (@files) {

                my $p = alike_percentage($similar_fingerprint, $file->{fingerprint});

                if ($p >= $percentage and !$seen{$file->{fingerprint}}++) {
                    push @similar, $file->{fingerprint};
                    push @similar_files, {score => $p, filename => $file->{filename}};
                }
            }
        }

        foreach my $entry (sort { $b->{score} <=> $a->{score} } @similar_files) {
            $callback->($entry->{score}, $entry->{filename});
        }
    }
    else {
        foreach my $file (@files) {

            my $p = alike_percentage($main_fingerprint, $file->{fingerprint});

            if ($p >= $percentage) {
                $callback->($p, $file->{filename});
            }
        }
    }

    return 1;
}

my $main_file = shift(@ARGV) // help(1);

@ARGV || help(1);

if (defined($copy_to)) {

    require File::Copy;

    if (not -d $copy_to) {
        require File::Path;
        File::Path::make_path($copy_to)
          or die "Can't create path <<$copy_to>>: $!";
    }
}

find_similar_images(
    sub ($score, $file) {

        say sprintf("%.0f%%: %s", $score, $file);

        if ($copy_to) {
            File::Copy::cp($file, $copy_to);
        }
    },
    $main_file,
    @ARGV
                   );
