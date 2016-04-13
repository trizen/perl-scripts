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

    sub new {
        my ($class, %opt) = @_;
        bless \%opt, $class;
    }

    sub display {
        my ($self) = @_;

        #foreach my $key (sort keys %$self) {
        #    printf("%-15s => %s\n", $key, $self->{$key});
        #}

        my $percent = sub {
            sprintf('%d%%', $_[0] / $self->{count} * 100);
        };

        my $avg = sub {
            sprintf('%.2f', $_[0] / $self->{count});
        };

        my $t = Text::ASCIITable->new();
        $t->setCols('Label', 'Absolute' . ' ' x 30, 'Percentage' . ' ' x 10);

        foreach my $row (
                         ['Terms count', $self->{count}],
                         (
                          $self->{evens} > ($self->{count} - $self->{evens})
                          ? ['Evens', $self->{evens}, $percent->($self->{evens})]
                          : ['Odds', $self->{count} - $self->{evens}, $percent->($self->{count} - $self->{evens})]
                         ),
                         ($self->{pos}   ? ["Positives", $self->{pos},   $percent->($self->{pos})]   : ()),
                         ($self->{neg}   ? ["Negatives", $self->{neg},   $percent->($self->{neg})]   : ()),
                         ($self->{zeros} ? ["Zeros",     $self->{zeros}, $percent->($self->{zeros})] : ()),
                         ['Primes', $self->{primes}, $percent->($self->{primes})],
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
                         ['# Factors avg.', sprintf('%.2f', $self->{factors_avg})],
                         (
                          ref($self->{divisors_avg})
                            && $self->{divisors_avg}->is_nan ? () : ['# Divisors avg.', sprintf('%.2f', $self->{divisors_avg})]
                         ),
                         ['Divisor sum avg.',          $self->{divisor_sum_avg}],
                         ['Arithmetic mean',           $self->{arithmetic_mean}],
                         ['Geometric mean',            $self->{geometric_mean}],
                         ['Avg. difference',           $self->{avg_diff}],
                         ['Lowest consecutive ratio',  $self->{lowest_ratio}],
                         ['Highest consecutive ratio', $self->{highest_ratio}],
                         ['Average consecutive ratio', $self->{ratios_sum} / $self->{count}],
                         ['Consecutive ratio product', $self->{ratios_prod}],
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
                         ($self->{descending} ? () : ['Strictly ascending',  $self->{ascending}  ? 'yes' : 'no']),
                         ($self->{ascending}  ? () : ['Strictly descending', $self->{descending} ? 'yes' : 'no']),
                         ($self->{ascending} || $self->{descending} ? () : ['All equal', $self->{equal} ? 'yes' : 'no']),
                         ['Minimum value', $self->{min}],
                         ['Maximum value', $self->{max}],
          ) {
            $t->addRow(@$row);
        }

        print $t;

        $self;
    }
}

package Sequence {

    use Math::BigNum qw(Inf);
    use ntheory qw(factor divisors divisor_sum);
    use List::Util qw(all pairmap);

    sub new {
        my ($class, $arr) = @_;
        bless $arr, $class;
    }

    sub analyze {
        my ($self) = @_;

        my %data = (
                    evens           => 0,
                    duplicates      => 0,
                    ratios_sum      => 0,
                    ratios_prod     => 1,
                    log_pair_sum    => 0,
                    log_pair_prod   => 1,
                    root_pair_sum   => 0,
                    root_pair_prod  => 1,
                    perfect_powers  => 0,
                    perfect_squares => 0,
                    arithmetic_mean => 0,
                    geometric_mean  => 1,
                    lowest_ratio    => Inf,
                    highest_ratio   => -Inf,
                    count           => scalar(@$self),
                   );

        my $min = Inf;
        my $max = -Inf;

        my $prev;

        my %seen;
        my $i = 0;
        foreach my $n (@$self) {

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
                $data{factors_avg}     += 1 / $data{count};
                $data{divisors_avg}    += 2 / $data{count};
                $data{divisor_sum_avg} += ($n + 1) / $data{count};
            }
            else {
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
                $data{avg_diff} += $diff / $data{count};

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

        $data{ascending} = do {
            my $x = $min - 1;
            all { my $bool = $_ > $x; $x = $_; $bool } @$self;
        };

        $data{descending} = do {
            my $x = $max + 1;
            all { my $bool = $_ < $x; $x = $_; $bool } @$self;
        };

        $data{equal} = $min == $max;

        Sequence::Report->new(%data);
    }

}

my @numbers;

while (<>) {
    chomp;
    push @numbers, Math::BigNum->new($_);
}

my $report = Sequence->new(\@numbers)->analyze;
$report->display;

__END__

Example: perl sequence_analyzer.pl lucasSeq.txt

.---------------------------------------------------------------------------------------------------.
| Label                       | Absolute                                     | Percentage           |
+-----------------------------+----------------------------------------------+----------------------+
| Terms count                 |                                          100 |                      |
| Odds                        |                                           67 |                  67% |
| Positives                   |                                          100 |                 100% |
| Primes                      |                                           18 |                  18% |
| Perfect powers              |                                            2 |                   2% |
| Perfect squares             |                                            2 |                   2% |
| # Factors avg.              |                                         3.25 |                      |
| Divisor sum avg.            |                      28212508112615572045.89 |                      |
| Arithmetic mean             |                      20736683802207131673.75 |                      |
| Geometric mean              | 35661051243.61841586753695206941047727609423 |                      |
| Avg. difference             |                       7920708398483722531.26 |                      |
| Lowest consecutive ratio    |           1.33333333333333333333333333333333 |                      |
| Highest consecutive ratio   |                                            3 |                      |
| Average consecutive ratio   |           1.61381320672257103568257571402219 |                      |
| Consecutive ratio product   |                        792070839848372253127 |                      |
| Consecutive root ratio sum  |         103.56356901545203579051796691421648 |                      |
| Consecutive root ratio prod |          25.97278179539401901214577958428716 |                      |
| Strictly ascending          | yes                                          |                      |
| Minimum value               |                                            1 |                      |
| Maximum value               |                        792070839848372253127 |                      |
'-----------------------------+----------------------------------------------+----------------------'
