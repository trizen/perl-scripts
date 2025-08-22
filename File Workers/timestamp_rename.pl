#!/usr/bin/perl

# Rename files to their MD5 hex value in a given directory (and its subdirectories).

# Example:
#   "IMG_20231024_094115.jpg" becomes "571b4ba928ae62e103b54727721ebe56.jpg"

use 5.036;
use Digest::MD5           qw();
use File::Find            qw(find);
use File::Basename        qw(dirname basename);
use File::Spec::Functions qw(catfile);

sub md5_rename_file ($file) {

    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
                        $atime,$mtime,$ctime,$blksize,$blocks)
                                               = stat($file);

    my $dirname  = dirname($file);
    my $basename = basename($file);

    if ($basename =~ s{^.*\.(\w+)\z}{$ctime.$1}s) {
        ## ok
    }
    else {
        $basename = $ctime;
    }

    my $new_file = catfile($dirname, $basename);

    if (-e $new_file) {    # new file already exists
        return;
    }

    rename($file, $new_file) or return;
    return $basename;
}

my @dirs = @ARGV;

@dirs || die "usage: $0 [files | dirs]\n";

find(
    {
     wanted => sub {
         if (-f $_) {

             say ":: Renaming file: $_";
             my $basename = md5_rename_file($_);

             if (defined($basename)) {
                 say "-> renamed to: $basename";
             }
             else {
                 say "-> failed to rename...";
             }
         }
     },
    },
    @dirs
);
