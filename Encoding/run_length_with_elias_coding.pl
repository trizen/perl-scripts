#!/usr/bin/perl

# Implementation of Run-length + Elias coding, for encoding arbitrary non-negative integers.

# References:
#   Data Compression (Summer 2023) - Lecture 5 - Basic Techniques
#   https://youtube.com/watch?v=TdFWb8mL5Gk
#
#   Data Compression (Summer 2023) - Lecture 6 - Delta Compression and Prediction
#   https://youtube.com/watch?v=-3H_eDbWNEU

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

sub RLEE_encoding ($integers, $double = 0) {

    my @symbols = (scalar(@$integers), @$integers);

    my $bitstring = '';
    my $rle       = run_length(\@symbols);

    foreach my $cv (@$rle) {
        my ($c, $v) = @$cv;

        if ($c == 0) {
            $bitstring .= '0';
        }
        elsif ($double) {
            my $t = sprintf('%b', abs($c) + 1);
            my $l = sprintf('%b', length($t));
            $bitstring .= '1' . ('1' x (length($l) - 1)) . '0' . substr($l, 1) . substr($t, 1);
        }
        else {
            my $t = sprintf('%b', abs($c));
            $bitstring .= '1' . ('1' x (length($t) - 1)) . '0' . substr($t, 1);
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

sub RLEE_decoding ($bitstring, $double = 0) {

    open my $fh, '<:raw', \$bitstring;

    my @values;
    my $buffer = '';
    my $len    = 0;

    for (my $k = 0 ; $k <= $len ; ++$k) {
        my $bit = read_bit($fh, \$buffer) // last;

        if ($bit eq '0') {
            push @values, 0;
        }
        elsif ($double) {
            my $bl = 0;
            ++$bl while (read_bit($fh, \$buffer) eq '1');

            my $bl2 = oct('0b1' . join('', map { read_bit($fh, \$buffer) } 1 .. $bl));
            my $int = oct('0b1' . join('', map { read_bit($fh, \$buffer) } 1 .. ($bl2 - 1)));

            push @values, $int - 1;
        }
        else {
            my $n = 0;
            ++$n while (read_bit($fh, \$buffer) eq '1');
            my $d = oct('0b1' . join('', map { read_bit($fh, \$buffer) } 1 .. $n));
            push @values, $d;
        }

        my $bl = 0;
        while (read_bit($fh, \$buffer) == 1) {
            ++$bl;
        }

        if ($bl > 0) {
            my $run = oct('0b1' . join('', map { read_bit($fh, \$buffer) } 1 .. $bl)) - 1;
            $k += $run;
            push @values, ($values[-1]) x $run;
        }

        if ($k == 0) {
            $len = pop(@values);
        }
    }

    return \@values;
}

my @symbols = (
               6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 1, 1, 3, 3, 1, 2, 3, 0, 0, 1, 2, 4, 2, 1, 0, 1, 2, 1, 1, 0, 0, 1
              );

my $enc = RLEE_encoding([@symbols]);
my $dec = RLEE_decoding($enc);

say unpack('B*', $enc);
say "@$dec";

"@$dec" eq "@symbols" or die "error";

do {
    my @integers = map { int(rand($_)) } 1 .. 1000;
    my $str      = RLEE_encoding([@integers], 1);

    say "Encoded length: ", length($str);
    say "Rawdata length: ", length(join(' ', @integers));

    my $decoded = RLEE_decoding($str, 1);

    join(' ', @integers) eq join(' ', @$decoded) or die "Decoding error";

    {
        open my $fh, '<:raw', __FILE__;
        my $str     = do { local $/; <$fh> };
        my $encoded = RLEE_encoding([unpack('C*', $str)], 1);
        my $decoded = RLEE_decoding($encoded, 1);
        $str eq pack('C*', @$decoded) or die "error";
    }
  }

__END__
111111100110010111010001111110000000110100010100110110010011000110100100100110001110000110001000010011000101000100100000
6 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 3 0 1 1 3 3 1 2 3 0 0 1 2 4 2 1 0 1 2 1 1 0 0 1
Encoded length: 1867
Rawdata length: 3606
