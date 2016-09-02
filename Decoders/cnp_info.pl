#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 11 October 2012
# https://github.com/trizen

# CNP info

# See also:
#   http://ro.wikipedia.org/wiki/Cod_numeric_personal

use 5.010;
use strict;
use warnings;

sub usage {
    die "usage: $0 CNP\n";
}

my @cnp = split //, shift // usage();

(@cnp != 13 || join(q{}, @cnp) =~ /[^0-9]/) && die "Invalid CNP!\n";

my @magic = qw(2 7 9 1 4 6 3 5 8 2 7 9);

my %year_num = (
                1 => {era => 1900,},
                2 => {era => 1900,},
                3 => {era => 1800,},
                4 => {era => 1800,},
                5 => {era => 2000,},
                6 => {era => 2000,},
                7 => {
                      era => 0,
                      cet => "Străin rezident în România",
                     },
                8 => {
                      era => 0,
                      cet => "Străin rezident în România",
                     },
                9 => {
                      era => 0,
                      cet => "Persoană străină",
                     }
               );

my %jud = (
           '01' => 'Alba',
           '02' => 'Arad',
           '03' => 'Argeș',
           '04' => 'Bacău',
           '05' => 'Bihor',
           '06' => 'Bistrița-Năsăud',
           '07' => 'Botoșani',
           '08' => 'Brașov',
           '09' => 'Brăila',
           '10' => 'Buzău',
           '11' => 'Caraș-Severin',
           '12' => 'Cluj',
           '13' => 'Constanța',
           '14' => 'Covasna',
           '15' => 'Dâmbovița',
           '16' => 'Dolj',
           '17' => 'Galați',
           '18' => 'Gorj',
           '19' => 'Harghita',
           '20' => 'Hunedoara',
           '21' => 'Ialomița',
           '22' => 'Iași',
           '23' => 'Ilfov',
           '24' => 'Maramureș',
           '25' => 'Mehedinți',
           '26' => 'Mureș',
           '27' => 'Neamț',
           '28' => 'Olt',
           '29' => 'Prahova',
           '30' => 'Satu Mare',
           '31' => 'Sălaj',
           '32' => 'Sibiu',
           '33' => 'Suceava',
           '34' => 'Teleorman',
           '35' => 'Timiș',
           '36' => 'Tulcea',
           '37' => 'Vaslui',
           '38' => 'Vâlcea',
           '39' => 'Vrancea',
           '40' => 'București',
           '41' => 'București S.1',
           '42' => 'București S.2',
           '43' => 'București S.3',
           '44' => 'București S.4',
           '45' => 'București S.5',
           '46' => 'București S.6',
           '51' => 'Călărași',
           '52' => 'Giurgiu',
          );

my @months = qw(
  Ianuarie
  Februarie
  Martie
  Aprilie
  Mai
  Iunie
  Iulie
  August
  Septembrie
  Octombrie
  Noiembrie
  Decembrie
  );

my %days;
@days{@months} = qw(
  31
  29
  31
  30
  31
  30
  31
  31
  30
  31
  30
  31
  );

my $sum = 0;
$sum += $magic[$_] * $cnp[$_] for 0 .. $#magic;

my $cc = $sum % 11;
$cc = 1 if $cc == 10;

if ($cc != $cnp[-1]) {
    die "Cifra de control e incorectă!\n";
}

my $hash_ref = $year_num{$cnp[0]};

my $year_num  = "$cnp[1]$cnp[2]";
my $month_num = "$cnp[3]$cnp[4]";
my $day_num   = "$cnp[5]$cnp[6]";
my $jud_num   = "$cnp[7]$cnp[8]";

if ($month_num < 1 or $month_num > 12) {
    die "Luna de naștere e invalidă!\n";
}

my $cur_day  = [localtime]->[3];
my $cur_mon  = [localtime]->[4] + 1;
my $cur_year = [localtime]->[5];

my $nationality = "Română";
if ($hash_ref->{era} == 0) {
    $hash_ref->{era} = $year_num < $cur_year - 100 ? 2000 : 1900;
    $nationality = $hash_ref->{cet} // 'Necunoscută';
}

my $birth_year = $hash_ref->{era} + $year_num;
my $month_name = $months[$month_num - 1];

if ($day_num > $days{$month_name} or $day_num < 1) {
    die "Ziua de naștere e invalidă!\n";
}

my $jud_name = $jud{$jud_num} // die "Codul județului e invalid!\n";

if ($month_num == 2 and $day_num == 29) {
    die "Anul $birth_year nu a fost un an bisect!\n"
      if not($birth_year % 400 == 0 or $birth_year % 4 == 0 and $birth_year % 100 != 0);
}

my $age = $cur_year + 1900 - $birth_year;
if ($cur_mon < $month_num or ($month_num == $cur_mon and $day_num < $cur_day)) {
    --$age;
}

my $gender =
  $cnp[0] == 9
  ? "Necunoscut"
  : ("Feminin", "Masculin")[$cnp[0] % 2];

printf <<"EOF",
Data Nașterii:  %s
Cetațenie:      %s
Sexul:          %s
Vârsta:         %s
Județul:        %s
EOF
  "$day_num $month_name $birth_year", $nationality, $gender, $age, $jud_name;
