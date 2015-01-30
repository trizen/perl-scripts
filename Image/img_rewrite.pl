#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 30 January 2015
# Website: https://github.com/trizen

# Rewrite a set of images specified as arguments.

use 5.010;
use strict;
use warnings;

use Image::Magick;

foreach my $file (@ARGV) {
    say "** Processing file `$file'...";
    my $img = Image::Magick->new;
    $img->Read($file) && do {
        warn "[!] Can't load image `$file' ($!). Skipping file...\n";
        next;
    };
    unlink($file);
    $img->Write($file);
}
