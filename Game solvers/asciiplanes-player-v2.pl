#!/usr/bin/perl

# Author: Trizen
# Date: 27 April 2023
# https://github.com/trizen

# Solver for the asciiplanes game.
#
# The solver maintains an "info board" recording what the opponent has told us
# (air/hit/head) and a "play board" representing the solver's current hypothesis
# about where the remaining planes are.  Each turn it picks the best cell to
# probe, asks the opponent (or the simulator) for a score, updates both boards,
# and repeats until all planes are destroyed.

use utf8;
use 5.036;

use Text::ASCIITable;
use Getopt::Long qw(GetOptions);
use List::Util   qw(any all shuffle max sum zip);

binmode(STDOUT, ':utf8');

## Package variables
my $pkgname = 'asciiplanes-player';
my $version = 0.02;

use constant {
              AIR   => '`',    # cell that is known to be empty sky
              BLANK => ' ',    # cell not yet probed / not yet placed
              HIT   => 'O',    # cell that is part of a plane body
              HEAD  => 'X',    # cell that is the nose (head) of a plane
             };

my %score_table = (
                   air  => AIR,
                   head => HEAD,
                   hit  => HIT,
                  );

# ---------------------------------------------------------------------------
# Runtime configuration (may be overridden by command-line options)
# ---------------------------------------------------------------------------

my $BOARD_SIZE = 8;
my $PLANES_NUM = 3;
my $wrap_plane = 0;
my $simulate   = 0;
my $hit_char   = HIT;
my $miss_char  = AIR;
my $head_char  = HEAD;
my $seed       = 0;
my $use_colors = eval { require Term::ANSIColor; 1; };

## CLI Argument Parsing
if (@ARGV) {
    GetOptions(
               'board-size|size=i' => \$BOARD_SIZE,
               'planes-num=i'      => \$PLANES_NUM,
               'head-char=s'       => \$head_char,
               'hit-char=s'        => \$hit_char,
               'miss-char=s'       => \$miss_char,
               'wrap!'             => \$wrap_plane,
               'simulate!'         => \$simulate,
               'colors!'           => \$use_colors,
               'seed=i'            => \$seed,
               'help|h|?'          => \&usage,
               'version|v'         => \&version,
              )
      or die("$0: error in command line arguments!\n");
}

srand($seed) if $seed;

## Plane Direction Shapes (Coordinate Offsets)
my @DIRECTIONS = (

    # UP
    [[0, 0], [1, -1], [1, 0], [1, 1], [2, 0], [3, -1], [3, 0], [3, 1]],

    # DOWN
    [[-3, -1], [-3, 0], [-3, 1], [-2, 0], [-1, -1], [-1, 0], [-1, 1], [0, 0]],

    # LEFT
    [[-1, 1], [-1, 3], [0, 0], [0, 1], [0, 2], [0, 3], [1, 1], [1, 3]],

    # RIGHT
    [[-1, -3], [-1, -1], [0, -3], [0, -2], [0, -1], [0, 0], [1, -3], [1, -1]]
);

my $TOTAL_CELLS = $BOARD_SIZE * $BOARD_SIZE;

## Mapping Utilities
my %letters2indices;
my %indices2letters;
{
    my $char = 'a';
    for my $i (0 .. $BOARD_SIZE - 1) {
        $letters2indices{$char} = $i;
        $indices2letters{$i}    = $char;
        $char++;
    }
}

## --- Ahead-of-Time Precomputation ---
# Precompute valid plane indices for every cell and direction.
# $PRECOMPUTED_PLANES->[$pos][$dir] = [ idx1, idx2, ... ] or undef

my $PRECOMPUTED_PLANES = [];

sub init_planes {
    for my $x (0 .. $BOARD_SIZE - 1) {
        for my $y (0 .. $BOARD_SIZE - 1) {
            my $pos = $x * $BOARD_SIZE + $y;

            for my $dir (0 .. $#DIRECTIONS) {
                my @indices;
                my $valid = 1;

                for my $offset (@{$DIRECTIONS[$dir]}) {
                    my $nx = $x + $offset->[0];
                    my $ny = $y + $offset->[1];

                    if ($wrap_plane) {
                        $nx %= $BOARD_SIZE;
                        $ny %= $BOARD_SIZE;
                    }
                    elsif ($nx < 0 || $nx >= $BOARD_SIZE || $ny < 0 || $ny >= $BOARD_SIZE) {
                        $valid = 0;
                        last;
                    }
                    push @indices, $nx * $BOARD_SIZE + $ny;
                }
                $PRECOMPUTED_PLANES->[$pos][$dir] = $valid ? \@indices : undef;
            }
        }
    }
}

init_planes();

## --- Core Game Logic (1D Arrays) ---

sub make_play_board {
    return [(BLANK) x $TOTAL_CELLS];
}

sub assign ($board, $pos, $dir, $force = 0) {
    my $indices = $PRECOMPUTED_PLANES->[$pos][$dir] or return;

    if (!$force) {
        for my $idx (@$indices) {
            return unless $board->[$idx] eq BLANK;
        }
    }

    $board->[$_]   = HIT for @$indices;
    $board->[$pos] = HEAD;
    return 1;
}

sub valid_assignment ($play_board, $info_board, $extra = 0) {
    for my $i (0 .. $TOTAL_CELLS - 1) {
        my $info = $info_board->[$i];
        if ($info eq AIR) {
            return 0 if $play_board->[$i] ne BLANK;
        }
        elsif ($extra && $info ne BLANK) {
            return 0 if $info ne $play_board->[$i];
        }
    }
    return 1;
}

sub create_planes ($play_board) {
    my $count     = 0;
    my $max_tries = $BOARD_SIZE**4;

    while ($count != $PLANES_NUM) {
        die "FATAL ERROR: try to increase the size of the grid (--size=x).\n" if --$max_tries <= 0;

        my $pos = int rand($TOTAL_CELLS);
        my $dir = int rand(4);
        ++$count if assign($play_board, $pos, $dir);
    }
    return 1;
}

sub guess ($info_board, $play_board, $plane_count) {
    my $count     = 0;
    my $max_tries = $TOTAL_CELLS;
    my @indices   = shuffle(0 .. $TOTAL_CELLS - 1);

    while ($count != ($PLANES_NUM - $plane_count)) {
        my $pos;
        while (@indices) {
            $pos = pop @indices;
            last if $play_board->[$pos] eq BLANK && $info_board->[$pos] eq BLANK;
            undef $pos;
        }
        return unless defined $pos;
        return if --$max_tries <= 0;

        my @good_dirs;
        for my $dir (0 .. 3) {
            my $indices = $PRECOMPUTED_PLANES->[$pos][$dir];
            push @good_dirs, $dir if $indices && all { $info_board->[$_] ne AIR } @$indices;
        }

        ++$count if any { assign($play_board, $pos, $_) } shuffle(@good_dirs);
    }
    return 1;
}

sub get_head_positions ($board) {
    my @headshots;
    push @headshots, $_ for grep { $board->[$_] eq HEAD } 0 .. $TOTAL_CELLS - 1;
    return @headshots;
}

sub make_play_boards ($info_board) {
    my @headshots = get_head_positions($info_board);
    my @boards    = ([make_play_board(), 0]);

    for my $pos (@headshots) {
        for my $dir (0 .. 3) {
            for my $board_entry (map { [[@{$_->[0]}], $_->[1]] } @boards) {
                next unless assign($board_entry->[0], $pos, $dir);
                push @boards, [$board_entry->[0], $board_entry->[1] + 1];
            }
        }
    }

    my $max_count = max(0, map { $_->[1] } @boards);
    return grep { valid_assignment($_->[0], $info_board) }
      grep { $_->[1] == $max_count } @boards;
}

## --- Solver Heuristics ---

sub _sort_by_center_distance (@positions) {
    my $center = ($BOARD_SIZE - 1) / 2;
    return map { $_->[0] }
      sort { $a->[1] <=> $b->[1] }
      map {
        my $x = int($_ / $BOARD_SIZE);
        my $y = $_ % $BOARD_SIZE;
        [$_, ($center - $x)**2 + ($center - $y)**2]
      } @positions;
}

sub _score_and_sort_by_hits ($info_board, @positions) {
    my @scored;

    for my $pos (@positions) {
        next unless $info_board->[$pos] eq BLANK;

        my @valid_planes;
        for my $dir (0 .. 3) {
            my $indices = $PRECOMPUTED_PLANES->[$pos][$dir];
            push @valid_planes, $indices if $indices && all { $info_board->[$_] ne AIR } @$indices;
        }

        if (@valid_planes) {
            my $hits = sum(
                0,
                map {
                    scalar grep { $info_board->[$_] eq HIT } @$_
                  } @valid_planes
            );
            push @scored, [$pos, $hits];
        }
    }

    return map { $_->[0] } sort { $b->[1] <=> $a->[1] } @scored;
}

sub solve ($callback) {
    my $tries      = 0;
    my $info_board = make_play_board();
    my @boards     = make_play_boards($info_board);

    while (1) {
        for my $board_entry (@boards) {
            my ($board, $plane_count) = @$board_entry;
            my $play_board = [@$board];    # Native ultra-fast shallow copy

            next unless guess($info_board, $play_board, $plane_count);
            next unless valid_assignment($play_board, $info_board, 1);

            my @head_pos = _sort_by_center_distance(get_head_positions($play_board));
            @head_pos = _score_and_sort_by_hits($info_board, @head_pos);

            my $all_dead = 1;
            my $new_info = 0;

            for my $pos (@head_pos) {
                next if $info_board->[$pos] ne BLANK;

                $all_dead = 0;
                my $score = $callback->($pos, $play_board, $info_board) // return;
                $score = AIR if $score eq BLANK;

                ++$tries;
                $info_board->[$pos] = $score;

                if ($score eq HEAD) {
                    $new_info = 1;
                    @boards   = make_play_boards($info_board);
                    next;
                }
                elsif ($score eq AIR) {
                    $new_info = 1;
                    @boards   = reverse(grep { valid_assignment($_->[0], $info_board) } @boards);
                }
                last;
            }

            return $tries if $all_dead;
            last          if $new_info;
        }
    }
}

## --- IO and Main Execution ---

sub print_ascii_table (@boards) {
    my @ascii_tables;

    for my $board (@boards) {
        my $table = Text::ASCIITable->new({headingText => "$pkgname $version"});
        $table->setCols(' ', 1 .. $BOARD_SIZE);

        my $char = 'a';
        for my $x (0 .. $BOARD_SIZE - 1) {

            # Extract 2D row from 1D board
            my @row = @{$board}[$x * $BOARD_SIZE .. ($x + 1) * $BOARD_SIZE - 1];
            $table->addRow([$char++, @row]);
            $table->addRowLine();
        }

        my $t = $table->drawit;

        if ($use_colors) {
            my $hit_color  = Term::ANSIColor::colored($hit_char,  "bold red");
            my $miss_color = Term::ANSIColor::colored($miss_char, "yellow");
            my $head_color = Term::ANSIColor::colored($head_char, "bold green");

            $t =~ s{\Q$hit_char\E}{$hit_color}g;
            $t =~ s{\Q$miss_char\E}{$miss_color}g;
            $t =~ s{\Q$head_char\E}{$head_color}g;
        }

        push @ascii_tables, [split(/\n/, $t)];
    }

    for my $row (zip(@ascii_tables)) {
        say join('  ', @$row);
    }
}

sub process_user_input ($pos, $play_board, $info_board) {

    require Term::ReadLine;
    state $term = Term::ReadLine->new("ASCII Planes Player");

    my $i = int($pos / $BOARD_SIZE);
    my $j = $pos % $BOARD_SIZE;

    print_ascii_table($play_board, $info_board);

    while (1) {
        say "=> My guess: " . join('', $indices2letters{$i}, $j + 1);
        say "=> Score (hit, head or air)";

        my $input = lc($term->readline("> ") // return);
        return if $input eq 'q' or $input eq 'quit';

        $input =~ s/^\s+|\s+\z//g;

        unless (exists $score_table{$input}) {
            say "\n:: Invalid score...\n";
            next;
        }
        return $score_table{$input};
    }
}

sub usage {
    print <<"EOT";
usage: $0 [options]

main:
        --size=i    : length side of the board (default: $BOARD_SIZE)
        --planes=i  : the total number of planes (default: $PLANES_NUM)
        --wrap!     : wrap the plane around the play board (default: $wrap_plane)
        --head=s    : character used for the head of the plane (default: "$head_char")
        --hit=s     : character used when a plane is hit (default: "$hit_char")
        --miss=s    : character used when a plane is missed (default: "$miss_char")
        --colors!   : use ANSI colors (requires Term::ANSIColor) (default: $use_colors)
        --simulate! : run a random simulation (default: $simulate)
        --seed=i    : run with a given pseudorandom seed value > 0 (default: $seed)

help:
        --help      : print this message and exit
        --version   : print the version number and exit

example:
        $0 --size=12 --planes=6 --hit='*'

EOT
    exit;
}

sub version {
    print "$pkgname $version\n";
    exit;
}

if ($simulate) {

    # Simulation mode: place planes randomly, then let the solver probe them.
    my $board = make_play_board();
    create_planes($board);

    my $tries = solve(
        sub ($pos, $play_board, $info_board) {
            print_ascii_table($play_board, $info_board);
            $board->[$pos];
        }
    );

    say "It took $tries tries to solve:";
    print_ascii_table($board);
}
else {
    # Interactive mode: ask the human to score each probe.
    my $tries = solve(\&process_user_input);
    say "\n:: All planes destroyed in $tries tries!\n" if defined($tries);
}
