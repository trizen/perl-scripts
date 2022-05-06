#!/usr/bin/perl

# Author: Trizen
# Date: 04 May 2022
# May the 4th Be With You
# https://github.com/trizen

# Show human-readable stats for the dnscrypt-proxy query log.

use 5.020;
use strict;
use warnings;

use List::Util qw(sum);
use experimental qw(signatures);
use Getopt::Long qw(GetOptions);

my $top      = 10;
my $log_file = '/var/log/dnscrypt-proxy/query.log';

sub help {
    print <<"EOT";
usage: $0 [options]

options:

    --top=i   : display the top results (default: $top)
    --file=s  : path to the log file
    --help    : display this message

EOT

    exit;
}

GetOptions(
           "top=i"  => \$top,
           "file=s" => \$log_file,
           "h|help" => \&help,
          )
  or die("Error in command line arguments\n");

my %domains;
my %resolvers;
my %cache_misses;
my %cache_hits;
my @durations;

open my $fh, '<:utf8', $log_file
  or die "Can't open <<$log_file>>: $!";

while (<$fh>) {
    if (m{^\[.*?\]\s+\S+\s+(\S+)\s+\S+\s+(\S+)\s+(\S+)\s+(\S+)}) {
        my ($host, $status, $time_ms, $resolver) = ($1, $2, $3, $4);

        $status eq 'PASS' or next;

        $domains{$host}++;

        if ($resolver eq '-') {
            $resolvers{'--cache--'}++;
            $cache_hits{$host}++;
        }
        else {
            $cache_misses{$host}++;
            $resolvers{$resolver}++;
            push @durations, ($time_ms =~ /^(\d+)/);
        }
    }
}

close $fh;

sub make_top ($header, $data) {

    my @entries = sort { ($data->{$b} <=> $data->{$a}) || ($a cmp $b) } keys %$data;
    my $total   = sum(values %$data);

    if (scalar(@entries) > $top) {
        $#entries = $top - 1;
    }

    my @rows;
    push @rows, sprintf($header, scalar(@entries));

    foreach my $entry (@entries) {
        push @rows, sprintf("%40s  %5d  %.0f%%", $entry, $data->{$entry}, $data->{$entry} / $total * 100);
    }

    return \@rows;
}

my @top;

push @top, make_top("Top %s resolved domains", \%domains);
push @top, make_top("Top %s cache misses",     \%cache_misses);
push @top, make_top("Top %s cache hits",       \%cache_hits);
push @top, make_top("Top %s resolvers",        \%resolvers);

while (@top) {
    my ($x, $y) = splice(@top, 0, 2);

    my ($header1, $header2) = (shift(@$x), shift(@$y));
    printf("%50s %60s\n\n", "== $header1 == ", " == $header2 == ");

    while (@$x or @$y) {
        printf("%-60s %s\n", shift(@$x) // '', shift(@$y) // '');
    }

    print "\n";
}

if (@durations) {
    say "\n:: Average resolving time: ",                   sprintf('%.2f', sum(@durations) / scalar(@durations)),   "ms.";
    say ":: Overall resolving time (including caching): ", sprintf('%.2f', sum(@durations) / sum(values %domains)), "ms.";
}
