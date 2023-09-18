#!/usr/bin/perl

# Author: Trizen
# Date: 13 September 2023
# https://github.com/trizen

# Recompress a given list of images, using either PNG or JPEG (whichever results in a smaller file size).

# WARNING: the original files are deleted!
# WARNING: the program does LOSSY compression of images!

# If the file is a PNG image:
#   1. we recompress it using `pngquant`
#   2. we create a JPEG copy
#   3. we recompress the JPEG copy using `recomp-jpg` from LittleUtils
#   4. then we keep whichever is smaller: the PNG or the JPEG file

# If the file is a JPEG image:
#   1. we recompress it using `recomp-jpg` from LittleUtils
#   2. we create a PNG copy
#   3. we recompress the PNG copy using `pngquant`
#   4. then we keep whichever is smaller: the JPEG or the PNG file

# The following tools are required:
#   * recomp-jpg -- for recompressing JPEG images (from LittleUtils)
#   * jpegoptim  -- for recompressing JPEG images (with --jpegoptim)
#   * pngquant   -- for recompressing PNG images

use 5.036;

use GD;
use File::Find            qw(find);
use File::Temp            qw(mktemp);
use File::Copy            qw(copy);
use File::Spec::Functions qw(catfile tmpdir);
use Getopt::Long          qw(GetOptions);

GD::Image->trueColor(1);

my $png_only  = 0;    # true to recompress only PNG images
my $jpeg_only = 0;    # true to recompress only JPEG images

my $quality         = 85;    # default quality value for JPEG (between 0-100)
my $png_compression = 0;     # default PNG compression level for GD (between 0-9)

my $use_exiftool  = 0;       # true to use `exiftool` instead of `File::MimeInfo::Magic`
my $use_jpegoptim = 0;       # true to use `jpegoptim` instead of `recomp-jpg`

sub png2jpeg ($orig_file, $jpeg_file) {

    my $image = eval { GD::Image->new($orig_file) } // do {
        warn "[!] Can't load file <<$orig_file>>. Skipping...\n";
        return;
    };

    my $jpeg_data = $image->jpeg($quality);

    open(my $fh, '>:raw', $jpeg_file) or do {
        warn "[!] Can't open file <<$jpeg_file>> for writing: $!\n";
        return;
    };

    print {$fh} $jpeg_data;
    close $fh;
}

sub jpeg2png ($orig_file, $png_file) {

    my $image = eval { GD::Image->new($orig_file) } // do {
        warn "[!] Can't load file <<$orig_file>>. Skipping...\n";
        return;
    };

    my $png_data = $image->png($png_compression);

    open(my $fh, '>:raw', $png_file) or do {
        warn "[!] Can't open file <<$png_file>> for writing: $!\n";
        return;
    };

    print {$fh} $png_data;
    close $fh;
}

sub determine_mime_type ($file) {

    if ($use_exiftool) {
        my $res = `exiftool \Q$file\E`;
        $? == 0       or return;
        defined($res) or return;
        if ($res =~ m{^MIME\s+Type\s*:\s*(\S+)}mi) {
            return $1;
        }
        return;
    }

    require File::MimeInfo::Magic;
    File::MimeInfo::Magic::magic($file);
}

sub optimize_jpeg ($jpeg_file) {

    if ($use_jpegoptim) {
        return system('jpegoptim', '-s', '-m', $quality, $jpeg_file);
    }

    system('recomp-jpg', '-t', $quality, $jpeg_file);
}

sub optimize_png ($png_file) {
    system('pngquant', '--strip', '--ext', '.png', '--skip-if-larger', '--force', $png_file);
}

@ARGV or die <<"USAGE";
usage: perl $0 [options] [dirs | files]

options:

    -q INT      : quality level for JPEG (default: $quality)
    --jpeg      : recompress only JPEG images (default: $jpeg_only)
    --png       : recompress only PNG images (default: $png_only)
    --exiftool  : use `exiftool` to determine the MIME type (default: $use_exiftool)
    --jpegoptim : use `jpegoptim` instead of `recomp-jpg` (default: $use_jpegoptim)

USAGE

GetOptions(
           'q|quality=i' => \$quality,
           'jpeg|jpg!'   => \$jpeg_only,
           'png!'        => \$png_only,
           'exiftool!'   => \$use_exiftool,
           'jpegoptim!'  => \$use_jpegoptim,
          )
  or die "Error in command-line arguments!";

my %types = (
             'image/png' => {
                             files  => [],
                             format => 'png',
                            },
             'image/jpeg' => {
                              files  => [],
                              format => 'jpeg',
                             },
            );

find(
    {
     no_chdir => 1,
     wanted   => sub {

         (-f $_) || return;
         my $type = determine_mime_type($_) // return;

         if (exists $types{$type}) {
             my $ref = $types{$type};
             push @{$ref->{files}}, $_;
         }
     }
    } => @ARGV
);

my $total_savings = 0;

my $temp_png = catfile(tmpdir(), mktemp("tmpfileXXXXX") . '.png');
my $temp_jpg = catfile(tmpdir(), mktemp("tmpfileXXXXX") . '.jpg');

foreach my $type (keys %types) {

    my $ref = $types{$type};

    if ($jpeg_only and $ref->{format} eq 'png') {
        next;
    }

    if ($png_only and $ref->{format} eq 'jpeg') {
        next;
    }

    foreach my $file (@{$ref->{files}}) {

        if ($ref->{format} eq 'png') {
            say ":: Processing PNG file: $file";

            # 1. we recompress it using `pngquant`
            # 2. we create a JPEG copy
            # 3. we recompress the JPEG copy using `recomp-jpg` from LittleUtils
            # 4. then we keep whichever is smaller: the PNG or the JPEG file

            copy($file, $temp_png) or do {
                warn "[!] Can't copy <<$file>> to <<$temp_png>>: $!\n";
                next;
            };

            png2jpeg($temp_png, $temp_jpg) or next;
            optimize_png($temp_png);
            optimize_jpeg($temp_jpg);

            my $final_file = $temp_png;
            my $file_ext   = 'png';

            if ((-s $temp_jpg) < (-s $final_file)) {
                $final_file = $temp_jpg;
                $file_ext   = 'jpg';
            }

            (-s $final_file) > 0 or next;

            if ((-s $final_file) < (-s $file)) {
                my $saved = ((-s $file) - (-s $final_file)) / 1024;
                $total_savings += $saved;
                printf(":: Saved: %.2fKB\n\n", $saved);
                unlink($file);
                my $new_file = ($file =~ s/\.png\z//ir) . '.' . $file_ext;
                while (-e $new_file) {    # lazy solution
                    $new_file .= '.' . $file_ext;
                }
                copy($final_file, $new_file);
            }
            else {
                printf(":: The recompressed file is larger by %.2fB. Skipping...\n\n", (-s $final_file) - (-s $file));
            }
        }
        elsif ($ref->{format} eq 'jpeg') {
            say ":: Processing JPEG file: $file";

            # 1. we recompress it using `recomp-jpg` from LittleUtils
            # 2. we create a PNG copy
            # 3. we recompress the PNG copy using `pngquant`
            # 4. then we keep whichever is smaller: the JPEG or the PNG file

            copy($file, $temp_jpg) or do {
                warn "[!] Can't copy <<$file>> to <<$temp_jpg>>: $!\n";
                next;
            };

            jpeg2png($temp_jpg, $temp_png) or next;
            optimize_jpeg($temp_jpg);
            optimize_png($temp_png);

            my $final_file = $temp_png;
            my $file_ext   = 'png';

            if ((-s $temp_jpg) < (-s $final_file)) {
                $final_file = $temp_jpg;
                $file_ext   = 'jpg';
            }

            (-s $final_file) > 0 or next;

            if ((-s $final_file) < (-s $file)) {
                my $saved = ((-s $file) - (-s $final_file)) / 1024;
                $total_savings += $saved;
                printf(":: Saved: %.2fKB\n\n", $saved);
                unlink($file);
                my $new_file = ($file =~ s/\.jpe?g\z//ir) . '.' . $file_ext;
                while (-e $new_file) {    # lazy solution
                    $new_file .= '.' . $file_ext;
                }
                copy($final_file, $new_file);
            }
            else {
                printf(":: The recompressed file is larger by %.2fB. Skipping...\n\n", (-s $final_file) - (-s $file));
            }
        }
        else {
            say "ERROR: unknown format type for file: $file";
        }
    }
}

unlink($temp_jpg);
unlink($temp_png);

printf(":: Total savings: %.2fKB\n", $total_savings),
