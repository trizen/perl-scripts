#!/usr/bin/perl

# Author: Trizen
# Date: 16 April 2023
# https://github.com/trizen

# HTML|URL to PDF converter, with JavaScript support.

# Using the following tool:
#   chromium -- for converting HTML to PDF

use 5.010;
use strict;
use warnings;

use open IO => ':utf8', ':std';
use Getopt::Long qw(GetOptions);

my $js_delay = 10000;

sub usage {
    my ($exit_code) = @_;
    $exit_code //= 0;

    print <<"EOT";
usage: $0 [options] [input.html | URL] [output.pdf]

options:

    --js-delay=i : wait some milliseconds for JavaScript to finish (default: $js_delay)

EOT

    exit($exit_code);
}

GetOptions('js-delay=i' => \$js_delay,
           "h|help"     => sub { usage(0) },)
  or die("Error in command line arguments\n");

my $input_html_file = $ARGV[0] // usage(2);
my $output_pdf_file = $ARGV[1] // "output.pdf";

say ":: Converting HTML to PDF...";

system(
    qw(
      chromium
      --headless
      --disable-gpu
      --no-pdf-header-footer
      --disable-pdf-tagging
      --enable-local-file-accesses
      --run-all-compositor-stages-before-draw
    ),
    "--virtual-time-budget=$js_delay",
    "--print-to-pdf=$output_pdf_file",
    $input_html_file,
);

if ($? != 0) {
    die "`chromium` failed with code: $?";
}

say ":: Done!"
