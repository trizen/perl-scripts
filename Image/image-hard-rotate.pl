#!/usr/bin/perl

# Author: Trizen
# Date: 10 August 2025
# https://github.com/trizen

# Hard-rotate images that contain the "Orientation" EXIF tag specified as "Rotate 90 CW" or "Rotate 270 CW".

use 5.036;
use Imager;
use Image::ExifTool qw(ImageInfo);

foreach my $file (@ARGV) {

    say ":: Processing: $file";

    my $info        = ImageInfo($file);
    my $orientation = $info->{Orientation};

    if (defined($orientation) and $orientation =~ /^Rotate (\d+) CW/) {

        my $angle = $1;
        say "-> Rotating image by $angle degrees clockwise...";

        my $img = Imager->new(file => $file) or die Imager->errstr();
        $img = $img->rotate(degrees => $angle);
        unlink($file);
        $img->write(file => $file) or die $img->errstr;
    }
}
