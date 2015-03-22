#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 08 April 2014
# Website: http://github.com/trizen

# Voice control - take actions based on vocal commands
# Configuration, grammar and .voca files: https://github.com/trizen/config-files/tree/master/.voxforge/julius

use utf8;
use 5.010;
use strict;
use warnings;
use List::Util qw(sum);

no if $] >= 5.018, warnings => 'experimental';

my %forks;
my $config = "$ENV{HOME}/.voxforge/julius/perl.jconf";
my @julius = qw(julius -input mic);

open(my $pipe_h, '-|', @julius, '-C', $config) // exit $!;

sub take_action {
    my ($command) = @_;

    given ($command) {
        when ('<s> PLAY MUSIC </s>') {
            say "Starting music...";
            push @{$forks{music}}, scalar fork();
            if ($forks{music}[-1] == 0) {
                exec "mpv $ENV{HOME}/*.mp3";
            }
        }
        when ('<s> STOP MUSIC </s>') {
            say "Stoping music...";
            if (ref $forks{music} eq 'ARRAY' and @{$forks{music}} > 0) {
                kill 1, $forks{music}[-1];
                pop @{$forks{music}};
            }
        }
        when ('<s> RUN TERM </s>') {
            say "Opening the terminal...";
        }
        when ('<s> RUN EDITOR </s>') {
            say "Running editor...";
        }
        when ('<s> PRESS ENTER </s>') {
            print "\n";
        }
        default {
            warn "WARN: Invalid command `$command'!\n";
        }
    }
}

my @buffer;
while (<$pipe_h>) {

    if (!/\S/) {
        my %conf;
        foreach my $line (@buffer) {
            if ($line =~ /^(\w+):\h*(.*\S)/) {
                $conf{$1} = $2;
            }
        }

        if (exists $conf{cmscore1} and exists $conf{sentence1}) {
            my @vals = split(' ', $conf{cmscore1});
            say "got: $conf{sentence1} ($conf{cmscore1})";

            # 'cmscore1' should be: 1.000 1.000 1.000 1.000 (with minor tolerance)
            if (sum(@vals) >= scalar(@vals) - 0.300) {
                take_action($conf{sentence1});
            }
        }

        $#buffer = -1;
    }

    push @buffer, $_;
}

__END__
pass1_best: <s> START MUSIC
pass1_best_wordseq: 0 2 3
pass1_best_phonemeseq: sil | y ah ng | w ah n
pass1_best_score: -4008.542480
### Recognition: 2nd pass (RL heuristic best-first)
STAT: 00 _default: 7 generated, 7 pushed, 5 nodes popped in 100
sentence1: <s> START MUSIC </s>
wseq1: 0 2 3 1
phseq1: sil | y ah ng | w ah n | sil
cmscore1: 1.000 1.000 1.000 1.000
score1: -11499.305664
