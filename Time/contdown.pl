#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use Time::Piece;
use Time::Seconds;

sub _div {
    my $quot = $_[0] / $_[1];
    my $int  = int($quot);
    $int > $quot ? $int - 1 : $int;
}

sub leap_year {
    my ($y) = @_;
    (($y % 4 == 0) and ($y % 400 == 0 or $y % 100 != 0)) || 0;
}

{
    #<<<
    my @days_in_month = (
                         [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31],
                         [0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31],
                        );
    #>>>

    sub days_in_month ($$) {
        my ($y, $m) = @_;
        $days_in_month[leap_year($y)][$m];
    }
}

sub ymd_to_days {
    my ($Y, $M, $D) = @_;

    if (   $M < 1
        || $M > 12
        || $D < 1
        || ($D > 28 && $D > days_in_month($Y, $M))) {
        return undef;
    }

    my $x = ($M <= 2 ? $Y - 1 : $Y);
    my $days = $D + (undef, -1, 30, 58, 89, 119, 150, 180, 211, 242, 272, 303, 333)[$M];

    $days += 365 * ($Y - 1970);
    $days += _div(($x - 1968), 4);
    $days -= _div(($x - 1900), 100);
    $days += _div(($x - 1600), 400);

    $days;
}

{
    my $t = localtime;

    my $now = ymd_to_days($t->year, $t->mon, $t->mday) + $t->sec / (60 * 60 * 24) + $t->min / (60 * 24);
    my $then = ymd_to_days(2014, 7, 29) - (3 / 24);

    local $| = 1;
    while ((my $diff = $then - $now) > 0) {
        printf("* Seconds: %d | Minutes: %.2f | Days: %.2f\r", 86400 * $diff, 86400 * $diff / 60, $diff);
        $now += 1 / 86400;
        sleep 1;
    }
}
