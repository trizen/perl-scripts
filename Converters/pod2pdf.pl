#!/usr/bin/perl

# Author: Trizen
# Date: 16 April 2023
# https://github.com/trizen

# POD to PDF converter, with syntax highlighting.

# Using the following tools:
#   pod2markdown    -- for converting POD to Markdown (part of Pod::Markdown)
#   markdown2pdf.pl -- for converting Markdown to PDF

use 5.010;
use strict;
use warnings;

use Getopt::Long qw(GetOptions);
use File::Temp   qw(tempfile);

my $markdown2pdf = "markdown2pdf.pl";    # path to the `markdown2pdf.pl` script
my $pod2markdown = "pod2markdown";       # path to the `pod2markdown` script

my $lang      = 'perl';
my $style     = 'github';
my $title     = 'Document';
my $page_size = 'A3';

sub usage {
    my ($exit_code) = @_;
    $exit_code //= 0;

    print <<"EOT";
usage: $0 [options] [input.md] [output.pdf]

options:

    --lang=s    : default syntax highlighting language (default: $lang)
    --style=s   : style theme for `highlight` (default: $style)
    --title=s   : title of the PDF file (default: $title)
    --size=s    : set paper size to: A4, Letter, etc. (default: $page_size)

EOT

    exit($exit_code);
}

GetOptions(
           "lang=s"  => \$lang,
           "title=s" => \$title,
           "size=s"  => \$page_size,
           "h|help"  => sub { usage(0) },
          )
  or die("Error in command line arguments\n");

my $input_pod_file  = $ARGV[0] // usage(2);
my $output_pdf_file = $ARGV[1] // ($input_pod_file . ".pdf");

say ":: Converting POD to Markdown...";

my $md = `\Q$pod2markdown\E \Q$input_pod_file\E`;

if (!defined($md)) {
    die "Failed to convert POD to Markdown...\n";
}

my ($md_fh, $md_file) = tempfile();
print $md_fh $md;
close $md_fh;

say ":: Converting Markdown to PDF...";
system($markdown2pdf, "--lang", $lang, "--style", $style, "--title", $title, "--size", $page_size, $md_file, $output_pdf_file);

if ($? != 0) {
    die "Failed to convert Markdown to PDF...\n";
}

unlink($md_file);
