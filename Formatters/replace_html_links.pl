#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 07 December 2017
# https://github.com/trizen

# Replace URLs inside an HTML file with a given URL.

use strict;
use warnings;

use open IO => ':utf8';    # use UTF-8 I/O encoding

use HTML::TreeBuilder;
use File::Path qw(make_path);
use File::Basename qw(basename);
use File::Spec::Functions qw(catfile);

# Directory where to write processed HTML files
my $output_dir = 'Processed HTML files';

# The URL used in replacing the other URLs inside the HTML files
my $url;

#$url = 'http://example.net';           # predefined URL
$url //= shift(@ARGV);                  # or URL specified in the first command-line argument

if (not defined($url)) {
    die "usage: $0 [url] [HTML files]\n";
}

if (not -d $output_dir) {
    make_path($output_dir)
      or die "Can't create directory `$output_dir': $!";
}

foreach my $file (grep { -f } @ARGV) {

    # Open the input HTML file for reading
    open my $in_fh, '<', $file
      or do {
        warn "Can't open file `$file' for reading: $!";
        next;
      };

    # Create a new HTML::TreeBuilder object
    my $tree = HTML::TreeBuilder->new;

    # Parse the HTML content
    $tree->parse_file($in_fh);

    # Traverse the HTML tree and replace URLs
    $tree->traverse(
        [
         sub {
             my ($elem) = @_;

             if (    ref($elem) eq 'HTML::Element'
                 and $elem->tag eq 'a'
                 and defined($elem->attr('href'))
             ) {
                 $elem->attr('href', $url);
             }

             return HTML::Element::OK;
         },
        ]
    );

    # The output HTML filename
    my $output_file = catfile($output_dir, basename($file));

    # Create the new HTML content
    my $new_html = $tree->as_HTML;

    # Open the output HTML file for writing
    open my $out_fh, '>', $output_file or do {
        warn "Can't open file `$output_file' for writing: $!";
        next;
    };

    # Write the new HTML content
    print $out_fh $new_html, "\n";

    # Close the output file-handle
    close $out_fh;
}
