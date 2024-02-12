#!/usr/bin/perl

# Author: Trizen
# Date: 12 February 2024
# https://github.com/trizen

# Solve Sudoku puzzle (iterative solution), if it has a unique solution.

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

sub solve_sudoku_backtracking ($board) {    # used as fallback

    my @empty_locations = find_empty_locations($board);

    if (not @empty_locations) {
        return 1;    # Puzzle is solved
    }

    my ($row, $col) = @{shift(@empty_locations)};

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

    my $prev_len = 0;

    while (1) {
        (my @empty_locations = find_empty_locations($board)) || last;

        if (scalar(@empty_locations) == $prev_len) {
            if (solve_sudoku_backtracking($board)) {
                return $board;
            }
            return undef;
        }

        foreach my $ij (@empty_locations) {
            my ($i,     $j)     = @$ij;
            my ($count, $value) = (0, 0);
            foreach my $n (1 .. 9) {
                is_valid($board, $i, $j, $n) || next;
                last if (++$count > 1);
                $value = $n;
            }
            $board->[$i][$j] = $value if ($count == 1);
        }

        $prev_len = scalar(@empty_locations);
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
