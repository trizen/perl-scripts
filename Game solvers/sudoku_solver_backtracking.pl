#!/usr/bin/perl

# Solve Sudoku puzzle (recursive solution).

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

sub solve_sudoku ($board) {
    my ($row, $col) = find_empty_location($board);

    if (!defined($row) && !defined($col)) {
        return 1;    # Puzzle is solved
    }

    foreach my $num (1 .. 9) {
        if (is_valid($board, $row, $col, $num)) {

            # Try placing the number
            $board->[$row][$col] = $num;

            # Recursively try to solve the rest of the puzzle
            if (solve_sudoku($board)) {
                return 1;
            }

            # If placing the current number doesn't lead to a solution, backtrack
            $board->[$row][$col] = 0;
        }
    }

    return 0;    # No solution found
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

if (solve_sudoku($sudoku_board)) {
    display_grid([map { @$_ } @$sudoku_board]);
}
else {
    say "No solution exists.";
}
