#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 14 April 2012
# https://github.com/trizen

@ARGV = @ARGV ? (@ARGV) : ($0);

foreach my $file (grep { -f } @ARGV) {
    open my $fh, '<', $file or next;
    my $s = '';
    while (1) {
        my $i = ord(getc($fh) // last);
        while (1) {
            my $f = int rand $i;
            my $l = int rand $i * 2;
            if (($f | $l) == $i)  { $s .= "$f|$l,"  => last }
            if (($f * $l) == $i)  { $s .= "$f*$l,"  => last }
            if (($l >> $f) == $i) { $s .= "$l>>$f," => last }
            if (($f << $l) == $i) { $s .= "$f<<$l," => last }
            if (($l << $f) == $i) { $s .= "$l<<$f," => last }
            if (($f**$l) == $i)   { $s .= "$f**$l," => last }
            if (($l**$f) == $i)   { $s .= "$l**$f," => last }
            if (($f + $l) == $i)  { $s .= "$f+$l,"  => last }
            if (($l - $f) == $i)  { $s .= "$l-$f,"  => last }
            if (($f ^ $l) == $i)  { $s .= "$f^$l,"  => last }
        }
    }
    close $fh;

    print <<"EOT";
print chr for $s;
EOT
}
