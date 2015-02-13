#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 13 February 2015
# Website: https://github.com/trizen

# Analyze a CSV list of products based on their values.
# (the energy expressed in kcal/100g divided by the price/100g)

use 5.010;
use strict;
use autodie;
use warnings;
use Text::CSV;

my $input_file = shift() // 'products.csv';

sub process_products_file {
    my ($file) = @_;

    my $csv = Text::CSV->new(
                             {
                              allow_whitespace => 1,
                              sep_char         => ',',
                             }
                            )
      or die "Cannot use CSV: " . Text::CSV->error_diag();

    open my $fh, '<:encoding(UTF-8)', $file;

    my @columns = map { lc(s/\W.*//rs) } @{$csv->getline($fh)};
    $csv->column_names(@columns);

    my @products;
    while (my $row = $csv->getline_hr($fh)) {
        push @products, {%{$row}, value => $row->{kcal} / $row->{price}};
    }
    return @products;
}

my @products = process_products_file($input_file);
my @sorted_products = sort { $b->{value} <=> $a->{value} } @products;

foreach my $product (@sorted_products) {
    printf("%-35s%-10g%-10g(%g)\n", $product->{name}, $product->{kcal}, $product->{price}, $product->{value});
}
