#!/usr/bin/perl

# Author: Trizen
# Date: 12 February 2024
# https://github.com/trizen

# Fast algorithm to solve the Sudoku puzzle (iterative solution).

use 5.036;

sub is_valid ($board, $row, $col, $num) {

    # Check if the number is not present in the current row and column
    foreach my $i (0 .. 8) {
        if (($board->[$row][$i] == $num) || ($board->[$i][$col] == $num)) {
            return 0;
        }
    }

    # Check if the number is not present in the current 3x3 subgrid
    my ($start_row, $start_col) = (3 * int($row / 3), 3 * int($col / 3));

    foreach my $i (0 .. 2) {
        foreach my $j (0 .. 2) {
            if ($board->[$start_row + $i][$start_col + $j] == $num) {
                return 0;
            }
        }
    }

    return 1;
}

sub find_empty_locations ($board) {

    my @locations;

    # Find all empty positions (cells with 0)
    foreach my $i (0 .. 8) {
        foreach my $j (0 .. 8) {
            if ($board->[$i][$j] == 0) {
                push @locations, [$i, $j];
            }
        }
    }

    return @locations;
}

sub find_empty_location ($board) {

    # Find an empty position (cell with 0)
    foreach my $i (0 .. 8) {
        foreach my $j (0 .. 8) {
            if ($board->[$i][$j] == 0) {
                return ($i, $j);
            }
        }
    }

    return (undef, undef);    # If the board is filled
}

sub solve_sudoku_fallback ($board) {    # fallback method

    my ($row, $col) = find_empty_location($board);

    if (!defined($row) && !defined($col)) {
        return 1;    # Puzzle is solved
    }

    foreach my $num (1 .. 9) {
        if (is_valid($board, $row, $col, $num)) {

            # Try placing the number
            $board->[$row][$col] = $num;

            # Recursively try to solve the rest of the puzzle
            if (__SUB__->($board)) {
                return 1;
            }

            # If placing the current number doesn't lead to a solution, backtrack
            $board->[$row][$col] = 0;
        }
    }

    return 0;    # No solution found
}

sub solve_sudoku ($board) {

    while (1) {
        (my @empty_locations = find_empty_locations($board)) || last;

        my $found = 0;

        # Solve easy cases
        foreach my $ij (@empty_locations) {
            my ($i,     $j)     = @$ij;
            my ($count, $value) = (0, 0);
            foreach my $n (1 .. 9) {
                is_valid($board, $i, $j, $n) || next;
                last if (++$count > 1);
                $value = $n;
            }
            if ($count == 1) {
                $board->[$i][$j] = $value;
                $found ||= 1;
            }
        }

        next if $found;

        # Solve more complex cases
        my @stats;
        foreach my $ij (@empty_locations) {
            my ($i, $j) = @$ij;
            $stats[$i][$j] = [grep { is_valid($board, $i, $j, $_) } 1 .. 9];
        }

        my (@rows, @cols, @subgrid);
        foreach my $ij (@empty_locations) {
            my ($i, $j) = @$ij;
            foreach my $v (@{$stats[$i][$j]}) {
                ++$cols[$j][$v];
                ++$rows[$i][$v];
                ++$subgrid[3 * int($i / 3)][3 * int($j / 3)][$v];
            }
        }

        foreach my $ij (@empty_locations) {
            my ($i, $j) = @$ij;
            foreach my $v (@{$stats[$i][$j]}) {
                if (   $cols[$j][$v] == 1
                    or $rows[$i][$v] == 1
                    or $subgrid[3 * int($i / 3)][3 * int($j / 3)][$v] == 1) {
                    $board->[$i][$j] = $v;
                    $found ||= 1;
                }
            }
        }

        next if $found;

        # Give up and try brute-force
        solve_sudoku_fallback($board);
        return $board;
    }

    return $board;
}

#<<<
# Example usage:
# Define the Sudoku puzzle as a 9x9 list with 0 representing empty cells
my $sudoku_board = [
        [2, 0, 0, 0, 7, 0, 0, 0, 3],
        [1, 0, 0, 0, 0, 0, 0, 8, 0],
        [0, 0, 4, 2, 0, 9, 0, 0, 5],
        [9, 4, 0, 0, 0, 0, 6, 0, 8],
        [0, 0, 0, 8, 0, 0, 0, 9, 0],
        [0, 0, 0, 0, 0, 0, 0, 7, 0],
        [7, 2, 1, 9, 0, 8, 0, 6, 0],
        [0, 3, 0, 0, 2, 7, 1, 0, 0],
        [4, 0, 0, 0, 0, 3, 0, 0, 0]
];

$sudoku_board = [
    [0, 0, 0, 8, 0, 1, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 4, 3],
    [5, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 7, 0, 8, 0, 0],
    [0, 0, 0, 0, 0, 0, 1, 0, 0],
    [0, 2, 0, 0, 3, 0, 0, 0, 0],
    [6, 0, 0, 0, 0, 0, 0, 7, 5],
    [0, 0, 3, 4, 0, 0, 0, 0, 0],
    [0, 0, 0, 2, 0, 0, 6, 0, 0]
] if 1;

$sudoku_board = [
    [8, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 3, 6, 0, 0, 0, 0, 0],
    [0, 7, 0, 0, 9, 0, 2, 0, 0],
    [0, 5, 0, 0, 0, 7, 0, 0, 0],
    [0, 0, 0, 0, 4, 5, 7, 0, 0],
    [0, 0, 0, 1, 0, 0, 0, 3, 0],
    [0, 0, 1, 0, 0, 0, 0, 6, 8],
    [0, 0, 8, 5, 0, 0, 0, 1, 0],
    [0, 9, 0, 0, 0, 0, 4, 0, 0]
] if 0;
#>>>

sub display_grid ($grid) {
    foreach my $i (0 .. $#$grid) {
        print "$grid->[$i] ";
        print " "  if ($i + 1) % 3 == 0;
        print "\n" if ($i + 1) % 9 == 0;
        print "\n" if ($i + 1) % 27 == 0;
    }
}

my $solution = solve_sudoku($sudoku_board);

if ($solution) {
    display_grid([map { @$_ } @$solution]);
}
else {
    warn "No unique solution exists!\n";
}
