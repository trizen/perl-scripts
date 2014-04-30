#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 30 June 2013
# Edit: 30 April 2014
# Website: http://github.com/trizen

# Sudoku dice game solver

use 5.010;
use strict;
use warnings;

use Time::HiRes qw(sleep);
use Term::ANSIColor qw(colored);
use List::Util qw(first shuffle);

sub valid_move {
    my ($row, $col, $table) = @_;

    if (($row < 0 or not exists $table->[$row]) || ($col < 0 or not exists $table->[$row][$col])) {
        return;
    }

    return 1;
}

{
    my @moves = (
                 {dir => 'left',  pos => [+0, -1]},
                 {dir => 'right', pos => [+0, +1]},
                 {dir => 'up',    pos => [-1, +0]},
                 {dir => 'down',  pos => [+1, +0]},
                );

    sub get_moves {
        my ($table, $row, $col, $number) = @_;

        my @next_pos;
        foreach my $move (@moves) {
            if (valid_move($row + $move->{pos}[0], $col + $move->{pos}[1], $table)) {
                if (    $table->[$row + $move->{pos}[0]][$col + $move->{pos}[1]] != 0
                    and $table->[$row + $move->{pos}[0]][$col + $move->{pos}[1]] == $number + 1) {
                    push @next_pos, $move;
                }
            }
        }

        return \@next_pos;
    }
}

my @steps;

sub init_universe {    # recursion at its best
    my ($table, $pos) = @_;
    my ($row,   $col) = @{$pos};

    my $number = $table->[$row][$col];
    $table->[$row][$col] = 1337;

    print "\e[H\e[J\e[H";
    foreach my $row (@{$table}) {
        say map {
                $_ == 1337 ? colored('[ ]', 'bold blue')
              : $_ == 0    ? colored(' * ', 'bold red')
              : colored(" $_ ", 'bold black')
        } @{$row};
    }
    sleep 0.05;

    $table->[$row][$col] = 0;

    if ($number == 0) {
        pop @steps;
        return $table;
    }

    $number = 0 if $number == 3;
    my $moves = get_moves($table, $row, $col, $number);

    if (@{$moves}) {
        foreach my $move (@{$moves}) {
            push @steps, $move;

            my $universe = init_universe([map { [@{$_}] } @{$table}], [$row + $move->{pos}[0], $col + $move->{pos}[1]]);

            if (
                not first {
                    first { $_ != 0 } @{$_};
                }
                @{$universe}
              ) {
                die "solved\n";
            }
        }

        return init_universe($table, [$row, $col]);
    }
    else {
        pop @steps;
        return $table;
    }
}

#
## MAIN
#

{
    my @rows = qw(
      321321313
      123312222
      321213131
      312231123
      213112321
      231323123
      132231231
      123113322
      321322113
      );

    my @table;
    foreach my $row (@rows) {
        push @table, [split //, $row];
    }

    my @positions;
    foreach my $i (0 .. $#table) {
        foreach my $j (0 .. $#{$table[$i]}) {
            if ($table[$i][$j] == 1) {
                push @positions, [$i, $j];
            }
        }
    }

    foreach my $pos (shuffle @positions) {    # tested solution from position[6]

        eval {
            init_universe([map { [@{$_}] } @table], $pos);
        };

        if ($@ eq "solved\n") {

            printf "** Locate row %d, column %d, click on it and follow the steps:\n", ($pos->[0] + 1, $pos->[1] + 1);

            my $i         = 1;
            my $count     = 1;
            my $prev_step = (shift @steps)->{dir};

            foreach my $step (@steps) {
                if ($step->{dir} eq $prev_step) {
                    ++$count;
                }
                else {
                    printf "%2d. Go %-8s%s", $i++, $prev_step, ($count == 1 ? "\n" : "($count times)\n");
                    $count     = 1;
                    $prev_step = $step->{dir};
                }
            }

            sleep 2;
            print "\n";
            @steps = ();
        }
    }
}
