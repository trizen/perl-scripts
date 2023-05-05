#!/usr/bin/perl

# Author: Trizen
# Date: 27 April 2023
# https://github.com/trizen

# Solver for the asciiplanes game.

use utf8;
use 5.036;

use Text::ASCIITable;
use List::Util qw(any all shuffle max sum zip);

binmode(STDOUT, ':utf8');

## Package variables
my $pkgname = 'asciiplanes-player';
my $version = 0.01;

## Game run-time constants
my $BOARD_SIZE = 8;
my $PLANES_NUM = 3;

use constant {
              AIR   => '`',
              BLANK => ' ',
              HIT   => 'O',
              HEAD  => 'X',
             };

my %score_table = (
                   air  => AIR,
                   head => HEAD,
                   hit  => HIT,
                  );

my $wrap_plane = 0;
my $simulate   = 0;
my $hit_char   = HIT;
my $miss_char  = AIR;
my $head_char  = HEAD;
my $seed       = 0;
my $use_colors = eval { require Term::ANSIColor; 1; };

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
        --colors!   : use ANSI colors (requires Term::ANSIColor) (default: $use_colors);
        --simulate! : run a random simulation (default: $simulate)
        --seed=i    : run with a given pseudorandom seed value > 0 (default: $seed)

help:
        --help      : print this message and exit
        --version   : print the version number and exit
        --debug     : print some information useful in debugging

example:
        $0 --size=12 --planes=6 --hit='*'

EOT

    exit;
}

sub version {
    print "$pkgname $version\n";
    exit;
}

if (@ARGV) {
    require Getopt::Long;
    Getopt::Long::GetOptions(
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
                             'version|v|V'       => \&version,
                            )
      or die("$0: error in command line arguments!\n");
}

if ($seed) {
    srand($seed);
}

sub pointers ($board, $x, $y, $indices) {
    map {
        my ($row, $col) = ($x + $_->[0], $y + $_->[1]);

        if ($wrap_plane) {
            $row %= $BOARD_SIZE;
            $col %= $BOARD_SIZE;
        }

        $row < $BOARD_SIZE or return;
        $col < $BOARD_SIZE or return;

        $row >= 0 or return;
        $col >= 0 or return;

        \$board->[$row][$col]
    } @$indices;
}

#<<<
my $UP =
    [
                  [+0, +0],
        [+1, -1], [+1, +0], [+1, +1],
                  [+2, +0],
        [+3, -1], [+3, +0], [+3, +1],
    ];
#>>>

#<<<
my $DOWN =
    [
        [-3, -1], [-3, +0], [-3, +1],
                  [-2, +0],
        [-1, -1], [-1, +0], [-1, +1],
                  [+0, +0],
    ];
#>>>

#<<<
my $LEFT =
    [
                  [-1, +1],           [-1, +3],
        [+0, +0], [+0, +1], [+0, +2], [+0, +3],
                  [+1, +1],           [+1, +3],
    ];
#>>>

#<<<
my $RIGHT =
    [
        [-1, -3],           [-1, -1],
        [+0, -3], [+0, -2], [+0, -1], [+0, +0],
        [+1, -3],           [+1, -1],
    ];
#>>>

my @DIRECTIONS = ($UP, $DOWN, $LEFT, $RIGHT);
my @PAIR_INDICES = (
    map {
        my $i = $_;
        map { [$i, $_] } 0 .. $BOARD_SIZE - 1
      } 0 .. $BOARD_SIZE - 1
);

sub assign ($board, $dir, $x, $y, $force = 0) {

    (my @plane = pointers($board, $x, $y, $dir)) || return;

    if (not $force) {
        foreach my $point (@plane) {
            $$point eq BLANK or return;
        }
    }

    foreach my $c (@plane) {
        $$c = HIT;
    }

    $board->[$x][$y] = HEAD;
    return 1;
}

sub print_ascii_table (@boards) {

    my @ascii_tables;

    foreach my $board (@boards) {

        my $table = Text::ASCIITable->new({headingText => "$pkgname $version"});
        $table->setCols(' ', 1 .. $BOARD_SIZE);

        my $char = 'a';
        foreach my $row (@$board) {
            $table->addRow([$char++, @{$row}]);
            $table->addRowLine();
        }

        my $t = $table->drawit;

        if ($use_colors) {
            my $hit_color  = Term::ANSIColor::colored($hit_char,  "bold red");
            my $miss_color = Term::ANSIColor::colored($miss_char, "yellow");
            my $head_color = Term::ANSIColor::colored($head_char, "bold green");

            $t =~ s{\Q${\(HIT)}\E}{$hit_color}g;
            $t =~ s{\Q${\(AIR)}\E}{$miss_color}g;
            $t =~ s{\Q${\(HEAD)}\E}{$head_color}g;
        }

        push @ascii_tables, [split(/\n/, $t)];
    }

    foreach my $row (zip(@ascii_tables)) {
        say join('  ', @$row);
    }
}

sub valid_assignment ($play_board, $info_board, $extra = 0) {

    foreach my $i (0 .. $#{$play_board}) {
        foreach my $j (0 .. $#{$play_board->[$i]}) {

            my $play = $play_board->[$i][$j];
            my $info = $info_board->[$i][$j];

            if ($info eq AIR) {
                if ($play ne BLANK) {
                    return 0;
                }
            }
            elsif ($extra) {
                $info eq BLANK and next;
                $info eq $play or return 0;
            }
        }
    }

    return 1;
}

sub create_planes ($play_board) {

    my $count     = 0;
    my $max_tries = $BOARD_SIZE**4;

    while ($count != $PLANES_NUM) {

        my $x = int rand($BOARD_SIZE);
        my $y = int rand($BOARD_SIZE);

        my $dir = $DIRECTIONS[rand @DIRECTIONS];

        if (--$max_tries <= 0) {
            die "FATAL ERROR: try to increase the size of the grid (--size=x).\n";
        }

        assign($play_board, $dir, $x, $y) || next;
        ++$count;
    }

    return 1;
}

sub guess ($info_board, $play_board, $plane_count) {

    my $count     = 0;
    my $max_tries = $BOARD_SIZE * $BOARD_SIZE;
    my @indices   = shuffle(@PAIR_INDICES);

    while ($count != ($PLANES_NUM - $plane_count)) {

        my ($x, $y) = @{pop(@indices) // return};

        while (1) {
            if (    $play_board->[$x][$y] eq BLANK
                and $info_board->[$x][$y] eq BLANK) {
                last;
            }
            ($x, $y) = @{pop(@indices) // return};
        }

        if (--$max_tries <= 0) {
            return;
        }

        my @good_directions = grep {
            my @plane = pointers($info_board, $x, $y, $_);
            @plane and all { $$_ ne AIR } @plane;
        } @DIRECTIONS;

        next if not any { assign($play_board, $_, $x, $y) } shuffle(@good_directions);

        ++$count;
    }

    return 1;
}

sub get_head_positions ($board) {

    my @headshots;

    foreach my $i (0 .. $#{$board}) {
        foreach my $j (0 .. $#{$board->[$i]}) {
            if ($board->[$i][$j] eq HEAD) {
                push @headshots, [$i, $j];
            }
        }
    }

    return @headshots;
}

sub make_play_board {
    [map { [(BLANK) x $BOARD_SIZE] } 1 .. $BOARD_SIZE];
}

sub clone_board ($board) {
    [map { [@$_] } @$board];
}

sub make_play_boards ($info_board) {

    my @headshots = get_head_positions($info_board);
    my @boards    = ([make_play_board(), 0]);

    foreach my $pos (@headshots) {
        foreach my $dir (@DIRECTIONS) {
            foreach my $board (map { [clone_board($_->[0]), $_->[1]] } @boards) {
                assign($board->[0], $dir, $pos->[0], $pos->[1]) || next;
                push @boards, [$board->[0], $board->[1] + 1];
            }
        }
    }

    my $max_count = max(map { $_->[1] } @boards);
    grep { valid_assignment($_->[0], $info_board) } grep { $_->[1] == $max_count } @boards;
}

sub get_letters {

    my %letters;
    my $char = 'a';

    foreach my $i (0 .. $BOARD_SIZE - 1) {
        $letters{$char++} = $i;
    }

    return %letters;
}

sub solve ($callback) {

    my $tries      = 0;
    my $info_board = make_play_board();
    my @boards     = make_play_boards($info_board);

    while (1) {
        foreach my $board_entry (@boards) {
            my ($board, $plane_count) = @$board_entry;

            my $play_board = clone_board($board);
            guess($info_board, $play_board, $plane_count) || next;
            valid_assignment($play_board, $info_board, 1) || next;

            # Prefer points nearest to the center of the board
            my @head_pos = (
                map { $_->[0] } sort { $a->[1] <=> $b->[1] } map {
                    [$_, sum(map { (($BOARD_SIZE - 1) / 2 - $_)**2 } @$_)]
                } get_head_positions($play_board)
            );

#<<<
            @head_pos = (
                map {
                    my ($x, $y) = @$_;
                    [$x, $y, [
                        grep { @$_ and all { $$_ ne AIR } @$_ }
                        map  { [pointers($info_board, $x, $y, $_)] } @DIRECTIONS
                    ]]
                } grep { $info_board->[$_->[0]][$_->[1]] eq BLANK } @head_pos
            );
#>>>

#<<<
            # Prefer the planes with the most hits
            @head_pos = (
                  map  { $_->[0] }
                  sort { $b->[1] <=> $a->[1] }
                  map  {
                    [$_, sum(map { scalar grep { $$_ eq HIT } @$_ } @{$_->[2]})]
                  } @head_pos
            );
#>>>

            my $all_dead = 1;
            my $new_info = 0;

            foreach my $pos (@head_pos) {

                my ($i, $j) = @$pos;

                if ($info_board->[$i][$j] ne BLANK) {
                    next;
                }

                $all_dead = 0;
                my $score = $callback->($i, $j, $play_board, $info_board) // return;

                if ($score eq BLANK) {
                    $score = AIR;
                }

                ++$tries;
                $info_board->[$i][$j] = $score;

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

            if ($all_dead) {
                return $tries;
            }

            last if $new_info;
        }
    }
}

my %letters2indices = get_letters();
my %indices2letters = map { ($letters2indices{$_}, $_) } keys %letters2indices;

sub process_user_input ($i, $j, $play_board, $info_board) {

    require Term::ReadLine;
    my $term = Term::ReadLine->new("ASCII Planes Player");

    print_ascii_table($play_board, $info_board);

    while (1) {
        say "=> My guess: " . join('', $indices2letters{$i}, $j + 1);
        say "=> Score (hit, head or air)";

        my $input = lc($term->readline("> ") // return);

        if ($input eq 'q' or $input eq 'quit') {
            return;
        }

        $input =~ s/^\s+//;
        $input =~ s/\s+\z//;

        if (not exists $score_table{$input}) {
            say "\n:: Invalid score...\n";
            next;
        }

        return $score_table{$input};
    }
}

if ($simulate) {

    my $board = make_play_board();
    create_planes($board);

    my $tries = solve(
        sub ($i, $j, $play_board, $info_board) {
            print_ascii_table($play_board, $info_board);
            $board->[$i][$j];
        }
    );

    say "It took $tries tries to solve:";
    print_ascii_table($board);
}
else {
    my $tries = solve(\&process_user_input);
    if (defined($tries)) {
        say "\n:: All planes destroyed in $tries tries!\n";
    }
}
