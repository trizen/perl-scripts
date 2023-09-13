#!/usr/bin/perl

# Collect and move video files into a specific directory, by scanning a given a directory (and its subdirectories) for video files.

# Requires `exiftool`.

use 5.036;
use File::Find            qw(find);
use File::Copy            qw(move);
use File::Path            qw(make_path);
use File::Basename        qw(basename);
use File::Spec::Functions qw(catfile curdir rel2abs);

sub is_video ($file) {
    my $res = `exiftool \Q$file\E`;

    $? == 0       or return;
    defined($res) or return;

    $res =~ m{^MIME\s+Type\s*:\s*video/}mi;
}

sub collect_video ($file, $directory) {

    my $dest = catfile($directory, basename($file));

    if (-e $dest) {
        warn "File <<$dest>> already exists...\n";
        return;
    }

    move($file, $dest);
}

my $directory = rel2abs("Videos");    # directory where to move the videos

if (not -d $directory) {
    make_path($directory)
      or die "Can't create directory <<$directory>>: $!";
}

if (not -d $directory) {
    die "<<$directory>> is not a directory!";
}

my @dirs = @ARGV;
@dirs = curdir() if not @ARGV;

find(
    {
     wanted => sub {
         if (-f $_ and is_video($_)) {
             say ":: Moving video: $_";
             collect_video($_, $directory);
         }
     },
    },
    @dirs
);
