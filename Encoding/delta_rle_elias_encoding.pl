#!/usr/bin/perl

# Implementation of Delta + Run-length + Elias coding, for encoding arbitrary integers.

# Reference:
#   Data Compression (Summer 2023) - Lecture 5 - Basic Techniques
#   https://youtube.com/watch?v=TdFWb8mL5Gk

use 5.036;

sub read_bit ($fh, $bitstring) {

    if (($$bitstring // '') eq '') {
        $$bitstring = unpack('b*', getc($fh) // return undef);
    }

    chop($$bitstring);
}

sub run_length ($arr) {

    @$arr || return [];

    my @result     = [$arr->[0], 1];
    my $prev_value = $arr->[0];

    foreach my $i (1 .. $#{$arr}) {

        my $curr_value = $arr->[$i];

        if ($curr_value eq $prev_value) {
            ++$result[-1][1];
        }
        else {
            push(@result, [$curr_value, 1]);
        }

        $prev_value = $curr_value;
    }

    return \@result;
}

sub DRE_encoding ($integers, $double = 0) {

    my @deltas;
    my $prev = 0;

    unshift(@$integers, scalar(@$integers));

    while (@$integers) {
        my $curr = shift(@$integers);
        push @deltas, $curr - $prev;
        $prev = $curr;
    }

    my $bitstring = '';
    my $rle       = run_length(\@deltas);

    foreach my $cv (@$rle) {
        my ($c, $v) = @$cv;

        if ($c == 0) {
            $bitstring .= '0';
        }
        elsif ($double) {
            my $t = sprintf('%b', abs($c));
            my $l = sprintf('%b', length($t) + 1);
            $bitstring .= '1' . (($c < 0) ? '0' : '1') . ('1' x (length($l) - 1)) . '0' . substr($l, 1) . substr($t, 1);
        }
        else {
            my $t = sprintf('%b', abs($c));
            $bitstring .= '1' . (($c < 0) ? '0' : '1') . ('1' x (length($t) - 1)) . '0' . substr($t, 1);
        }

        if ($v == 1) {
            $bitstring .= '0';
        }
        else {
            my $t = sprintf('%b', $v);
            $bitstring .= join('', '1' x (length($t) - 1), '0', substr($t, 1));
        }
    }

    pack('B*', $bitstring);
}

sub DRE_decoding ($bitstring, $double = 0) {

    open my $fh, '<:raw', \$bitstring;

    my @deltas;
    my $buffer = '';
    my $len    = 0;

    for (my $k = 0 ; $k <= $len ; ++$k) {
        my $bit = read_bit($fh, \$buffer) // last;

        if ($bit eq '0') {
            push @deltas, 0;
        }
        elsif ($double) {
            my $bit = read_bit($fh, \$buffer);

            my $bl = 0;
            ++$bl while (read_bit($fh, \$buffer) eq '1');

            my $bl2 = oct('0b1' . join('', map { read_bit($fh, \$buffer) } 1 .. $bl)) - 1;
            my $int = oct('0b1' . join('', map { read_bit($fh, \$buffer) } 1 .. ($bl2 - 1)));

            push @deltas, ($bit eq '1' ? $int : -$int);
        }
        else {
            my $bit = read_bit($fh, \$buffer);
            my $n   = 0;
            ++$n while (read_bit($fh, \$buffer) eq '1');
            my $d = oct('0b1' . join('', map { read_bit($fh, \$buffer) } 1 .. $n));
            push @deltas, ($bit eq '1' ? $d : -$d);
        }

        my $bl = 0;
        while (read_bit($fh, \$buffer) == 1) {
            ++$bl;
        }

        if ($bl > 0) {
            my $run = oct('0b1' . join('', map { read_bit($fh, \$buffer) } 1 .. $bl)) - 1;
            $k += $run;
            push @deltas, ($deltas[-1]) x $run;
        }

        if ($k == 0) {
            $len = pop(@deltas);
        }
    }

    my @acc;
    my $prev = $len;

    foreach my $d (@deltas) {
        $prev += $d;
        push @acc, $prev;
    }

    return \@acc;
}

my $str   = join('', 'a' x 13, 'b' x 14, 'c' x 10, 'd' x 3, 'e' x 1, 'f' x 1, 'g' x 4);
my @bytes = unpack('C*', $str);

my $enc = DRE_encoding(\@bytes);
my $dec = pack('C*', @{DRE_decoding($enc)});

say unpack('B*', $enc);
say $dec;

$dec eq $str or die "error: $dec != $str";

do {
    my @integers = map { int(rand($_)) } 1 .. 1000;
    my $str      = DRE_encoding([@integers], 1);

    say "Encoded length: ", length($str);
    say "Rawdata length: ", length(join(' ', @integers));

    my $decoded = DRE_decoding($str, 1);

    join(' ', @integers) eq join(' ', @$decoded) or die "Decoding error";

    {
        open my $fh, '<:raw', __FILE__;
        my $str     = do { local $/; <$fh> };
        my $encoded = DRE_encoding([unpack('C*', $str)], 1);
        my $decoded = DRE_decoding($encoded, 1);
        $str eq pack('C*', @$decoded) or die "error";
    }
  }

__END__
Encoded length: 1879
Rawdata length: 3628
