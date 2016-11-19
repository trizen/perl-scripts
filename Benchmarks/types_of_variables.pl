#!/usr/bin/perl

# Performance comparison between `state`, `my` and global variables.

use 5.010;
use Benchmark qw(cmpthese);

cmpthese(
    -1,
    {
     my => sub {
         my $x = rand();
         $x + 1;
     },
     state => sub {
         state $x;
         $x = rand();
         $x + 1;
     },
     global => sub {
         $main::global = rand();
         $main::global + 1;
     }
    }
);


__END__
             Rate     my global  state
my     12105605/s     --   -17%   -44%
global 14563555/s    20%     --   -32%
state  21462081/s    77%    47%     --
