#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use PDF::API2;

my $main_url = 'https://projecteuler.net/problem=%d';

my $page = 1;
my $pdf  = PDF::API2->new;

my $p_beg = 1;
my $p_end = 521;

my $update_p_nums = 1;    # retrieve the current number of problems

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

for my $i ($p_beg .. $p_end) {
    my $url = sprintf($main_url, $i);
    my $pdf_data = `wkhtmltopdf --use-xserver \Q$url\E /dev/stdout`;

    if (defined $pdf_data) {
        my $pdf_obj = PDF::API2->openScalar($pdf_data);

        for my $i (1 .. $pdf_obj->pages) {
            $pdf->importpage($pdf_obj, $i, $page);
            ++$page;
        }
    }
}

$pdf->saveas('project_euler.pdf') or die "Can't save: $!";
