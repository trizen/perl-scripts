#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 30 January 2017
# Edit: 20 December 2021
# https://github.com/trizen

# Recursive brute-force Sudoku generator and solver.

# See also:
#   https://en.wikipedia.org/wiki/Sudoku

use 5.020;
use strict;

use List::Util qw(shuffle);
use experimental qw(signatures);

sub check ($i, $j) {

    use integer;

    my ($id, $im) = ($i / 9, $i % 9);
    my ($jd, $jm) = ($j / 9, $j % 9);

    $jd == $id && return 1;
    $jm == $im && return 1;

        $id / 3 == $jd / 3
    and $jm / 3 == $im / 3;
}

my @lookup;
foreach my $i (0 .. 80) {
    foreach my $j (0 .. 80) {
        $lookup[$i][$j] = check($i, $j);
    }
}

sub solve_sudoku ($callback, $grid) {

    sub {
        foreach my $i (0 .. 80) {
            if (!$grid->[$i]) {

                my %t;
                undef @t{@{$grid}[grep { $lookup[$i][$_] } 0 .. 80]};

                foreach my $k (shuffle(1 .. 9)) {
                    if (!exists $t{$k}) {
                        $grid->[$i] = $k;
                        __SUB__->();
                        $grid->[$i] = 0;
                    }
                }

                return;
            }
        }

        $callback->(@$grid);
      }
      ->();
}

sub generate_sudoku ($known, $solution_count = 1) {

    my @grid = (0) x 81;

    eval {
        solve_sudoku(
            sub {
                my (@solution) = @_;

                my %table;
                @table{(shuffle(0 .. $#solution))[0 .. $known - 1]} = ();

                my @candidate = map { exists($table{$_}) ? $solution[$_] : 0 } 0 .. $#solution;

                my $res = eval {
                    my $count = 0;
                    solve_sudoku(sub { die "error" if (++$count > $solution_count) }, [@candidate]);
                    $count;
                };

                if (defined($res) and $res == $solution_count) {
                    @grid = @candidate;
                    die "found";
                }
            },
            \@grid
                    );
    };

    return @grid;
}

sub display_grid_as_ascii_table {
    my (@grid) = @_;

    my $t = Text::ASCIITable->new();
    $t->setCols(map { '1 2 3' } 1 .. 3);
    $t->setOptions({hide_HeadLine => 1, hide_HeadRow => 1});

    my @collect;

    foreach my $i (0 .. $#grid) {

        push @collect, $grid[$i] ? $grid[$i] : '0';

        if (($i + 1) % 9 == 0) {
            my @row = splice(@collect);

            my @chunks;
            while (@row) {
                push @chunks, join ' ', splice(@row, 0, 3);
            }

            $t->addRow(@chunks);
        }

        if (($i + 1) % 27 == 0) {
            $t->addRowLine();
        }
    }

    print $t;
}

sub display_grid {
    my (@grid) = @_;

    my $has_ascii_table = eval { require Text::ASCIITable; 1 };

    if ($has_ascii_table) {
        return display_grid_as_ascii_table(@grid);
    }

    foreach my $i (0 .. $#grid) {
        print "$grid[$i] ";
        print " "  if ($i + 1) % 3 == 0;
        print "\n" if ($i + 1) % 9 == 0;
        print "\n" if ($i + 1) % 27 == 0;
    }
}

my $known          = 35;    # number of known entries
my $solution_count = 1;     # number of solutions the puzzle must have

my @sudoku = generate_sudoku($known, $solution_count);

say "\n:: Random Sudoku with $known known entries:\n";

display_grid(@sudoku);

say "\n:: Solution(s):\n";

solve_sudoku(
    sub {
        my (@solution) = @_;
        display_grid(@solution);
    },
    \@sudoku
            );

__END__

:: Random Sudoku with 35 known entries:

.-----------------------.
| 8 9 0 | 6 4 5 | 2 0 3 |
| 7 4 0 | 8 0 0 | 9 0 0 |
| 0 0 5 | 0 3 0 | 8 1 4 |
+-------+-------+-------+
| 3 0 0 | 0 0 9 | 0 0 1 |
| 0 1 2 | 4 7 0 | 5 0 8 |
| 0 8 0 | 0 0 0 | 4 3 0 |
+-------+-------+-------+
| 1 0 0 | 0 6 0 | 3 0 0 |
| 0 0 0 | 0 0 0 | 0 0 5 |
| 0 0 0 | 0 5 4 | 7 0 0 |
'-------+-------+-------'

:: Solution(s):

.-----------------------.
| 8 9 1 | 6 4 5 | 2 7 3 |
| 7 4 3 | 8 2 1 | 9 5 6 |
| 2 6 5 | 9 3 7 | 8 1 4 |
+-------+-------+-------+
| 3 7 4 | 5 8 9 | 6 2 1 |
| 6 1 2 | 4 7 3 | 5 9 8 |
| 5 8 9 | 2 1 6 | 4 3 7 |
+-------+-------+-------+
| 1 5 8 | 7 6 2 | 3 4 9 |
| 4 2 7 | 3 9 8 | 1 6 5 |
| 9 3 6 | 1 5 4 | 7 8 2 |
'-------+-------+-------'
