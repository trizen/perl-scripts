#!/usr/bin/perl

# Author: Trizen
# Date: 04 May 2022
# May the 4th Be With You
# https://github.com/trizen

# Show human-readable stats for the dnscrypt-proxy query log.

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

use Getopt::Long qw(GetOptions);
use List::Util qw(sum);

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
my @durations;

open my $fh, '<:utf8', $log_file
  or die "Can't open <<$log_file>>: $!";

while (<$fh>) {
    if (m{^\[.*?\]\s+\S+\s+(\S+)\s+\S+\s+\S+\s+(\S+)\s+(\S+)}) {
        my ($host, $time_ms, $resolver) = ($1, $2, $3);

        $domains{$host}++;

        if ($resolver eq '-') {
            $resolvers{'--cache--'}++;
        }
        else {
            $cache_misses{$host}++;
            $resolvers{$resolver}++;
            push @durations, ($time_ms =~ /^(\d+)/);
        }
    }
}

close $fh;

sub display_top ($header, $data) {

    my @entries = sort { ($data->{$b} <=> $data->{$a}) || ($a cmp $b) } keys %$data;
    my $total   = sum(values %$data);

    if (scalar(@entries) > $top) {
        $#entries = $top - 1;
    }

    printf($header, scalar(@entries));

    foreach my $entry (@entries) {
        printf("%40s  %5d  %.0f%%\n", $entry, $data->{$entry}, $data->{$entry} / $total * 100);
    }
}

display_top(":: Top %s resolved domains:\n\n", \%domains);
display_top("\n:: Top %s cache misses:\n\n",   \%cache_misses);
display_top("\n:: Top %s resolvers:\n\n",      \%resolvers);

if (@durations) {
    say "\n:: Average resolving time: ", sprintf('%.2f', sum(@durations) / scalar(@durations)), "ms.";
    say ":: Overall resolving time (including caching): ", sprintf('%.2f', sum(@durations) / sum(values %domains)), "ms.";
}
