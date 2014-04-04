#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 21 March 2014
# http://trizenx.blogspot.com

# Realign the columns of a space-delimited file (with support for comments and empty lines)

use 5.010;
use strict;
use warnings;

sub fstab_beautifier {
    my ($fh, $code) = @_;

    my @data;
    while (defined(my $line = <$fh>)) {
        if ($line =~ /^#/) {    # it's a comment
            push @data, {comment => $line};
        }
        elsif (not $line =~ /\S/) {    # it's an empty line
            push @data, {empty => ""};
        }
        else {                         # hopefully, it's a line with columns
            push @data, {fields => [split(' ', $line)]};
        }
    }

    # Indicate the EOF (this is used to flush the buffer)
    push @data, {eof => 1};

    # Store the columns and the width of each column
    my @buffer;
    my @widths;

    for (my $i = 0 ; $i <= $#data ; $i++) {
        my $line = $data[$i];

        if (exists $line->{fields}) {    # it's a line with columns

            # Collect the maximum width of each column
            while (my ($i, $item) = each @{$line->{fields}}) {
                if ((my $len = length($item)) > ($widths[$i] //= 0)) {
                    $widths[$i] = $len;
                }
            }

            # Store the line in the buffer
            # and continue looping to the next line
            push @buffer, $line->{fields};
            next;
        }
        elsif (exists $line->{comment}) {    # it's a comment
            $code->(unpack("A*", $line->{comment}));
        }

        if (@buffer) {                       # buffer is not empty

            # Create the format for 'sprintf'
            my $format = join("\t", map { "%-${_}s" } splice(@widths));

            # For each line of the buffer, format it and send it further
            while (defined(my $line = shift @buffer)) {
                $code->(unpack("A*", sprintf($format, @{$line})));
            }
        }

        if (exists $line->{empty}) {         # empty line
            $code->($line->{empty});
        }
    }
}

my $fh = @ARGV
  ? do {
    open my $fh, '<', $ARGV[0]
      or die "Can't open file `$ARGV[0]' for reading: $!";
    $fh;
  }
  : \*DATA;

# Call the function with a FileHandle and CODE
fstab_beautifier($fh, sub { say $_[0] });

__END__
# My system partitions
/dev/sda7               swap                     swap           defaults                 0   0
/dev/sda1               /                               ext3            defaults                 1   1
/dev/sda2               /home                   ext3            defaults                 1   2

# My /mnt partitions
/dev/sr0                 /mnt/dvd_sr0    auto           noauto,user,ro  0   0
/dev/sr1         /mnt/dvd_sr1     auto             noauto,user,ro  0   0
/dev/fd0                 /mnt/floppy      auto          rw,noauto,user,sync      0   0
/dev/sdd4        /mnt/zip         vfat             rw,noauto,user,sync   0   0
/dev/sde1               /mnt/usb          auto             rw,noauto,user,sync   0   0

# My /home/vtel57/ partitions
/dev/sda8        /home/vtel57/vtel57_archives   ext2     defaults        0   2
/dev/sdc1        /home/vtel57/vtel57_backups    ext2     defaults        0   2
/dev/sdc7        /home/vtel57/vtel57_common     vfat     rw,gid=users,uid=vtel57         0   0

# My /dev partitions
devpts             /dev/pts              devpts   gid=5,mode=620   0   0
proc                     /proc                  proc            defaults                 0   0
tmpfs                   /dev/shm                 tmpfs     defaults              0   0
