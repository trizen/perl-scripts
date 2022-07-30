#!/usr/bin/perl

# Author: Trizen
# Date: 30 July 2022
# https://github.com/trizen

# Experimental Gitbook to PDF converter, with syntax highlighting.

# Uses the following tools:
#   md2html         -- for converting markdown to HTML
#   markdown2pdf.pl -- for converting markdown to PDF (with syntax highlighting)

use 5.010;
use strict;
use warnings;

use open IO => ':utf8', ':std';
use HTML::TreeBuilder 5 ('-weak');

use PDF::API2    qw();
use Encode       qw(decode_utf8 encode_utf8);
use Getopt::Long qw(GetOptions);
use URI::Escape  qw(uri_unescape);

my $markdown2pdf = "markdown2pdf.pl";    # path to the `markdown2pdf.pl` script

my $style = 'github';
my $title = 'Document';

sub usage {
    my ($exit_code) = @_;
    $exit_code //= 0;

    print <<"EOT";
usage: $0 [options] [SUMMARY.md] [output.pdf]

options:

    --style=s   : style theme for `highlight` (default: $style)
    --title=s   : title of the PDF file (default: $title)

EOT

    exit($exit_code);
}

GetOptions(
           "style=s" => \$style,
           "title=s" => \$title,
           "h|help"  => sub { usage(0) },
          )
  or die("Error in command line arguments\n");

my $input_markdown_file = $ARGV[0] // usage(2);
my $output_pdf_file     = $ARGV[1] // "OUTPUT.pdf";

say ":: Converting $input_markdown_file to HTML...";
my $html = `md2html $input_markdown_file`;

if ($? != 0) {
    die "`md2html` failed with code: $?";
}

my $tree = HTML::TreeBuilder->new();
$tree->parse($html);
$tree->eof();

#my @nodes = $tree->guts();
my @nodes = $tree->disembowel();

my $pdf     = PDF::API2->new;
my $page    = 1;
my $outline = $pdf->outline;

sub end {
    $pdf->preferences(-outlines => 1, -onecolumn => 1);
    $pdf->save($output_pdf_file);
}

local $SIG{INT} = \&end;

sub expand_ul {
    my ($ul, $depth) = @_;

    foreach my $t (@{$ul->content}) {
        if ($t->tag eq 'li') {
            foreach my $x (@{$t->content}) {

                if (!ref($x)) {
                    next;
                }

                if ($x->tag eq 'ul') {
                    expand_ul($x, $depth + 1);
                }
                else {
                    if ($x->tag eq 'a') {

                        my $href     = $x->attr('href');
                        my $file     = decode_utf8(uri_unescape($href));
                        my $pdf_file = "$file.pdf";

                        if (not -e $file) {
                            warn "File <<$file>> does not exist. Skipping...\n";
                            next;
                        }

                        if (not -e $pdf_file) {
                            say ":: Converting <<$file>> to PDF...";
                            system($markdown2pdf, "--style", $style, "--title", $title, $file, $pdf_file);

                            if ($? != 0) {
                                die "`$markdown2pdf` failed with code: $?";
                            }
                        }

                        if (not -e $pdf_file) {
                            warn "File <<$pdf_file>> does not exist. Skipping...\n";
                            next;
                        }

                        my $pdf_obj = PDF::API2->open($pdf_file);

                        my $item = $outline->outline;
                        $item->title(encode_utf8($x->content->[0]));

                        my $start = $page;

                        for my $i (1 .. $pdf_obj->page_count) {
                            $pdf->import_page($pdf_obj, $i, $page);
                            ++$page;
                        }

                        $item->destination($pdf->open_page($start));
                    }

                    #say "[$depth] ",@{$x->content};
                }
            }
        }
    }
}

foreach my $entry (@nodes) {
    if ($entry->tag eq 'ul') {
        expand_ul($entry, 0);
    }
}

end();
