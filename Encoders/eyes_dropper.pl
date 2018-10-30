#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Created on: 01 July 2011 (00:01 AM)
# Latest edit on: 24 December 2011

# Transforms a phrase in a Perl regex, using only punctuation characters.

use strict;
use warnings;

use List::Util ('shuffle');

my $phrase;
my @content;
my %chars_table;

my $quote       = 0;
my $compact     = 0;
my $exec_code   = 0;
my $eval_code   = 0;
my $brake_after = 8;

my @symbols = shuffle(qw'^ + " * [ & | < ` / { > ; : ( ) ? - = } @ . ] $ _ % !', (',', '#'));

foreach my $arg (@ARGV) {

    if (-f $arg) {
        open my $fh, '<', $arg or die $!;
        sysread $fh, $phrase, -s $arg;
        close $fh;
        next;
    }

    if (substr($arg, 0, 1) eq '-') {

        if ($arg =~ /^-+(?:h|help|usage|\?)$/) {
            usage();
        }
        elsif ($arg =~ /^-+exec(?:ute)?$/) {
            $exec_code = 1;
        }
        elsif ($arg =~ /^-+e(?:val)?$/) {
            $eval_code = 1;
        }
        elsif ($arg =~ /^-+e(?:val)?2$/) {
            $eval_code = 2;
        }
        elsif ($arg =~ /^-+c(?:ompact)?$/) {
            $compact = 1;
        }
        elsif ($arg =~ /^-+q(?:uote(?:meta)?)?$/) {
            $quote = 1;
        }
        elsif ($arg =~ /^-+(\d+)$/) {
            $brake_after = $1;
        }
    }
}

unless (defined $phrase) {
    $phrase =
      grep({ chr ord $_ ne '-' } @ARGV)
      ? join(' ', grep({ chr ord $_ ne '-' } @ARGV))
      : 'Just another Perl hacker,';
}

sub usage {
    print "
usage: $0 [...]
\noptions:
         /my/file  : encode text from a file
         -num      : newline before N chars (ex: -10)
         -exec     : execute code (unix only)
         -print    : print text using single quotes (default)
         -eval     : eval code using single quotes
         -eval2    : eval code using a code block
         -compact  : compact code (not for files)
         -quote    : quotemeta special characters\n\n";
    exit;
}

my $char_to_quote = $quote ? qr/['\\{}]/ : qr/['\\]/;
my $action;

if ($exec_code) {
    $action = q[$x='/tmp/.x';open my $fh,">$x";system qq|perl $x| if print $fh];
}
elsif ($eval_code) {
    $action = 'eval';
}
else {
    $action = 'print';
}

if ($compact) {
    $phrase =~ s/~/\\~/g;
    $phrase = "$action q~$phrase\n";
}
elsif (defined $action and not $eval_code == 2) {
    push @content, qq[use re 'eval';'\n'=~('(?{'.];
    $phrase = "$action <<'Q_M';\n$phrase\nQ_M\n";
}
elsif (defined $action and $eval_code == 2) {
    push @content, q[''=~('(?{'.];
    $phrase = "${action} {$phrase}";
}

my %memoize;

LOOP_1: foreach my $letter (split(//, $phrase, 0)) {

    if (exists $chars_table{$letter}) {
        next LOOP_1 if $chars_table{$letter} eq 'Not found!';
        $compact ? push(@content, $chars_table{$letter})
          : (
             ref($chars_table{$letter}) eq 'ARRAY'
             ? push(@content, "('$chars_table{$letter}[0]'^'$chars_table{$letter}[1]').")
             : push(@content, $chars_table{$letter})
            );
        next LOOP_1;
    }

    foreach my $simb (@symbols) {
        foreach my $chr (@symbols) {

            next if exists $memoize{$simb . $chr};
            next if exists $memoize{$chr . $simb};

            ++$memoize{$simb . $chr};
            ++$memoize{$chr . $simb};

            $chars_table{$simb ^ $chr} = [$simb, $chr];

            if (exists $chars_table{$letter}) {
                if ($compact) {
                    push @content, [$simb, $chr];
                    next LOOP_1;
                }
                else {
                    push @content, "('${simb}'^'${chr}').";
                    next LOOP_1;
                }
            }
        }
    }

    if (not $compact) {
        $letter = quotemeta $letter if $letter =~ /$char_to_quote/o;
        push @content, "('${letter}').";
        $chars_table{$letter} = "('${letter}').";
    }
    else {
        $chars_table{$letter} = 'Not found!';
    }
}

if ($compact) {
    print q[''=~('(?{'.('], map({ $content[$_][0] } 0 .. $#content), q['^'],
      map({ $content[$_][1] } 0 .. $#content), q[').'~})');], "\n";
}
else {
    for (my $i = $brake_after - 1 ; $i <= $#content ; $i += $brake_after) {
        splice @content, $i, 0, "\n";
    }
    print @content, "'})');\n";
}
