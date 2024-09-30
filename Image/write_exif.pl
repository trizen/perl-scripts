#!/usr/bin/perl

# Author: Trizen
# Date: 30 September 2024
# https://github.com/trizen

# Add the EXIF "DateTimeOriginal" to images, based on the filename of the image, along with custom GPS tags.

use 5.036;
use Image::ExifTool qw();

my $latitude  = 45.84692326942804;
my $longitude = 22.796479967835673;

@ARGV or die "usage: $0 [images]\n";

foreach my $file (@ARGV) {

    say "Processing: $file";

    my $exifTool = Image::ExifTool->new;
    $exifTool->ExtractInfo($file);

    if ($file =~ m{.*IMG_((?:20|19)[0-9]{2})([0-9]{2})([0-9]{2})_([0-9]{2})([0-9]{2})([0-9]{2})}) {
        my ($year, $month, $day, $hour, $min, $sec) = ($1, $2, $3, $4, $5, $6);

        my $date = "$year:$month:$day $hour:$min:$sec";
        say "Setting image creation time to: $date";

        # Set the file modification date
        $exifTool->SetNewValue(FileModifyDate => $date, Protected => 1);

        # Set the EXIF creation date (unless it already exists)
        if (not defined $exifTool->GetValue("DateTimeOriginal")) {
            $exifTool->SetNewValue(DateTimeOriginal => $date);
        }

        # Set GPSLatitude and GPSLongitude tags
        $exifTool->SetNewValue('GPSLatitude',     $latitude);
        $exifTool->SetNewValue('GPSLatitudeRef',  $latitude >= 0 ? 'N' : 'S');
        $exifTool->SetNewValue('GPSLongitude',    $longitude);
        $exifTool->SetNewValue('GPSLongitudeRef', $longitude >= 0 ? 'E' : 'W');

        $exifTool->WriteInfo($file);
    }
    else {
        warn "Unable to determine the image creation date. Skipping...\n";
    }
}
