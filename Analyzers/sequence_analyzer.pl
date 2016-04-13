#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 13 April 2016
# Website: https://github.com/trizen

# Analyze a sequence of numbers and generate a report with the results.

################################################
#                  [WARNING]                   #
#-----------------------------------------------
#   This script is still a work in progress!   #
#----------------------------------------------#
################################################

use 5.014;

use strict;
use warnings;

package Sequence::Report {

    use Text::ASCIITable;
    use ntheory qw(LogarithmicIntegral);

    sub new {
        my ($class, %opt) = @_;
        bless \%opt, $class;
    }

    sub display {
        my ($self) = @_;

        foreach my $key (sort keys %$self) {
            printf("%-15s => %s\n", $key, $self->{$key});
        }

        my $percent = sub {
            sprintf('%.5g%%', $_[0] / $self->{count} * 100);
        };

        my $avg = sub {
            sprintf('%.2f', $_[0] / $self->{count});
        };

        my $t = Text::ASCIITable->new();
        my @columns = ('Label', 'Absolute' . ' ' x 30, 'Percentage' . ' ' x 10);
        $t->setCols(@columns);

        foreach my $row (
                         ['Terms count', $self->{count}],
                         (
                          $self->{evens} > ($self->{count} - $self->{evens})
                          ? ['Evens', $self->{evens}, $percent->($self->{evens})]
                          : ['Odds', $self->{count} - $self->{evens}, $percent->($self->{count} - $self->{evens})]
                         ),
                         ($self->{pos}    ? ["Positives", $self->{pos},    $percent->($self->{pos})]    : ()),
                         ($self->{neg}    ? ["Negatives", $self->{neg},    $percent->($self->{neg})]    : ()),
                         ($self->{zeros}  ? ["Zeros",     $self->{zeros},  $percent->($self->{zeros})]  : ()),
                         ($self->{primes} ? ['Primes',    $self->{primes}, $percent->($self->{primes})] : ()),
                         (
                          $self->{perfect_powers}
                          ? ['Perfect powers', $self->{perfect_powers}, $percent->($self->{perfect_powers})]
                          : ()
                         ),
                         (
                          $self->{perfect_squares}
                          ? ['Perfect squares', $self->{perfect_squares}, $percent->($self->{perfect_squares})]
                          : ()
                         ),
                         (
                          $self->{duplicates} ? ['Duplicated terms', $self->{duplicates}, $percent->($self->{duplicates})] : ()
                         ),
                         (
                            (ref($self->{divisors_avg}) && $self->{divisors_avg}->is_nan) || !$self->{divisors_avg} ? ()
                          : ['Avg. number of divisors', sprintf('%.2f', $self->{divisors_avg})]
                         ),
                         (
                            (ref($self->{factors_avg}) && $self->{factors_avg}->is_nan) || !$self->{factors_avg} ? ()
                          : ['Avg. number of prime factors', sprintf('%.2f', $self->{factors_avg})]
                         ),
                         ($self->{divisor_sum_avg} ? ['Divisor sum avg.', $self->{divisor_sum_avg}] : ()),
                         ['Arithmetic mean', $self->{arithmetic_mean}],
                         ['Geometric mean',  $self->{geometric_mean}],
                         (exists($self->{avg_diff}) ? ['Avg. difference', $self->{avg_diff}] : ()),
                         (
                          ref($self->{lowest_ratio})
                            && !$self->{lowest_ratio}->is_real ? () : ['Lowest consecutive ratio', $self->{lowest_ratio}]
                         ),
                         (
                          ref($self->{highest_ratio})
                            && !$self->{highest_ratio}->is_real ? () : ['Highest consecutive ratio', $self->{highest_ratio}]
                         ),
                         (
                            ref($self->{ratios_sum}) && !$self->{ratios_sum}->is_real ? ()
                          : exists($self->{ratios_sum}) ? ['Average consecutive ratio', $self->{ratios_sum} / $self->{count}]
                          :                               ()
                         ),
                         (
                          ref($self->{ratios_prod})
                            && !$self->{ratios_prod}->is_real ? () : ['Consecutive ratio product', $self->{ratios_prod}]
                         ),
                         (
                          ref($self->{log_pair_sum})
                            && $self->{log_pair_sum}->is_real ? ['Consecutive log ratio sum', $self->{log_pair_sum}] : ()
                         ),
                         (
                          ref($self->{log_pair_prod})
                            && $self->{log_pair_prod}->is_real ? ['Consecutive log ratio prod', $self->{log_pair_prod}] : ()
                         ),
                         (
                          ref($self->{root_pair_sum})
                            && $self->{root_pair_sum}->is_real ? ['Consecutive root ratio sum', $self->{root_pair_sum}] : ()
                         ),
                         (
                          ref($self->{root_pair_prod})
                            && $self->{root_pair_prod}->is_real ? ['Consecutive root ratio prod', $self->{root_pair_prod}] : ()
                         ),
                         (
                          $self->{increasing_consecutive}
                          ? ['Consecutive increasing terms',
                             $self->{increasing_consecutive},
                             $percent->($self->{increasing_consecutive} + 1)
                            ]
                          : ()
                         ),
                         (
                          $self->{decreasing_consecutive}
                          ? ['Consecutive decreasing terms',
                             $self->{decreasing_consecutive},
                             $percent->($self->{decreasing_consecutive} + 1)
                            ]
                          : ()
                         ),
                         (
                          $self->{equal_consecutive}
                          ? ['Consecutive equal terms', $self->{equal_consecutive}, $percent->($self->{equal_consecutive} + 1)
                            ]
                          : ()
                         ),
                         ['Minimum value', $self->{min}],
                         ['Maximum value', $self->{max}],
          ) {
            my ($label, $value, $extra) = @$row;
            $t->addRow($label, sprintf("%.15g", $value), defined($extra) ? $extra : ());
        }

        $t->alignCol({$columns[1] => 'right'});
        $t->alignCol({$columns[2] => 'right'});

        print $t;

        say "=> Summary:";

        if ($self->{primes}) {
            my $li_dist = LogarithmicIntegral($self->{count});
            my $log_dist = $self->{count} > 1 ? $self->{count} / log($self->{count}) : 0;

            if ($self->{primes} >= $li_dist) {
                if ($self->{primes} / $self->{count} * 100 > 80) {
                    say "\tcontains many primes (>80%)";
                }
                else {
                    printf("\tcontains about %.2fx more than a random number of primes\n", $self->{primes} / $li_dist);
                }
            }
            elsif ($self->{primes} < $li_dist and $self->{primes} > $log_dist) {
                printf("\tcontains a random number of primes (between %d and %d)\n", int($log_dist), int($li_dist));
            }
            else {
                printf("\tcontains about %.2fx less than a random number of primes\n", $li_dist / $self->{primes});
            }
        }
        else {
            say "\tcontains no primes";
        }

        if ($self->{increasing_consecutive} and $self->{increasing_consecutive} == $self->{count} - 1) {
            say "\tall terms are in a strictly increasing order";
        }

        if ($self->{decreasing_consecutive} and $self->{decreasing_consecutive} == $self->{count} - 1) {
            say "\tall terms are in a strictly decreasing order";
        }

        $self;
    }
}

package Sequence {

    use Math::BigNum qw(Inf);
    use ntheory qw(factor divisors divisor_sum);
    use List::Util qw(all pairmap);

    sub new {
        my ($class, %opt) = @_;
        bless \%opt, $class;
    }

    sub analyze {
        my ($self) = @_;

        my $seq = $self->{sequence};

        my %data = (
                    evens          => 0,
                    ratios_prod    => 1,
                    log_pair_prod  => 1,
                    root_pair_prod => 1,
                    geometric_mean => 1,
                    lowest_ratio   => Inf,
                    highest_ratio  => -Inf,
                    count          => scalar(@$seq),
                   );

        $data{count} > 0
          or die "ERROR: empty sequence of numbers!\n";

        my $min = Inf;
        my $max = -Inf;

        my $prev;

        my %seen;
        my $i = 0;
        foreach my $n (@$seq) {

            if ($seen{$n}++) {
                ++$data{duplicates};
            }

            my $cmp = $n <=> 0;

            if ($cmp == 0) {
                ++$data{zeros};
            }
            elsif ($cmp > 0) {
                ++$data{pos};
            }
            else {
                ++$data{neg};
            }

            $data{arithmetic_mean} += $n / $data{count};
            $data{geometric_mean} *= $n->root($data{count});

            if ($n->is_prime) {
                ++$data{primes};
                if ($self->{factorize}) {
                    $data{factors_avg}     += 1 / $data{count};
                    $data{divisors_avg}    += 2 / $data{count};
                    $data{divisor_sum_avg} += ($n + 1) / $data{count};
                }
            }
            elsif ($self->{factorize}) {
                $data{factors_avg}     += factor($n) / $data{count};
                $data{divisors_avg}    += divisors($n) / $data{count};
                $data{divisor_sum_avg} += divisor_sum($n) / $data{count};
            }

            if ($n->is_psqr) {
                ++$data{perfect_squares};
            }

            if ($n->is_ppow) {
                ++$data{perfect_powers};
            }

            if ($n->is_even) {
                ++$data{evens};
            }

            if ($n < $min) {
                $min = $n;
            }

            if ($n > $max) {
                $max = $n;
            }

            if (defined($prev)) {
                my $div = $n / $prev;

                $data{ratios_sum} += $div;
                $data{ratios_prod} *= $div;

                my $diff = $n - $prev;
                $data{avg_diff} += $diff / ($data{count} - 1);

                my $log = $n->log($prev);
                $data{log_pair_prod} *= $log;
                $data{log_pair_sum} += $log;

                my $root = $n->root($prev);
                $data{root_pair_prod} *= $root;
                $data{root_pair_sum} += $root;

                if ($div < $data{lowest_ratio}) {
                    $data{lowest_ratio} = $div;
                }

                if ($div > $data{highest_ratio}) {
                    $data{highest_ratio} = $div;
                }

                my $cmp = $n <=> $prev;

                if ($cmp > 0) {
                    ++$data{increasing_consecutive};
                }
                elsif ($cmp < 0) {
                    ++$data{decreasing_consecutive};
                }
                else {
                    ++$data{equal_consecutive};
                }
            }

            $prev = $n;

            if (++$i > 500) {
                while (my ($key, $value) = each %data) {
                    if (ref($value) eq 'Math::BigNum') {
                        $data{$key} = $value->float;
                    }
                }
            }
        }

        $data{min} = $min;
        $data{max} = $max;

        $data{equal} = $min == $max;

        Sequence::Report->new(%data);
    }
}

use Getopt::Long qw(GetOptions);

my $factorize = 1;

sub usage {
    print <<"EOT";
usage: $0 [options] [< sequence.txt]

options:
        -f  --factorize!  : factorize each term (default: ${\($factorize ? 'true' : 'false')})

example:
    $0 --no-factorize < FibonacciSeq.txt
EOT
    exit;
}

GetOptions('f|factorize!' => \$factorize,
           'h|help'       => \&usage,);

my @numbers;

while (<>) {
    my $num = (split(' '))[-1];
    push @numbers, Math::BigNum->new($num);
}

my $report = Sequence->new(
                           sequence  => \@numbers,
                           factorize => $factorize,
                          )->analyze;
$report->display;

__END__

Example: perl sequence_analyzer.pl lucasSeq.txt

.----------------------------------------------------------------------------------------------.
| Label                        | Absolute                               | Percentage           |
+------------------------------+----------------------------------------+----------------------+
| Terms count                  |                                    200 |                      |
| Odds                         |                                    134 |                  67% |
| Positives                    |                                    200 |                 100% |
| Primes                       |                                     19 |                 9.5% |
| Perfect powers               |                                      2 |                   1% |
| Perfect squares              |                                      2 |                   1% |
| Avg. number of prime factors |                                   4.23 |                      |
| Divisor sum avg.             |                   1.03321578536822e+40 |                      |
| Arithmetic mean              |                   8.21246127744217e+39 |                      |
| Geometric mean               |                   1.00558086246261e+21 |                      |
| Avg. difference              |                   3.15264429818144e+39 |                      |
| Lowest consecutive ratio     |                       1.33333333333333 |                      |
| Highest consecutive ratio    |                                      3 |                      |
| Average consecutive ratio    |                       1.61592359773623 |                      |
| Consecutive ratio product    |                   6.27376215338106e+41 |                      |
| Consecutive root ratio sum   |                       203.563569015452 |                      |
| Consecutive root ratio prod  |                        25.972781795394 |                      |
| Consecutive increasing terms |                                    199 |                 100% |
| Minimum value                |                                      1 |                      |
| Maximum value                |                   6.27376215338106e+41 |                      |
'------------------------------+----------------------------------------+----------------------'
=> Summary:
    contains about 2.64x less than a random number of primes
    all terms are in a strictly increasing order
