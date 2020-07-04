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
                ref($self->{harmonic_mean}) && !$self->{harmonic_mean}->is_real
                ? ()
                : ['Harmonic mean', $self->{harmonic_mean}]
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
          ) {
            my ($label, $value, $extra) = @$row;
            $t->addRow($label, sprintf("%.15g", $value), defined($extra) ? $extra : ());
        }

        $t->alignCol({$columns[1] => 'right'});
        $t->alignCol({$columns[2] => 'right'});

        print $t;

        say "\n=> Summary:";

        # Number of primes
        if ($self->{primes}) {
            my $li_dist = LogarithmicIntegral($self->{count});
            my $log_dist = $self->{count} > 1 ? ($self->{count} / log($self->{count})) : 0;

            if ($self->{primes} == $self->{count}) {
                say "\tall terms are prime numbers";
            }
            elsif ($self->{primes} >= $li_dist) {
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
        elsif (($self->{evens} or $self->{odds}) and not $self->{neg}) {
            say "\tcontains no primes";
        }

        # Odd or even terms
        if ($self->{evens} and $self->{evens} == $self->{count}) {
            say "\tall terms are even";
        }
        elsif ($self->{odds} and $self->{odds} == $self->{count}) {
            say "\tall terms are odd";
        }
        elsif ($self->{evens} && $self->{odds} and $self->{evens} == $self->{odds}) {
            say "\tequal number of odds and evens";
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
            say "\tgeometric sequence (ratio = $self->{lowest_ratio})";

            if ($self->{increasing_consecutive} && $self->{increasing_consecutive} == $self->{count} - 1) {
                say "\tpossible closed-form: " . (
                    $self->{lowest_ratio} == 1 ? 'n' : (
                       $self->{min} == 1
                       ? "$self->{lowest_ratio}^(n-1)"
                       : (
                          $self->{min} == $self->{lowest_ratio} ? "$self->{lowest_ratio}^n" : (
                             "$self->{lowest_ratio}^(n" . do {
                                 my $log = $self->{min}->log($self->{lowest_ratio})->sub(1)->round(-30);
                                 $log->is_zero ? ''
                                   : (
                                      $log->is_int
                                        || length($log->as_rat) < 20
                                        || length($self->{min}->as_rat) > 20 ? (' ' . $log->sign . ' ' . $log->abs)
                                      : (" + log($self->{min})/log($self->{lowest_ratio}) - 1")
                                     );
                               }
                               . ')'
                          )
                         )
                    )
                );

                if ($self->{min} > $self->{lowest_ratio}) {
                    my $factor = $self->{min} / $self->{lowest_ratio};
                    say(
                        "\tpossible closed-form: "
                          . (
                             ($factor == 1 ? '' : "$factor * ")
                             . (
                                $self->{lowest_ratio} == 1
                                ? 'n'
                                : "$self->{lowest_ratio}^n"
                               )
                            )
                       );
                }
            }
        }

        # Arithmetic sequence
        if (    ref($self->{lowest_diff}) && $self->{lowest_diff}->is_real
            and ref($self->{highest_diff}) && $self->{highest_diff}->is_real
            and $self->{lowest_diff} == $self->{highest_diff}) {
            say "\tarithmetic sequence (diff = $self->{lowest_diff})";

            if ($self->{increasing_consecutive} && $self->{increasing_consecutive} == $self->{count} - 1) {
                my $min = ($self->{min} - $self->{lowest_diff})->round(-20);
                say "\tpossible closed-form: "
                  . (
                     $self->{lowest_diff} == 0 ? $min
                     : (
                        ($self->{lowest_diff} == 1 ? 'n' : "$self->{lowest_diff}n")
                        . (
                           $min == 0 ? ''
                           : (' ' . $min->sign . ' ' . $min->abs)
                          )
                       )
                    );
            }
        }

        # Perfect power sequence
        if ($self->{perfect_squares} && $self->{perfect_squares} == $self->{count}) {
            say "\tsequence of perfect squares";
        }
        elsif (
               $self->{perfect_powers}
               and (
                    $self->{perfect_powers} == $self->{count}
                    or (    $self->{perfect_squares}
                        and $self->{perfect_powers} + $self->{perfect_squares} == $self->{count})
                   )
          ) {
            say "\tsequence of perfect powers";
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
            $data{harmonic_mean} += $n->inv;

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

                    if ($div < $data{lowest_ratio}) {
                        $data{lowest_ratio} = $div;
                    }

                    if ($div > $data{highest_ratio}) {
                        $data{highest_ratio} = $div;
                    }
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
                $i = 0;
            }
        }

        $data{harmonic_mean} = $data{count} / $data{harmonic_mean};

        while (my ($key, $value) = each %data) {
            if (ref($value) eq 'Math::BigNum') {
                $data{$key} = $value->round(-30);
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
    -r  --reverse!      : reverse the sequence
    -s  --sort!         : sort the sequence
    -u  --uniq!         : remove duplicated terms
    -p  --prec=i        : number of decimals of precision
    -f  --first=i       : read only the first i terms
    -o  --output=s      : output the sequence into this file

valid map types:
    sum     : consecutive sums
    ratio   : consecutive ratios
    prod    : consecutive products
    diff    : consecutive differences

    abs     : take the absolute value
    int     : take the integer part
    floor   : take the floor value
    ceil    : take the ceil value
    log     : natural logarithm of each term
    log=x   : base x logarithm of each term
    div=x   : divide each term by x
    mul=x   : multiply each term by x
    add=x   : add x to each term
    sub=x   : subtract x from each term
    exp     : exponential of each term (e^k)
    cos     : cos() of each term
    sin     : sin() of each term
    inv     : inverse value (1/k)
    sqr     : square each term (k^2)
    sqrt    : take the square root of each term (k^(1/2))
    pow     : rise each term to the nth power (k^n)
    pow=x   : rise each term to the i power (k^x)
    root    : take the nth root of each term (k^(1/n))
    root=x  : take the k root of each term (k^(1/x))

    padd    : consecutive pair sum
    pdiv    : consecutive pair ratio
    pmul    : consecutive pair product
    psub    : consecutive pair difference

example:
    $0 -u -m root=5,floor,sum < FibonacciSeq.txt
EOT
    exit;
}

my $map     = '';
my $reverse = 0;
my $sort    = 0;
my $uniq    = 0;
my $prec    = 32;
my $first   = undef;
my $output  = undef;

GetOptions(
           'm|map=s'    => \$map,
           'r|reverse!' => \$reverse,
           's|sort!'    => \$sort,
           'u|uniq!'    => \$uniq,
           'p|prec=i'   => \$prec,
           'f|first=i'  => \$first,
           'o|output=s' => \$output,
           'h|help'     => \&usage,
          )
  or die "Error in command-line arguments";

local $Math::BigNum::PREC = 4 * $prec;

my @numbers;

my $value_re = qr/(?:=([-+]?\d+(?:\.\d+)?+)\b)?/;
my $trans_re = qr/\b(log|sqrt|root|pow|sqr|abs|exp|int|floor|ceil|inv|add|mul|div|sub|cos|sin)\b$value_re/o;

while (<>) {
    my $num = (split(' '))[-1];
    push @numbers, Math::BigNum->new($num);

    while ($map =~ /$trans_re/go) {
        if ($1 eq 'log') {
            defined($2)
              ? $numbers[-1]->blog($2)
              : $numbers[-1]->blog;
        }
        elsif ($1 eq 'sqrt') {
            $numbers[-1]->bsqrt;
        }
        elsif ($1 eq 'root') {
            defined($2)
              ? $numbers[-1]->broot($2)
              : $numbers[-1]->broot($.);
        }
        elsif ($1 eq 'pow') {
            defined($2)
              ? $numbers[-1]->bpow($2)
              : $numbers[-1]->bpow($.);
        }
        elsif ($1 eq 'sqr') {
            $numbers[-1]->bsqr;
        }
        elsif ($1 eq 'inv') {
            $numbers[-1]->binv;
        }
        elsif ($1 eq 'abs') {
            $numbers[-1]->babs;
        }
        elsif ($1 eq 'int') {
            $numbers[-1]->bint;
        }
        elsif ($1 eq 'cos') {
            $numbers[-1] = $numbers[-1]->cos;
        }
        elsif ($1 eq 'sin') {
            $numbers[-1] = $numbers[-1]->sin;
        }
        elsif ($1 eq 'ceil') {
            $numbers[-1] = $numbers[-1]->ceil;
        }
        elsif ($1 eq 'floor') {
            $numbers[-1] = $numbers[-1]->floor;
        }
        elsif ($1 eq 'exp') {
            $numbers[-1]->bexp;
        }
        elsif ($1 eq 'add') {
            defined($2)
              ? $numbers[-1]->badd($2)
              : $numbers[-1]->badd($.);
        }
        elsif ($1 eq 'sub') {
            defined($2)
              ? $numbers[-1]->bsub($2)
              : $numbers[-1]->bsub($.);
        }
        elsif ($1 eq 'mul') {
            defined($2)
              ? $numbers[-1]->bmul($2)
              : $numbers[-1]->bmul($.);
        }
        elsif ($1 eq 'div') {
            defined($2)
              ? $numbers[-1]->bdiv($2)
              : $numbers[-1]->bdiv($.);
        }
        else {
            die "ERROR: unknown map type: `$1`";
        }
    }

    if (defined($first) and $. >= $first) {
        last;
    }
}

if ($uniq) {
    my %seen;
    @numbers = grep { !$seen{$_->as_rat}++ } @numbers;
}

if ($sort) {
    @numbers = sort { $a <=> $b } @numbers;
}

if ($reverse) {
    @numbers = reverse(@numbers);
}

my $consecutive_re = qr/\b(ratio|diff|sum|prod)\b/;

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

my $pair_re = qr/\b(pdiv|psub|padd|pmul)\b/;

if ($map =~ /$pair_re/o) {

    my @new;
    my $prev;

    foreach my $num (reverse(@numbers)) {
        if (defined($prev)) {
            while ($map =~ /$pair_re/go) {
                if ($1 eq 'pdiv') {
                    $prev /= $num;
                }
                elsif ($1 eq 'pmul') {
                    $prev *= $num;
                }
                elsif ($1 eq 'psub') {
                    $prev -= $num;
                }
                elsif ($1 eq 'padd') {
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

    if ($uniq) {
        my %seen;
        @new = grep { !$seen{$_->as_rat}++ } @new;
    }

    if ($sort) {
        @new = sort { $a <=> $b } @new;
    }

    @numbers = @new;
}

use List::Util qw(all any min);

# Display the first 10 terms of the sequence
say "=> First 10 terms:";
say for @numbers[0 .. min(9, $#numbers)];
say '';

# Output the sequence into a file
if (defined($output)) {
    open my $fh, '>', $output;
    local $, = "\n";
    say {$fh} @numbers;
}

# Generate a report for the sequence
my $report = Sequence->new(
                           sequence => \@numbers,
                           is_int   => (all { $_->is_int } @numbers),
                           is_pos   => !(any { $_->is_neg } @numbers),
                          )->analyze;

# Display the report
$report->display;

__END__

First 10 terms:
6
18
54
162
486
1458
4374
13122
39366
118098

.------------------------------------------------------------------------------------------------.
| Label                          | Absolute                               | Percentage           |
+--------------------------------+----------------------------------------+----------------------+
| Terms count                    |                                    100 |                      |
| Evens                          |                                    100 |                 100% |
| Positives                      |                                    100 |                 100% |
| Cons. increasing terms         |                                    100 |                 100% |
| Minimum value                  |                                      6 |                      |
| Maximum value                  |                   1.03075504146402e+48 |                      |
| Avg. number of prime factors   |                                   51.5 |                      |
| Divisor sum average            |                   3.47879826494108e+46 |                      |
| Arithmetic mean                |                   1.54613256219603e+46 |                      |
| Geometric mean                 |                   2.48687157866749e+24 |                      |
| Harmonic mean                  |                                    400 |                      |
| Lowest consecutive ratio       |                                      3 |                      |
| Highest consecutive ratio      |                                      3 |                      |
| Avg. consecutive ratio         |                                      3 |                      |
| Lowest consecutive difference  |                                     12 |                      |
| Highest consecutive difference |                   6.87170027642682e+47 |                      |
| Avg. consecutive difference    |                   1.04116670854952e+46 |                      |
'--------------------------------+----------------------------------------+----------------------'

=> Summary:
    contains no primes
    all terms are in a strictly increasing order
    geometric sequence (ratio = 3)
    possible closed-form: 3^(n + log(6)/log(3) - 1)
    possible closed-form: 2 * 3^n
