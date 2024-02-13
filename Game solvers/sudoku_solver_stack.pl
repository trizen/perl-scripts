#!/usr/bin/perl

# Solve Sudoku puzzle (iterative solution // stack-based).

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

    my @stack = ($board);

    while (@stack) {

        my $current_board = pop @stack;
        my ($row, $col) = find_empty_location($current_board);

        if (!defined($row) && !defined($col)) {
            return $current_board;
        }

        foreach my $num (1 .. 9) {
            if (is_valid($current_board, $row, $col, $num)) {
                my @new_board = map { [@$_] } @$current_board;
                $new_board[$row][$col] = $num;
                push @stack, \@new_board;
            }
        }
    }

    return undef;
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
] if 0;

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
    say "No solution exists.";
}
