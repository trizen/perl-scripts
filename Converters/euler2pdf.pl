#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use PDF::API2 qw();
use Text::Unidecode qw(unidecode);
use HTML::Entities qw(decode_entities);
use File::Spec::Functions qw(catfile tmpdir);

my $main_url = 'https://projecteuler.net/problem=%d';

my $p_beg = 1;
my $p_end = 608;

my $update_p_nums = 1;    # true to retrieve the current number of problems

if ($update_p_nums) {

    require LWP::UserAgent;
    my $lwp = LWP::UserAgent->new(
           env_proxy => 1,
           agent => 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2490.80 Safari/537.36',
    );

    my $resp = $lwp->get('https://projecteuler.net/archives');
    if ($resp->is_success) {
        my $content = $resp->decoded_content;

        if ($content =~ /The problems archives table shows problems (\d+) to (\d+)/) {
            $p_beg = $1;
            $p_end = $2;
            say "Successfully updated the number of problems ($p_beg to $p_end)";
        }
        else {
            warn "Can't get the new number of problems. Using the default ones...";
        }
    }
}

my $page = 1;
my $pdf  = PDF::API2->new;

my $ms_delay     = 3500;                                    # wait some milliseconds for JavaScript to finish
my $outlines     = $pdf->outlines;
my $cache_dir    = tmpdir();
my $outline_file = catfile($cache_dir, "outline_$$.txt");

sub end {
    $pdf->preferences(-outlines => 1, -onecolumn => 1);
    $pdf->saveas('Project Euler.pdf');
}

local $SIG{INT} = \&end;

for my $i ($p_beg .. $p_end) {

    printf("[%3d of %3d] Processing...\n", $i, $p_end);

    my $url = sprintf($main_url, $i);
    my $pdf_data = `wkhtmltopdf              \\
        --dump-outline \Q$outline_file\E     \\
        --quiet                              \\
        --use-xserver                        \\
        --enable-javascript                  \\
        --enable-smart-shrinking             \\
        --images                             \\
        --enable-forms                       \\
        --enable-plugins                     \\
        --enable-external-links              \\
        --load-error-handling ignore         \\
        --javascript-delay $ms_delay         \\
        --cache-dir \Q$cache_dir\E           \\
        \Q$url\E                             \\
        /dev/stdout`;

    if (defined $pdf_data) {
        my $pdf_obj = PDF::API2->openScalar($pdf_data);

        my $outline = $outlines->outline;
        if (open my $fh, '<:utf8', $outline_file) {
            while (<$fh>) {
                if (/^\h*<item title="(.*?)" page="1"/) {
                    my $title = unidecode(decode_entities($1));
                    $outline->title("$i. $title");
                    last;
                }
            }
        }

        my $start = $page;

        for my $i (1 .. $pdf_obj->pages) {
            $pdf->importpage($pdf_obj, $i, $page);
            ++$page;
        }

        $outline->dest($pdf->openpage($start));
    }
}

end();
