#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 26 August 2015
# Edit: 24 October 2023
# Website: https://github.com/trizen

# Find images that look similar.

# Blog post:
#   https://trizenx.blogspot.com/2015/08/finding-similar-images.html

use 5.022;
use strict;
use warnings;

use experimental qw(bitwise);

use Imager       qw();
use List::Util   qw(sum);
use File::Find   qw(find);
use Getopt::Long qw(GetOptions);

my $width      = 32;
my $height     = 'auto';
my $percentage = 90;

my $keep_only   = undef;
my $img_formats = '';

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
    -w  --width=i       : resize images to this width (default: $width)
    -h  --height=i      : resize images to this height (default: $height)
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
           'w|width=s'      => \$width,
           'h|height=s'     => \$height,
           'f|formats=s'    => \$img_formats,
           'k|keep=s'       => \$keep_only,
          )
  or die("Error in command line arguments");

push @img_formats, map { quotemeta } split(/\s*,\s*/, $img_formats);

my $img_formats_re = do {
    local $" = '|';
    qr/\.(@img_formats)\z/i;
};

#<<<
sub alike_percentage {
    ((($_[0] ^. $_[1]) =~ tr/\0//) / $_[2])**2 * 100;
}
#>>>

sub fingerprint {
    my ($image) = @_;

    my $img = Imager->new(file => $image) or do {
        warn "Failed to load <<$image>>: ", Imager->errstr();
        return;
    };

    if ($height ne 'auto') {
        $img = $img->scale(ypixels => $height);
    }
    else {
        $img = $img->scale(xpixels => $width);
    }

    my ($curr_width, $curr_height) = ($img->getwidth, $img->getheight);

    my @averages;
    foreach my $y (0 .. $curr_height - 1) {
        my @line = $img->getscanline(y => $y);
        foreach my $pixel (@line) {
            my ($R, $G, $B) = $pixel->rgba;
            push @averages, sum($R, $G, $B) / 3;
        }
    }

    my $avg = sum(@averages) / @averages;
    [join('', map { ($_ < $avg) ? 1 : 0 } @averages), $curr_width, $curr_height];
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
            my $p = alike_percentage(
                           $files[$i]{fingerprint}->[0],
                           $files[$j]{fingerprint}->[0],
                           sqrt($files[$i]{fingerprint}->[1] * $files[$j]{fingerprint}->[1]) * sqrt($files[$i]{fingerprint}->[2] * $files[$j]{fingerprint}->[2])
            );
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
