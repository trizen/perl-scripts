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

        #foreach my $key (sort keys %$self) {
        #    printf("%-15s => %s\n", $key, $self->{$key});
        #}

        my $percent = sub {
            sprintf('%.4g%%', $_[0] / $self->{count} * 100);
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
               $self->{odds} || $self->{evens}
             ? !$self->{odds} || ($self->{odds} && $self->{evens} && $self->{evens} >= $self->{odds})
                   ? ['Evens', $self->{evens}, $percent->($self->{evens})]
                   : $self->{odds} ? ['Odds', $self->{odds}, $percent->($self->{odds})]
                 : ()
             : ()
            ),

              ($self->{pos} ? ["Positives", $self->{pos}, $percent->($self->{pos})] : ()),
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
                $self->{duplicates}
                ? ['Duplicated terms', $self->{duplicates}, $percent->($self->{duplicates})]
                : ()
              ),

              (
                $self->{increasing_consecutive}
                ? ['Cons. increasing terms',
                   $self->{increasing_consecutive} + 1,
                   $percent->($self->{increasing_consecutive} + 1)
                  ]
                : ()
              ),

              (
                $self->{decreasing_consecutive}
                ? ['Consecutive decreasing terms',
                   $self->{decreasing_consecutive} + 1,
                   $percent->($self->{decreasing_consecutive} + 1)
                  ]
                : ()
              ),

              (
                $self->{equal_consecutive}
                ? ['Consecutive equal terms', $self->{equal_consecutive} + 1, $percent->($self->{equal_consecutive} + 1)]
                : ()
              ),

              ['Minimum value', $self->{min}], ['Maximum value', $self->{max}],

              (
                  (ref($self->{divisors_avg}) && $self->{divisors_avg}->is_nan) || !$self->{divisors_avg}
                ? ()
                : ['Avg. number of divisors', sprintf('%.2f', $self->{divisors_avg})]
              ),

              (
                  (ref($self->{factors_avg}) && $self->{factors_avg}->is_nan) || !$self->{factors_avg}
                ? ()
                : ['Avg. number of prime factors', sprintf('%.2f', $self->{factors_avg})]
              ),

              (
                $self->{divisor_sum_avg}
                ? ['Divisor sum average', $self->{divisor_sum_avg}]
                : ()
              ),

              (
                ref($self->{arithmetic_mean}) && !$self->{arithmetic_mean}->is_real
                ? ()
                : ['Arithmetic mean', $self->{arithmetic_mean}]
              ),

              (
                ref($self->{geometric_mean}) && !$self->{geometric_mean}->is_real
                ? ()
                : ['Geometric mean', $self->{geometric_mean}]
              ),

              (
                ref($self->{lowest_ratio}) && !$self->{lowest_ratio}->is_real
                ? ()
                : ['Lowest consecutive ratio', $self->{lowest_ratio}]
              ),

              (
                ref($self->{highest_ratio}) && !$self->{highest_ratio}->is_real
                ? ()
                : ['Highest consecutive ratio', $self->{highest_ratio}]
              ),

              (
                  exists($self->{ratios_sum})
                ? ref($self->{ratios_sum}) && !$self->{ratios_sum}->is_real
                      ? ()
                      : ['Avg. consecutive ratio', $self->{ratios_sum} / ($self->{count} - 1)]
                : ()
              ),

              (
                ref($self->{lowest_diff}) && !$self->{lowest_diff}->is_real
                ? ()
                : ['Lowest consecutive difference', $self->{lowest_diff}]
              ),

              (
                ref($self->{highest_diff}) && !$self->{highest_diff}->is_real
                ? ()
                : ['Highest consecutive difference', $self->{highest_diff}]
              ),

              (
                  exists($self->{avg_diff})
                ? ref($self->{avg_diff}) && !$self->{avg_diff}->is_real
                      ? ()
                      : ['Avg. consecutive difference', $self->{avg_diff}]
                : ()
              ),

              (
                ref($self->{ratios_prod}) && !$self->{ratios_prod}->is_real
                ? ()
                : ['Pair ratio product', $self->{ratios_prod}]
              ),

              (
                ref($self->{log_pair_sum}) && $self->{log_pair_sum}->is_real
                ? ['Pair log ratio sum', $self->{log_pair_sum}]
                : ()
              ),

              (
                ref($self->{log_pair_prod})
                  && $self->{log_pair_prod}->is_real
                ? ['Pair log ratio prod', $self->{log_pair_prod}]
                : ()
              ),

              (
                ref($self->{root_pair_sum})
                  && $self->{root_pair_sum}->is_real
                ? ['Pair root ratio sum', $self->{root_pair_sum}]
                : ()
              ),

              (
                ref($self->{root_pair_prod})
                  && $self->{root_pair_prod}->is_real
                ? ['Pair root ratio prod', $self->{root_pair_prod}]
                : ()
              ),

          ) {
            my ($label, $value, $extra) = @$row;
            $t->addRow($label, sprintf("%.15g", $value), defined($extra) ? $extra : ());
        }

        $t->alignCol({$columns[1] => 'right'});
        $t->alignCol({$columns[2] => 'right'});

        print $t;

        say "=> Summary:";

        # Number of primes
        if ($self->{primes}) {
            my $li_dist = LogarithmicIntegral($self->{count});
            my $log_dist = $self->{count} > 1 ? $self->{count} / log($self->{count}) : 0;

            if ($self->{primes} >= $li_dist) {
                if ($self->{primes} / $self->{count} * 100 > 80) {
                    say "\tcontains many primes (>80%)";
                }
                else {
                    printf("\tcontains about %.2f times more than a random number of primes\n", $self->{primes} / $li_dist);
                }
            }
            elsif ($self->{primes} < $li_dist and $self->{primes} > $log_dist) {
                printf("\tcontains a random number of primes (between %d and %d)\n", int($log_dist), int($li_dist));
            }
            else {
                printf("\tcontains about %.2f times less than a random number of primes\n", $li_dist / $self->{primes});
            }
        }
        else {
            say "\tcontains no primes";
        }

        # Increasing sequence
        if ($self->{increasing_consecutive} and $self->{increasing_consecutive} == $self->{count} - 1) {
            say "\tall terms are in a strictly increasing order";
        }

        # Decreasing sequence
        if ($self->{decreasing_consecutive} and $self->{decreasing_consecutive} == $self->{count} - 1) {
            say "\tall terms are in a strictly decreasing order";
        }

        # Geometric sequence
        if (    ref($self->{lowest_ratio}) && $self->{lowest_ratio}->is_real
            and ref($self->{highest_ratio}) && $self->{highest_ratio}->is_real
            and $self->{lowest_ratio} == $self->{highest_ratio}) {
            say "\tgeometric sequence with ratio=$self->{lowest_ratio}";
        }

        # Arithmetic sequence
        if (    ref($self->{lowest_diff}) && $self->{lowest_ratio}->is_real
            and ref($self->{highest_diff}) && $self->{highest_diff}->is_real
            and $self->{lowest_diff} == $self->{highest_diff}) {
            say "\tarithmetic sequence with diff=$self->{lowest_diff}";
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
                    ratios_prod    => 1,
                    log_pair_prod  => 1,
                    root_pair_prod => 1,
                    geometric_mean => 1,
                    lowest_ratio   => Inf,
                    highest_ratio  => -Inf,
                    lowest_diff    => Inf,
                    highest_diff   => -Inf,
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

            if ($self->{is_int}) {

                if ($self->{is_pos}) {
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
                }

                if ($n->is_psqr) {
                    ++$data{perfect_squares};
                }
                elsif ($n->is_ppow) {
                    ++$data{perfect_powers};
                }

                if ($n->is_even) {
                    ++$data{evens};
                }
                else {
                    ++$data{odds};
                }
            }

            if ($n < $min) {
                $min = $n;
            }

            if ($n > $max) {
                $max = $n;
            }

            if (defined($prev)) {

                {
                    my $diff = $n - $prev;
                    $data{avg_diff} += $diff / ($data{count} - 1);

                    if ($diff < $data{lowest_diff}) {
                        $data{lowest_diff} = $diff;
                    }

                    if ($diff > $data{highest_diff}) {
                        $data{highest_diff} = $diff;
                    }
                }

                {
                    my $div = $n / $prev;

                    $data{ratios_sum} += $div;
                    $data{ratios_prod} *= $div;

                    if ($div < $data{lowest_ratio}) {
                        $data{lowest_ratio} = $div;
                    }

                    if ($div > $data{highest_ratio}) {
                        $data{highest_ratio} = $div;
                    }
                }

                {
                    my $root = $n->root($prev);
                    $data{root_pair_prod} *= $root;
                    $data{root_pair_sum} += $root;
                }

                {
                    my $log = $n->log($prev);
                    $data{log_pair_prod} *= $log;
                    $data{log_pair_sum} += $log;
                }

                if (defined(my $cmp = $n <=> $prev)) {
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

sub usage {
    print <<"EOT";
usage: $0 [options] [< sequence.txt]

options:
    -m  --map=type,type : map the sequence
    -r  --reverse       : reverse the sequence

valid map types:
    sum     : consecutive sums
    ratio   : consecutive ratios
    prod    : consecutive products
    diff    : consecutive differences

    log     : take the natural logartihm of each term
    sqrt    : take the square root of each term
    root    : take the nth root each term
    sqr     : square each term (k^2)
    cube    : cube each term (k^3)
    pow     : rise each term at the nth power

    psum    : consecutive pair sum
    pratio  : consecutive pair ratios
    pprod   : consecutive pair products
    pdiff   : consecutive pair difference

example:
    $0 -m log,sum < FibonacciSeq.txt
EOT
    exit;
}

my $map     = '';
my $reverse = 0;

GetOptions(
           'm|map=s'    => \$map,
           'r|reverse!' => \$reverse,
           'h|help'     => \&usage,
          );

my @numbers;

my $trans_re = qr/\b(log(?:2|10)?|sqrt|root|pow|cbrt|sqr|cube)\b/;

while (<>) {
    my $num = (split(' '))[-1];
    push @numbers, Math::BigNum->new($num);

    while ($map =~ /$trans_re/go) {
        if ($1 eq 'log') {
            $numbers[-1]->blog;
        }
        elsif ($1 eq 'log2') {
            $numbers[-1]->blog(2);
        }
        elsif ($1 eq 'log10') {
            $numbers[-1]->blog(10);
        }
        elsif ($1 eq 'sqrt') {
            $numbers[-1]->bsqrt;
        }
        elsif ($1 eq 'cbrt') {
            $numbers[-1]->broot(3);
        }
        elsif ($1 eq 'root') {
            $numbers[-1]->broot($.);
        }
        elsif ($1 eq 'pow') {
            $numbers[-1]->bpow($.);
        }
        elsif ($1 eq 'cube') {
            $numbers[-1]->bpow(3);
        }
        elsif ($1 eq 'sqr') {
            $numbers[-1]->bsqr;
        }
        else {
            die "ERROR: unknown map type: `$1`";
        }
    }
}

if ($reverse) {
    @numbers = reverse(@numbers);
}

my $consecutive_re = qr/\b(ratio|diff|sum|prod)\b/;
my $pair_re        = qr/\b(pratio|pdiff|psum|pprod)\b/;

if ($map =~ /$consecutive_re/o) {

    my @new;
    my $prev = shift @numbers;

    foreach my $num (@numbers) {
        while ($map =~ /$consecutive_re/go) {
            if ($1 eq 'ratio') {
                $prev /= $num;
            }
            elsif ($1 eq 'prod') {
                $prev *= $num;
            }
            elsif ($1 eq 'diff') {
                $prev -= $num;
            }
            elsif ($1 eq 'sum') {
                $prev += $num;
            }
            else {
                die "ERROR: unknown map type: `$1`";
            }
        }
        push @new, $prev;
    }

    @numbers = @new;
}

if ($map =~ /$pair_re/o) {

    my @new;
    my $prev;

    foreach my $num (reverse(@numbers)) {
        if (defined($prev)) {
            while ($map =~ /$pair_re/go) {
                if ($1 eq 'pratio') {
                    $prev /= $num;
                }
                elsif ($1 eq 'pprod') {
                    $prev *= $num;
                }
                elsif ($1 eq 'pdiff') {
                    $prev -= $num;
                }
                elsif ($1 eq 'psum') {
                    $prev += $num;
                }
                else {
                    die "ERROR: unknown map type: `$1`";
                }
            }
            unshift @new, $prev;
        }
        $prev = $num;
    }

    @numbers = @new;
}

use List::Util qw(all min);

say "=> First 10 terms:";
say for @numbers[0 .. min(9, $#numbers)];
say '';

my $report = Sequence->new(
                           sequence => \@numbers,
                           is_int   => (all { $_->is_int } @numbers),
                           is_pos   => (all { $_->is_pos } @numbers),
                          )->analyze;
$report->display;

__END__

Example: perl sequence_analyzer.pl lucasSeq.txt

.------------------------------------------------------------------------------------------------.
| Label                          | Absolute                               | Percentage           |
+--------------------------------+----------------------------------------+----------------------+
| Terms count                    |                                    200 |                      |
| Odds                           |                                    133 |                66.5% |
| Positives                      |                                    200 |                 100% |
| Primes                         |                                     20 |                  10% |
| Perfect squares                |                                      2 |                   1% |
| Cons. increasing terms         |                                    199 |                99.5% |
| Consecutive decreasing terms   |                                      2 |                   1% |
| Minimum value                  |                                      1 |                      |
| Maximum value                  |                   3.87739824812222e+41 |                      |
| Avg. number of prime factors   |                                   4.21 |                      |
| Divisor sum average            |                   7.12545315917369e+39 |                      |
| Arithmetic mean                |                   5.07558020075164e+39 |                      |
| Geometric mean                 |                   6.23640784643016e+20 |                      |
| Lowest consecutive ratio       |                                    0.5 |                      |
| Highest consecutive ratio      |                                      3 |                      |
| Avg. consecutive ratio         |                       1.61842555557034 |                      |
| Lowest consecutive difference  |                                     -1 |                      |
| Highest consecutive difference |                   1.48103434286339e+41 |                      |
| Avg. consecutive difference    |                   1.94844133071469e+39 |                      |
| Pair ratio product             |                   1.93869912406111e+41 |                      |
| Pair root ratio sum            |                       203.563569015452 |                      |
| Pair root ratio prod           |                        25.972781795394 |                      |
'--------------------------------+----------------------------------------+----------------------'
=> Summary:
    contains about 2.51 times less than a random number of primes
