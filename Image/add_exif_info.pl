#!/usr/bin/perl

# Author: Trizen
# Date: 30 September 2024
# Edit: 24 September 2025
# https://github.com/trizen

# Add the EXIF "DateTimeOriginal" to images, based on the filename of the image, with support for GPS tags.

use 5.036;
use Image::ExifTool qw();
use File::Find      qw(find);
use Getopt::Long    qw(GetOptions);
use Time::Piece     qw();

my $latitude  = 45.84692326942804;
my $longitude = 22.796479967835673;

my $coordinates = undef;
my $set_gps     = 0;
my $utc_offset  = 0;

my $img_formats = '';

my @img_formats = qw(
  jpeg
  jpg
);

sub usage($exit_code = 0) {

    print <<"EOT";
usage: $0 [options] [images]

options:
    --gps!              : set the GPS coordinates
    --latitude=float    : value for GPSLatitude
    --longitude=float   : value for GPSLongitude
    --coordinates=str   : GPS coordinates as "latitude,longitude"
    --UTC-offset=i      : offset date by this many hours (default: $utc_offset)
    -f  --formats=s,s   : specify more image formats (default: @img_formats)
    --help              : print this message and exit
EOT

    exit $exit_code;
}

GetOptions(
           "gps!"          => \$set_gps,
           "f|formats=s"   => \$img_formats,
           "utc-offset=i"  => \$utc_offset,
           "latitude=f"    => \$latitude,
           "longitude=f"   => \$longitude,
           "coordinates=s" => \$coordinates,
           'help'          => sub { usage(0) }
          )
  or die("Error in command line arguments\n");

if (defined($coordinates)) {
    ($latitude, $longitude) = split(/\s*,\s*/, $coordinates);
}

sub process_image ($file) {

    my $exifTool = Image::ExifTool->new;

    $exifTool->ExtractInfo($file);

    if ($file =~ m{.*(?:/|\D_|\b)((?:20|19)[0-9]{2})([0-9]{2})([0-9]{2})_([0-9]{2})([0-9]{2})([0-9]{2})}) {
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
        if ($set_gps) {
            $exifTool->SetNewValue('GPSLatitude',     $latitude);
            $exifTool->SetNewValue('GPSLatitudeRef',  $latitude >= 0 ? 'N' : 'S');
            $exifTool->SetNewValue('GPSLongitude',    $longitude);
            $exifTool->SetNewValue('GPSLongitudeRef', $longitude >= 0 ? 'E' : 'W');
        }

        my $time_obj = Time::Piece->strptime($date, "%Y:%m:%d %H:%M:%S");

        if ($utc_offset) {
            $time_obj += $utc_offset * 3600;
        }

        my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks) = stat($file);

        $exifTool->WriteInfo($file);

        $mtime = $time_obj->epoch;
        $atime = $mtime;

        # Set the original ownership of the image
        chown($uid, $gid, $file);

        # Set the modification time
        utime($atime, $mtime, $file)
          or warn "Can't change timestamp: $!\n";

        # Set original permissions
        chmod($mode & 07777, $file)
          or warn "Can't change permissions: $!\n";
    }
    else {
        warn "Unable to determine the image creation date. Skipping...\n";
    }

}

@ARGV || usage(1);

push @img_formats, map { quotemeta } split(/\s*,\s*/, $img_formats);

my $img_formats_re = do {
    local $" = '|';
    qr/\.(@img_formats)\z/i;
};

find {
    no_chdir => 1,
    wanted   => sub {
        (/$img_formats_re/o && -f) || return;
        say ":: Processing: $_";
        process_image($_);
    }
} => @ARGV;
