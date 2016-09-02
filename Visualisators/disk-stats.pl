#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 30 January 2013
# https://github.com/trizen

# Show disk and RAM usage.

use 5.010;
use strict;
use warnings;

use List::Util qw(max);
use Term::ANSIColor qw(colored color);
use Number::Bytes::Human qw(format_bytes);

my %CONFIG = (DF_COMMAND => 'df -Th');

sub get_ram {

    # RAM
    my $freeram   = 0;
    my $totalram  = 0;
    my $match_ram = qr/:\s+(\d+)/;

    {
        open my $ram_fh, '<', '/proc/meminfo';
        while (defined(my $ram_line = <$ram_fh>)) {
            $totalram = $1 / 1024 if $. == 1 and $ram_line =~ /$match_ram/o;
            $freeram += $1 / 1024 if $. > 1  and $ram_line =~ /$match_ram/o;
            last if $. == 4;
        }
        close $ram_fh;
    }

    my $usedram      = $totalram - $freeram;
    my $used_percent = $usedram / $totalram * 100;

    return
      scalar {
              name         => "/dev/mem",
              used         => format_bytes($usedram * 1024**2),
              total        => format_bytes($totalram * 1024**2),
              used_percent => $used_percent,
             };
}

sub get_partitions {
    my @partitions;
    open my $df_pipe, '-|', $CONFIG{DF_COMMAND};
    while (defined($df_pipe) and defined(my $line = <$df_pipe>)) {
        chomp($line);

        my (undef, $type, $totalsize, $used, undef, $used_percent, $mountpoint) = split(' ', $line, 7);
        $used_percent =~ s/^\d+\K%\z// or next;

        #$mountpoint =
        #    $mountpoint eq '/' ? 'Root'
        #  : $mountpoint =~ m{^.*/}s ? ucfirst substr($mountpoint, $+[0])
        #  :                           ucfirst $mountpoint;

        push @partitions,
          scalar {
                  name         => $mountpoint,
                  used_percent => $used_percent,
                  total        => $totalsize,
                  used         => $used,
                 };
    }
    close $df_pipe;

    my %seen;
    return grep { !$seen{join $;, %{$_}}++ } @partitions;
}

my @data = (get_ram(), get_partitions());

my %data;
push @{$data{names}}, map { $_->{name} } @data;
push @{$data{usage}}, map { "$_->{used}/$_->{total}" } @data;

my $left_cut  = max(map { length } @{$data{names}});
my $right_cut = max(map { length } @{$data{usage}});

my $width = (split(' ', `stty size`))[1];

foreach my $i (0 .. $#data) {

    my $hash_ref = $data[$i];
    my $barw     = $width - ($left_cut + $right_cut + 2);
    my $used     = sprintf "%.0f", $barw * ($hash_ref->{used_percent} / 100);

    my $bar   = '';
    my $pos   = 0;
    my $bleft = 0;

    my @colors = ([50, 'green'], [80, 'yellow'], [100, 'red']);
    until ($bleft >= $used) {
        my ($size, $color) = @{shift @colors};

        my $barsize = sprintf "%.0f",
          $hash_ref->{used_percent} > $size ? (($size - $pos) / 100 * $barw) : ($used - $bleft);

        $bar .= colored('>' x $barsize, "bold $color");
        $pos   += $size;
        $bleft += $barsize;
    }

    printf "%s%-${left_cut}s%s[%s%s]%s%${right_cut}s%s\n", color('bright_blue'), $data{names}[$i], color('reset'),
      $bar, " " x ($barw - $used), color('green'), $data{usage}[$i], color('reset');
}
