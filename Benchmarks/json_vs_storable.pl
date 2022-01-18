#!/usr/bin/perl

# Speed comparison of JSON::XS vs Storable.

# Result:
#   Storable is significantly faster for both encoding and decoding of data.

use 5.014;
use strict;
use warnings;

use Storable qw(freeze thaw);
use JSON::XS qw(encode_json decode_json);

use LWP::Simple qw(get);
use Benchmark qw(cmpthese);

my $info = {
    content     => get("https://github.com/"),
    description => "GitHub is where people build software. More than 73 million people use GitHub to discover, fork, and contribute to over 200 million projects.",
    id       => "2df61d3f",
    keywords => undef,
    score    => 2,
    title    => "This is a test",
    url      => "https://github.com/",
};

my $storable = freeze($info);
my $json     = encode_json($info);

say "# Decoding speed:\n";

cmpthese(
    -1,
    {
     json => sub {
         my $data = decode_json($json);
     },
     storable => sub {
         my $data = thaw($storable);
     },
    }
);

say "\n# Encoding speed:\n";

cmpthese(
    -1,
    {
     json => sub {
         my $data = encode_json($info);
     },
     storable => sub {
         my $data = freeze($info);
     },
    }
);

__END__

# Decoding speed:

            Rate     json storable
json      2327/s       --     -94%
storable 41533/s    1685%       --

# Encoding speed:

            Rate     json storable
json      1541/s       --     -93%
storable 21721/s    1309%       --
