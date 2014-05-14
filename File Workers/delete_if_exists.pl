#!/usr/bin/perl
#
# Delete files from $delete_dir if exists in $compare_dir
#
# Usage: perl delete_if_exists.pl /delete/dir /compare/dir
#

use File::Find qw(find);
use File::Spec::Functions qw(rel2abs catdir);

my $delete_dir = rel2abs(shift);
my $compare_dir = rel2abs(shift || die "usage: $0 [delete_dir] [compare_dir]\n");

find sub {
    return unless -f;
    my $delete_file = catdir($delete_dir, $_);
    if (-f $delete_file) {
        print unlink($delete_file)
          ? "** Deleted: $delete_file\n"
          : "[!] Can't delete $delete_file: $!\n";
    }
} => $compare_dir;
