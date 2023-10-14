#!/usr/bin/perl

# Collect and move GIF images into a specific directory, by scanning a given a directory (and its subdirectories) for GIF images.

use 5.036;
use File::Find            qw(find);
use File::Copy            qw(move);
use File::Path            qw(make_path);
use File::Basename        qw(basename);
use File::Spec::Functions qw(catfile curdir rel2abs);
use Getopt::Long          qw(GetOptions);

my $use_exiftool = 0;    # true to use `exiftool` instead of `File::MimeInfo::Magic`

sub is_gif ($file) {

    if ($use_exiftool) {
        my $res = `exiftool \Q$file\E`;

        $? == 0       or return;
        defined($res) or return;

        return ($res =~ m{^MIME\s+Type\s*:\s*image/gif}mi);
    }

    require File::MimeInfo::Magic;
    (File::MimeInfo::Magic::magic($file) // '') eq 'image/gif';
}

sub collect_gif ($file, $directory) {

    my $dest = catfile($directory, basename($file));

    if (-e $dest) {
        warn "File <<$dest>> already exists...\n";
        return;
    }

    move($file, $dest);
}

GetOptions('exiftool!' => \$use_exiftool,)
  or die "Error in command-line arguments!";

my @dirs = @ARGV;

@dirs || die "usage: perl $0 [directory | files]\n";

my $directory = rel2abs("GIF images");    # directory where to move the videos

if (not -d $directory) {
    make_path($directory)
      or die "Can't create directory <<$directory>>: $!";
}

if (not -d $directory) {
    die "<<$directory>> is not a directory!";
}

find(
    {
     wanted => sub {
         if (-f $_ and is_gif($_)) {
             say ":: Moving file: $_";
             collect_gif($_, $directory);
         }
     },
    },
    @dirs
);
