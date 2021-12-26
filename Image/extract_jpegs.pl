#!/usr/bin/perl

# Unpack two or more concatenated JPEG files.

# See also:
#   https://stackoverflow.com/questions/4585527/detect-end-of-file-for-jpg-images

use 5.014;
use strict;
use warnings;

use Digest::MD5 qw(md5_hex);

binmode(STDIN,  ':raw');
binmode(STDOUT, ':raw');

my $data = do {
    local $/;
    <>;
};

#my @files = split(/\x{FF}\x{D8}/, $data);
#my @files = split(/^\xFF\xD8/m, $data);

my $count = 1;

#$data = reverse($data);

#foreach my $data (@files) {
while ($data =~ /(\xFF\xD8.*?\xFF\xD9)/gs) {
    my $jpeg = $1;
    my $name = sprintf("file_%d %s.jpg", $count++, md5_hex($jpeg));
    open my $fh, '>:raw', $name
      or die "Can't open <<$name>>: $!";
    print $fh $jpeg;
    close $fh;
}
