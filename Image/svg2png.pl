#!/usr/bin/perl

# Author: Trizen
# 19 December 2021
# https://github.com/trizen

# Convert SVG images to PNG, using the Gtk3::Gdk::Pixbuf library.

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

use Gtk3 qw(-init);
use File::Spec::Functions qw(catfile);
use File::Basename qw(dirname basename);
use Getopt::Long qw(GetOptions);

my %CONFIG = (
              output_dir   => undef,
              width        => undef,
              height       => undef,
              scale_factor => undef,
              flipx        => undef,
              flipy        => undef,
             );

sub help ($exit_code = 0) {
    print <<"EOT";
Usage: $0 [OPTIONS] [<SVG files>]

  -w, --width=WIDTH     Width of output image in pixels
  -h, --height=HEIGHT   Height of output image in pixels
  -s, --scale=FACTOR    Scale image by FACTOR
  -d, --dir=DIRECTORY   Output directory

  --flipx       Flip X coordinates of image
  --flipy       Flip Y coordinates of image

  --help        Give this help list
EOT

    exit($exit_code);
}

GetOptions(
           "d|directory=s" => \$CONFIG{output_dir},
           "w|width=i"     => \$CONFIG{width},
           "h|height=i"    => \$CONFIG{height},
           "s|scale=f"     => \$CONFIG{scale_factor},
           "flipx"         => \$CONFIG{flipx},
           "flipy"         => \$CONFIG{flipy},
           'help'          => sub { help(0) },
          )
  or help(1);

@ARGV || help(2);

sub svg2png ($input_file, $output_file = undef) {

    my $pixbuf;

    if (defined($CONFIG{width}) or defined($CONFIG{height})) {
        my $width  = $CONFIG{width}  // $CONFIG{height};
        my $height = $CONFIG{height} // $CONFIG{width};
        $pixbuf = "Gtk3::Gdk::Pixbuf"->new_from_file_at_scale($input_file, $width, $height, 0);
    }
    elsif (defined($CONFIG{scale_factor})) {
        my (undef, $width, $height) = Gtk3::Gdk::Pixbuf::get_file_info($input_file);
        my $scale = $CONFIG{scale_factor};
        $pixbuf = "Gtk3::Gdk::Pixbuf"->new_from_file_at_scale($input_file, $width * $scale, $height * $scale, 0);
    }
    else {
        $pixbuf = "Gtk3::Gdk::Pixbuf"->new_from_file($input_file);
    }

    if ($CONFIG{flipx}) {
        $pixbuf = $pixbuf->flip(1);
    }

    if ($CONFIG{flipy}) {
        $pixbuf = $pixbuf->flip(0);
    }

    if (defined($pixbuf)) {
        if (!defined($output_file)) {

            my $output_dir = $CONFIG{output_dir} // dirname($input_file);
            my $basename   = basename($input_file);

            if (not $basename =~ s/\.svg\z/.png/i) {
                $basename .= '.png';
            }

            if (not -d $output_dir) {
                require File::Path;
                File::Path::make_path($output_dir)
                  || warn "Cannot create output directory <<$output_dir>>: $!\n";
            }

            $output_file = catfile($output_dir, $basename);
        }
        $pixbuf->save($output_file, 'png');
        return 1;
    }

    return undef;
}

foreach my $file (@ARGV) {
    say ":: Processing: $file";
    if (-e $file) {
        svg2png($file) || warn "Cannot convert file <<$file>>! Skipping...\n";
    }
    else {
        warn "File <<$file>> does not exist! Skipping...\n";
    }
}
