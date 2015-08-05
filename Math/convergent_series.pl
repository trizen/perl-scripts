#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 31 July 2015
# Website: https://github.com/trizen

# A simple generator of convergent infinite series.

use 5.010;
use strict;
use warnings;

use List::Util qw(first);
use Term::ReadLine qw();
use Storable qw(store retrieve);

my $db = 'convergent_series.db';

my %map;
if (-e $db) {
    %map = %{retrieve($db)};
}
else {
    generate_all();
    save_database();
}

sub save_database {
    store(\%map, 'convergent_series.db');
}

#
## sum(i^k / (j*n)^l)
#
sub generate_squared_series {

    my $ref = \%map;

    my %f;
    foreach my $i (1 .. 4) {
        foreach my $j (1 .. 4) {
            foreach my $k (1 .. 3) {
                foreach my $l (2 .. 3) {

                    my $sum = 0;
                    foreach my $n (1 .. 10000000) {
                        $sum += $i**$k / ($j * $n)**$l;
                    }

                    my $formula = "sum($i**$k/($j*n)**$l)";

                    $formula =~ s/\b1\*(?=[\d(n])//g;
                    $formula =~ s/[\d)]\K\*\*1\b//g;
                    $formula =~ s/\b1\K\*\*\d+//g;
                    $formula =~ s{/1\b}{}g;
                    $formula =~ s/\((\d+|n)\)/$1/g;

                    my $form = ($f{$formula} //= \$formula);

                    $ref = \%map;
                    say "$formula ($sum)";

                    foreach my $char (split(//, $sum)) {
                        if (not defined first { $formula eq ${$_} } @{$ref->{f}}) {
                            push @{$ref->{f}}, $form;
                        }
                        $ref = ($ref->{d}{$char} //= {});
                    }

                }
            }
        }
    }
}

sub generate_all {
    generate_squared_series();

    # more to come...

    print "\n** Database generated successfully!\n\n";
}

sub lookup {
    my ($n) = @_;

    my %found;
    foreach my $i (2 .. 100) {

        foreach my $pair ([$n, ""],
                          [$n**(1 / $i),    "**$i"],
                          [$n**$i,          "**(1/$i)"],
                          [$n**(-($i - 1)), "**(-${\($i-1)})"],
                          [$n / $i,         "*$i"],
                          [$n * $i,         "/$i"],
                          (map { [$n**$i / $_, "*$_)**(1/$i)"] } 2 .. 9)) {

            my $j = $pair->[0];
            my @chars = split(//, $j);

            my $max = 0;
            my $ref = \%map;

            my @match;
            while (@chars and exists($ref->{d}{$chars[0]})) {
                my $char = shift @chars;
                $ref = $ref->{d}{$char};
                push @match, $char;
                ++$max;
            }

            if ($max >= 6) {
                push @{$found{$max}}, [$ref->{f}, $pair->[1], join('', @match)];
            }
        }
    }

    my @matches;
    foreach my $key (sort { $b <=> $a } keys %found) {
        my $arrs = $found{$key};

        my %seen;
        foreach my $arr (@{$arrs}) {
            foreach my $f (@{$arr->[0]}) {

                my $func = "${$f}$arr->[1]";
                if (($func =~ tr/)//) != ($func =~ tr/(//)) {
                    $func = "($func";
                }

                next if $seen{$func}++;
                push @matches, sprintf("%-50s%s", $func, "($arr->[2])");
            }
        }
    }
    return @matches;
}

my %const = (
             e  => exp(1),
             pi => atan2(0, -'inf'),
            );

my $term = Term::ReadLine->new("Convergent series");
while (defined(my $expr = $term->readline("Enter an expression: "))) {

    {
        local $" = '|';
        $expr =~ s/\b(@{[keys %const]})\b/$const{$1}/g;
    }

    my $n = eval($expr);

    if ($@) {
        warn "\n[!] Invalid expression: $expr\n\t$@\n";
        next;
    }
    elsif (not defined($n)) {
        next;
    }

    my @formulas = lookup($n);

    if (@formulas) {
        print "\n[+] Found the following formulas for $n:\n\t";
        print join("\n\t", @formulas), "\n\n";
    }
    else {
        print "\n[-] Can't find any formula for $n\n\n";
    }
}

__END__

use 5.010;
use strict;

sub pi {
    my $sum = 0;

    for my $k(0..10) {
        $sum += (1/16**$k) * (4/(8*$k+1) - 2/(8*$k+4) - 1/(8*$k+5) - 1/(8*$k+6));
    }

    $sum;
}

sub zeta {
    my ($n) = @_;

    my $sum = 0;
    for my $i(1..100000) {
        $sum += 1/$i**$i;
    }

    $sum;
}

say zeta(2);
say pi();
