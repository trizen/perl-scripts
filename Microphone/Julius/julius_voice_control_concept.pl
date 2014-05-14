#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 08 April 2014
# Website: http://github.com/trizen

# Voice control - take actions based on vocal commands
# This script depends on the 'julius', which also needs
# an acoustic model for the English language.
# An open-source acoustic model can be downloaded from:
#    http://www.voxforge.org/home/downloads

# Configuration files: https://github.com/trizen/config-files/tree/master/.voxforge/julius

use utf8;
use 5.010;
use strict;
use warnings;
use List::Util qw(sum);

no if $] >= 5.018, warnings => 'experimental';

my $config = "$ENV{HOME}/.voxforge/julius/perl.jconf";
my @julius = qw(julius -input mic);

open(my $pipe_h, '-|', @julius, '-C', $config) // exit $!;

sub take_action {
    my ($command) = @_;

    given ($command) {
        when ('<s> START MUSIC </s>') {
            say "Starting music...";
        }
        when ('<s> START TERM </s>') {
            say "Opening the terminal...";
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
            if (sum(@vals) == @vals) {    # 'cmscore1' must be: 1.000 1.000 1.000 1.000
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

#################################
## __VOCA_FILE__ (perl.voca)
#################################
% NS_B
<s>        sil

% NS_E
</s>        sil

% CMD
START      y ah ng

% THING
MUSIC     w ah n
TERM      s eh v ax n

######################################
## __GRAMMAR_FILE__ (perl.grammar)
######################################
S : NS_B CMD THING_LOOP NS_E
THING_LOOP: THING_LOOP THING
THING_LOOP: THING
