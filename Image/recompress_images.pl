#!/usr/bin/perl

# Author: Trizen
# Date: 13 September 2023
# Edit: 18 September 2023
# https://github.com/trizen

# Recompress a given list of images, using either PNG or JPEG (whichever results in a smaller file size).

# WARNING: the original files are deleted!
# WARNING: the program does LOSSY compression of images!

# If the file is a PNG image:
#   1. we create a JPEG copy
#   2. we recompress the PNG image using `pngquant`
#   3. we recompress the JPEG copy using `jpegoptim`
#   4. then we keep whichever is smaller: the PNG or the JPEG file

# If the file is a JPEG image:
#   1. we create a PNG copy
#   2. we recompress the JPEG image using `jpegoptim`
#   3. we recompress the PNG copy using `pngquant`
#   4. then we keep whichever is smaller: the JPEG or the PNG file

# The following tools are required:
#   * jpegoptim  -- for recompressing JPEG images
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

my $use_exiftool = 0;        # true to use `exiftool` instead of `File::MimeInfo::Magic`

sub png2jpeg (%args) {

    my $orig_file = $args{png_file}  // return;
    my $jpeg_file = $args{jpeg_file} // return;

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

sub jpeg2png (%args) {

    my $orig_file = $args{jpeg_file} // return;
    my $png_file  = $args{png_file}  // return;

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

    if ($file =~ /\.jpe?g\z/i) {
        return "image/jpeg";
    }

    if ($file =~ /\.png\z/i) {
        return "image/png";
    }

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

    # Uncomment the following line to use `recomp-jpg` from LittleUtils
    # return system('recomp-jpg', '-q', '-t', $quality, $jpeg_file);

    system('jpegoptim', '-q', '-s', '--threshold=0.1', '-m', $quality, $jpeg_file);
}

sub optimize_png ($png_file) {
    system('pngquant', '--strip', '--ext', '.png', '--skip-if-larger', '--force', $png_file);
}

@ARGV or die <<"USAGE";
usage: perl $0 [options] [dirs | files]

Recompress a given list of images, using either PNG or JPEG (whichever results in a smaller file size).

options:

    -q INT      : quality level for JPEG (default: $quality)
    --jpeg      : recompress only JPEG images (default: $jpeg_only)
    --png       : recompress only PNG images (default: $png_only)
    --exiftool  : use `exiftool` to determine the MIME type (default: $use_exiftool)

WARNING: the original files are deleted!
WARNING: the program does LOSSY compression of images!
USAGE

GetOptions(
           'q|quality=i' => \$quality,
           'jpeg|jpg!'   => \$jpeg_only,
           'png!'        => \$png_only,
           'exiftool!'   => \$use_exiftool,
          )
  or die "Error in command-line arguments!";

my %types = (
             'image/png' => {
                             files  => [],
                             format => 'png',
                            },
             'image/jpeg' => {
                              files  => [],
                              format => 'jpg',
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

sub recompress_image ($file, $file_format) {

    my $conversion_func = \&jpeg2png;
    my $temp_file       = $temp_jpg;

    if ($file_format eq 'png') {
        $conversion_func = \&png2jpeg;
        $temp_file       = $temp_png;
    }

    copy($file, $temp_file) or do {
        warn "[!] Can't copy <<$file>> to <<$temp_file>>: $!\n";
        return;
    };

    $conversion_func->(png_file => $temp_png, jpeg_file => $temp_jpg) or return;
    optimize_png($temp_png);
    optimize_jpeg($temp_jpg);

    my $final_file = $temp_png;
    my $file_ext   = 'png';

    if ((-s $temp_jpg) < (-s $final_file)) {
        $final_file = $temp_jpg;
        $file_ext   = 'jpg';
    }

    my $final_size = (-s $final_file);
    my $curr_size  = (-s $file);

    $final_size > 0 or return;

    if ($final_size < $curr_size) {

        my $saved = ($curr_size - $final_size) / 1024;

        $total_savings += $saved;

        printf(":: Saved: %.2fKB (%.2fMB -> %.2fMB) (%.2f%%) ($file_format -> $file_ext)\n\n",
               $saved,
               $curr_size / 1024**2,
               $final_size / 1024**2,
               ($curr_size - $final_size) / $curr_size * 100);

        unlink($file) or return;

        my $new_file = ($file =~ s/\.(?:png|jpe?g)\z//ir) . '.' . $file_ext;

        while (-e $new_file) {    # lazy solution
            $new_file .= '.' . $file_ext;
        }

        copy($final_file, $new_file) or do {
            warn "[!] Can't copy <<$final_file>> to <<$new_file>>: $!\n";
            return;
        };
    }
    else {
        printf(":: The image is already very well compressed. Skipping...\n\n");
    }

    return 1;
}

foreach my $type (keys %types) {

    my $ref = $types{$type};

    if ($jpeg_only and $ref->{format} eq 'png') {
        next;
    }

    if ($png_only and $ref->{format} eq 'jpg') {
        next;
    }

    foreach my $file (@{$ref->{files}}) {
        if ($ref->{format} eq 'png') {
            say ":: Processing PNG file: $file";
            recompress_image($file, 'png');

        }
        elsif ($ref->{format} eq 'jpg') {
            say ":: Processing JPEG file: $file";
            recompress_image($file, 'jpg');
        }
        else {
            say "ERROR: unknown format type for file: $file";
        }
    }
}

unlink($temp_jpg);
unlink($temp_png);

printf(":: Total savings: %.2fKB\n", $total_savings),
