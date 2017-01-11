#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 26 August 2015
# Website: https://github.com/trizen

# Find images that look similar

use 5.022;
use strict;
use warnings;

use experimental 'bitwise';

use Image::Magick qw();
use List::Util qw(sum);
use File::Find qw(find);
use Getopt::Long qw(GetOptions);

my $width      = 64;
my $height     = 64;
my $percentage = 50;

my $img_formats = '';
my $resize_to   = $width . 'x' . $height;

my @img_formats = qw(
  jpeg
  jpg
  png
  );

sub help {
    my ($code) = @_;
    local $" = ",";
    print <<"EOT";
usage: $0 [options] [dir]

options:
    -p  --percentage=i  : mark the images as similar based on this percentage
    -r  --resize-to=s   : resize images to this resolution (default: $resize_to)
    -f  --formats=s,s   : specify more image formats (default: @img_formats)

example:
    perl $0 -p 75 -r '8x8' ~/Pictures
EOT

    exit($code);
}

GetOptions(
           'p|percentage=i' => \$percentage,
           'r|resize-to=s'  => \$resize_to,
           'f|formats=s'    => \$img_formats,
           'h|help'         => sub { help(0) },
          )
  or die("Error in command line arguments");

($width, $height) = split(/\h*x\h*/i, $resize_to);

my $size = $width * $height;
push @img_formats, map { quotemeta } split(/\s*,\s*/, $img_formats);

my $img_formats_re = do {
    local $" = '|';
    qr/\.(@img_formats)\z/i;
};

sub avg {
    ($_[0] + $_[1] + $_[2]) / 3;
}

#<<<
sub alike_percentage {
    ((($_[0] ^. $_[1]) =~ tr/\0//) / $size)**2 * 100;
}
#>>>

sub fingerprint {
    my ($image) = @_;

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

sub find_similar_images(&@) {
    my $callback = shift;

    my @files;
    find {
        no_chdir => 1,
        wanted   => sub {
            (/$img_formats_re/o && -f) || return;

            push @files,
              {
                fingerprint => fingerprint($_) // return,
                filename => $_,
              };
        }
    } => @_;

    #
    ## Populate the %alike hash
    #
    my %alike;
    foreach my $i (0 .. $#files - 1) {
        for (my $j = $i + 1 ; $j <= $#files ; $j++) {
            my $p = alike_percentage($files[$i]{fingerprint}, $files[$j]{fingerprint});
            if ($p >= $percentage) {
                $alike{$files[$i]{filename}}{$files[$j]{filename}} = $p;
                $alike{$files[$j]{filename}}{$files[$i]{filename}} = $p;
            }
        }
    }

    #
    ## Group the files
    #
    my @alike;
    foreach my $root (
        map { $_->[0] }
        sort { ($a->[1] <=> $b->[1]) || ($b->[2] <=> $a->[2]) }
        map {
            my $keys = keys(%{$alike{$_}});
            my $avg  = sum(values(%{$alike{$_}})) / $keys;

            [$_, $keys, $avg]
        }
        keys %alike
      ) {
        my @group = keys(%{$alike{$root}});
        if (@group) {
            my $avg = 0;
            $avg += delete($alike{$_}{$root}) for @group;
            push @alike, {score => $avg / @group, files => [$root, @group]};

        }
    }

    #
    ## Callback each group
    #
    my %seen;
    foreach my $group (sort { $b->{score} <=> $a->{score} } @alike) {
        (@{$group->{files}} == grep { $seen{$_}++ } @{$group->{files}}) and next;
        $callback->($group->{score}, $group->{files});
    }

    return 1;
}

@ARGV || help(1);
find_similar_images {
    my ($score, $files) = @_;
    printf("=> Similarity: %.0f%%\n", $score), say join("\n", sort @{$files});
    say "-" x 80;
}
@ARGV;
