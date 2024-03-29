#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 26 August 2015
# Edit: 25 October 2023
# Website: https://github.com/trizen

# Find images that look similar.

# Blog post:
#   https://trizenx.blogspot.com/2015/08/finding-similar-images.html

use 5.022;
use strict;
use warnings;

use experimental 'bitwise';

use Image::Magick qw();
use List::Util    qw(sum);
use File::Find    qw(find);
use Getopt::Long  qw(GetOptions);

my $width      = 32;
my $height     = 32;
my $percentage = 90;

my $keep_only   = undef;
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
    -p  --percentage=i  : minimum similarity percentage (default: $percentage)
    -r  --resize-to=s   : resize images to this resolution (default: $resize_to)
    -f  --formats=s,s   : specify more image formats (default: @img_formats)
    -k  --keep=s        : keep only the 'smallest' or 'largest' image from each group

WARNING: option '-k' permanently removes your images!

example:
    perl $0 -p 75 -r '8x8' ~/Pictures
EOT

    exit($code);
}

GetOptions(
           'p|percentage=i' => \$percentage,
           'r|resize-to=s'  => \$resize_to,
           'f|formats=s'    => \$img_formats,
           'k|keep=s'       => \$keep_only,
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

#<<<
sub alike_percentage {
    ((($_[0] ^. $_[1]) =~ tr/\0//) / $size)**2 * 100;
}
#>>>

sub fingerprint {
    my ($image) = @_;

    my $img = Image::Magick->new;
    $img->Read(filename => $image) && return;

    $img->AdaptiveResize(width => $width, height => $height) && return;   # balanced
    ## $img->Resize(width => $width, height => $height) && return;        # better, but slower
    ## $img->Resample(width => $width, height => $height) && return;      # faster, but worse

    my @pixels = $img->GetPixels(
                                 map       => 'RGB',
                                 x         => 0,
                                 y         => 0,
                                 width     => $width,
                                 height    => $height,
                                 normalize => 1,
                                );

    my @averages;

    while (@pixels) {
        push @averages, sum(splice(@pixels, 0, 3))/3;
    }

    my $avg = sum(@averages) / @averages;
    join('', map { ($_ < $avg) ? 1 : 0 } @averages);
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
                filename    => $_,
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
        map  { $_->[0] }
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

    printf("=> Similarity: %.0f%%\n", $score);
    say join("\n", sort @{$files});
    say "-" x 80;

    if (defined($keep_only)) {

        my @existent_files = grep { -f $_ } @$files;

        scalar(@existent_files) > 1 or return;

        my @sorted_by_size = map { $_->[0] } sort { $a->[1] <=> $b->[1] } map { [$_, -s $_] } @existent_files;
        if ($keep_only =~ /large/i) {
            pop(@sorted_by_size);
        }
        elsif ($keep_only =~ /small/i) {
            shift(@sorted_by_size);
        }
        else {
            die "error: unknown value <<$keep_only>> for option `-k`!\n";
        }
        foreach my $file (@sorted_by_size) {
            say "Removing: $file";
            unlink($file) or warn "Failed to remove: $!";
        }
    }
} @ARGV;
