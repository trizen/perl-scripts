#!/usr/bin/perl

use 5.014;

use Benchmark qw(cmpthese);

package Foo {

    sub new {
        bless {}, __PACKAGE__;
    }

    sub call_me { }

    sub bar {
        $_[0]->call_me(@_[1 .. $#_]);
    }

    sub baz {
        shift(@_)->call_me(@_);
    }
}

my $obj = Foo->new();

cmpthese(
    -1,
    {
     with_shift => sub {
         $obj->baz(1, 2, 3, 4, 5);
         $obj->baz();
         $obj->baz(1);
         $obj->baz(1, 2);
     },
     with_range => sub {
         $obj->bar(1, 2, 3, 4, 5);
         $obj->bar();
         $obj->bar(1);
         $obj->bar(1, 2);
     },
    }
);

__END__
                Rate with_range with_shift
with_range  721308/s         --       -33%
with_shift 1071850/s        49%         --
