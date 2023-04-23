#!/usr/bin/perl

# Author: Trizen
# Date: 16 April 2023
# https://github.com/trizen

# HTML to PDF converter, with JavaScript support.

# Using the following tool:
#   wkhtmltopdf -- for converting HTML to PDF

use 5.010;
use strict;
use warnings;

use open IO => ':utf8', ':std';
use Getopt::Long qw(GetOptions);

my $title     = undef;
my $js        = 0;
my $js_delay  = 1000;
my $page_size = 'A3';

sub usage {
    my ($exit_code) = @_;
    $exit_code //= 0;

    print <<"EOT";
usage: $0 [options] [input.md] [output.pdf]

options:

    --js         : allow web pages to run JavaScript (default: $js)
    --js-delay=i : wait some milliseconds for JavaScript to finish (default: $js_delay)
    --title=s    : title of the PDF file
    --size=s     : set paper size to: A4, Letter, etc. (default: $page_size)

EOT

    exit($exit_code);
}

GetOptions(
           "title=s"        => \$title,
           "size=s"         => \$page_size,
           'js|javascript!' => \$js,
           'js-delay=i'     => \$js_delay,
           "h|help"         => sub { usage(0) },
          )
  or die("Error in command line arguments\n");

my $input_html_file = $ARGV[0] // usage(2);
my $output_pdf_file = $ARGV[1] // ($input_html_file . ".pdf");

say ":: Converting HTML to PDF...";

system(
    qw(wkhtmltopdf
      --quiet
      --enable-smart-shrinking
      --images
      --enable-external-links
      --enable-internal-links
      --keep-relative-links
      --enable-local-file-access
      --load-error-handling ignore),
    "--page-size", $page_size,
    (defined($title) ? ('--title', $title) : ()),
    ($js             ? (
            '--enable-javascript',
            '--javascript-delay', $js_delay
       ) : ('--disable-javascript')),
    $input_html_file,
    $output_pdf_file,
);

if ($? != 0) {
    die "`wkhtmltopdf` failed with code: $?";
}

say ":: Done!"
