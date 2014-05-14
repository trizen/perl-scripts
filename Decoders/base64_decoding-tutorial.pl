#!/usr/bin/perl

# How does base64 works?
# This short tutorial explains the basics behind the base64 decoding
# Written by Trizen under the GPL.
#
# See also: http://en.wikipedia.org/wiki/Uuencoding
#           http://en.wikipedia.org/wiki/Base64

my $base64 = 'SnVzdCBhbm90aGVyIFBlcmwgaGFja2VyLAo=';    # base64

#--------------Removing non-base64 chars--------------#

# Anything that *ISN'T* A-Z, a-z, 0-9 or [+/._=] will be removed
$base64 =~ tr|A-Za-z0-9+=/||cd;                        # remove non-base64 chars
$base64 =~ s/=+$//;                                    # remove padding (if any)

#--------------Transliteration--------------#
$base64 =~ tr{A-Za-z0-9+/}{ -_};                     # convert to uuencoded format

# same thing as:
# $base64 =~ tr{ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/}
#              { !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_};
# so: A => ' '
#     B => '!'
#     C => '"'
#     and so on...

#--------------Decoding--------------#
print unpack 'u', pack('C', 32 + int(length($1) * 3 / 4)) . $1 while $base64 =~ s/(.{60}|.+)//;

# For short strings, this works just fine:
#     print unpack('u','M'. $base64);

# unpack('u','...') unpacks this:
#       print unpack('u', ':2G5S="!A;F]T:&5R(%!E<FP@:&%C:V5R+ H');

# Compact code 1 (with substitution)
# Code from http://en.wikipedia.org/wiki/Uuencoding
sub base64_decode_1 {
    my ($base64) = @_;
    $base64 =~ tr|A-Za-z0-9+=/||cd;    # remove non-base64 chars
    $base64 =~ s/=+$//;                # remove padding
    $base64 =~ tr|A-Za-z0-9+/| -_|;    # convert to uuencoded format

    my $decoded;
    $decoded .= unpack 'u', pack('C', 32 + int(length($1) * 3 / 4)) . $1 while $base64 =~ s/(.{60}|.+)//;
    return $decoded;
}

# Without substitution
# Coded by Trizen
sub base64_decode_2 {
    my ($base64) = @_;
    $base64 =~ tr|A-Za-z0-9+=/||cd;    # remove non-base64 chars
    $base64 =~ s/=+$//;                # remove padding
    $base64 =~ tr|A-Za-z0-9+/| -_|;    # convert to uuencoded format

    my $x = 84;                        # block size (default should be 60?)
    my $i = -$x;

    my $decoded;
    while (my $block = unpack("A$x", $base64)) {
        my ($base64_length, $offset) = (length($base64), $i + $x);
        substr($base64, $base64_length > $offset ? $offset : $base64_length, $base64_length > $x ? $x : $base64_length, '');
        $decoded .= chr(32 + int(length($block) * 3 / 4)) . $block;
    }
    return unpack('u', $decoded);
}

# May be memory expensive, but it's faster than base64_decode_2()
# Coded by Trizen
sub base64_decode_3 {
    my ($base64) = @_;

    $base64 =~ tr|A-Za-z0-9+=/||cd;    # remove non-base64 chars
    $base64 =~ s/=+$//;                # remove padding
    $base64 =~ tr|A-Za-z0-9+/| -_|;    # convert to uuencoded format

    my $x = 84;                        # block size (default should be 60?)

    my $decoded;
    foreach my $block (unpack("(A$x)*", $base64)) {
        $decoded .= chr(32 + int(length($block) * 3 / 4)) . $block;
    }

    return unpack('u', $decoded);
}

# Faster still :)
# Coded by Gisle Aas
# http://search.cpan.org/~gaas/MIME-Base64-Perl-1.00/lib/MIME/Base64/Perl.pm
sub base64_decode_4 {
    my ($str) = @_;
    $str =~ tr|A-Za-z0-9+=/||cd;    # remove non-base64 chars
    $str =~ s/=+$//;                # remove padding
    $str =~ tr|A-Za-z0-9+/| -_|;    # convert to uuencoded format

    my $uustr = '';
    my ($i, $l);
    $l = length($str) - 60;

    for ($i = 0 ; $i <= $l ; $i += 60) {
        $uustr .= "M" . substr($str, $i, 60);
    }

    $str = substr($str, $i);

    # and any leftover chars
    if ($str ne "") {
        $uustr .= chr(32 + length($str) * 3 / 4) . $str;
    }
    return unpack("u", $uustr);
}

# FASTEST (written in C)
sub base64_decode_5 {
    use MIME::Base64 qw(decode_base64);
    return decode_base64($_[0]);
}


__END__

# Some benchmarks

my $base64_text = <<'BASE64';
QmFzZTY0IGVuY29kaW5nIGNhbiBiZSBoZWxwZnVsIHdoZW4gZmFpcmx5IGxlbmd0aHkgaWRlbnRp
ZnlpbmcgaW5mb3JtYXRpb24gaXMgdXNlZCBpbiBhbiBIVFRQIGVudmlyb25tZW50LiBGb3IgZXhh
bXBsZSwgYSBkYXRhYmFzZSBwZXJzaXN0ZW5jZSBmcmFtZXdvcmsgZm9yIEphdmEgb2JqZWN0cyBt
aWdodCB1c2UgQmFzZTY0IGVuY29kaW5nIHRvIGVuY29kZSBhIHJlbGF0aXZlbHkgbGFyZ2UgdW5p
cXVlIGlkIChnZW5lcmFsbHkgMTI4LWJpdCBVVUlEcykgaW50byBhIHN0cmluZyBmb3IgdXNlIGFz
IGFuIEhUVFAgcGFyYW1ldGVyIGluIEhUVFAgZm9ybXMgb3IgSFRUUCBHRVQgVVJMcy4gQWxzbywg
bWFueSBhcHBsaWNhdGlvbnMgbmVlZCB0byBlbmNvZGUgYmluYXJ5IGRhdGEgaW4gYSB3YXkgdGhh
dCBpcyBjb252ZW5pZW50IGZvciBpbmNsdXNpb24gaW4gVVJMcywgaW5jbHVkaW5nIGluIGhpZGRl
biB3ZWIgZm9ybSBmaWVsZHMsIGFuZCBCYXNlNjQgaXMgYSBjb252ZW5pZW50IGVuY29kaW5nIHRv
IHJlbmRlciB0aGVtIGluIG5vdCBvbmx5IGEgY29tcGFjdCB3YXksIGJ1dCBpbiBhIHJlbGF0aXZl
bHkgdW5yZWFkYWJsZSBvbmUgd2hlbiB0cnlpbmcgdG8gb2JzY3VyZSB0aGUgbmF0dXJlIG9mIGRh
dGEgZnJvbSBhIGNhc3VhbCBodW1hbiBvYnNlcnZlci4K
BASE64

use Benchmark qw(timethese cmpthese);

my $results = timethese(
                        10000,
                        {
                         'base64_decode_1' => sub { base64_decode_1($base64_text) },
                         'base64_decode_2' => sub { base64_decode_2($base64_text) },
                         'base64_decode_3' => sub { base64_decode_3($base64_text) },
                         'base64_decode_4' => sub { base64_decode_4($base64_text) },
                         'base64_decode_5' => sub { base64_decode_5($base64_text) },
                        }
                       );
cmpthese($results);
