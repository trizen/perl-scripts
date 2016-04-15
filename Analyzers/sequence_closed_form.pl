#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 15 April 2016
# Website: https://github.com/trizen

# Analyze a sequence of numbers and find a closed-form expression.

# WARNING: This program is under heavy development.

use 5.010;
use strict;
use warnings;

package Sequence::ClosedForm {

    sub new {
        my ($class, %opt) = @_;
        bless \%opt, $class;
    }

    sub sub_n {
        my ($self) = @_;

        my $n = 0;
        sub {
            $_[0] - ++$n;
        };
    }

    sub add_n {
        my ($self) = @_;

        my $n = 0;
        sub {
            $_[0] + ++$n;
        };
    }

    sub sub_constant {
        my ($self, $c) = @_;
        sub {
            $_[0] - $c;
          }
    }

    sub div_constant {
        my ($self, $c) = @_;
        sub {
            $_[0] / $c;
          }
    }

    sub add_constant {
        my ($self, $c) = @_;
        sub {
            $_[0] + $c;
          }
    }

    sub sub_consecutive {
        my ($self) = @_;

        my $prev;
        sub {
            my ($term) = @_;
            if (defined($prev)) {
                $term = $term - $prev;
            }
            $prev = $_[0];
            $term;
        };
    }

    sub add_consecutive {
        my ($self) = @_;

        my $prev;
        sub {
            my ($term) = @_;
            if (defined($prev)) {
                $term = $term + $prev;
            }
            $prev = $_[0];
            $term;
        };
    }

    sub div_consecutive {
        my ($self) = @_;

        my $prev;
        sub {
            my ($term) = @_;
            if (defined($prev)) {
                $term = $term / $prev;
            }
            $prev = $_[0];
            $term;
        };
    }
}

my @rules = (
             ['sub_consecutive'],
             ['add_constant', 'div_consecutive'],
             ['sub_constant', 'add_n', 'add_n'],
             ['sub_constant'],
             ['sub_n', 'div_consecutive',],
             ['add_n', 'div_consecutive',],
             ['div_consecutive',],
            );

my @constants = (1 .. 3);    #, #exp(1), atan2(0, -'inf'));

my $seq = Sequence::ClosedForm->new();
my @seq = (map { [$_ * ($_ + 1) / 2] } 1 .. 10);

sub generate_closures {
    map {
        /_constant\z/
          ? do {
            my $sub = $_;
            ($sub => [map { $seq->$sub($_) } @constants]);
          }
          : ($_ => $seq->$_)
    } @_;
}

RULE: foreach my $rule (@rules) {
    my @methods  = @{$rule};
    my %closures = generate_closures(@methods);

    my @matrix;

    foreach my $m (@seq) {
        ++$#matrix;
        my @m     = @{$m};
        my $reset = 0;
        foreach my $term (@m) {
            my $result = $term;
            foreach my $method (@methods) {
                if (ref($closures{$method}) eq 'ARRAY') {
                    my @map;
                    foreach my $sub (@{$closures{$method}}) {
                        push @map, eval { $sub->($term) } // next RULE;
                    }
                    @m = @map;
                    $reset ||= 1;
                }
                else {
                    $result = eval { $closures{$method}($result) };
                }
                last if $@;
            }
            $result // next RULE;
            push @{$matrix[-1]}, $result;
        }
        if ($reset) {
            %closures = generate_closures(@methods);
        }
    }

    use Data::Dump qw(pp);
    pp \@matrix;
}
