use Lingua::Translit;
my $tr = new Lingua::Translit('DIN 1460 RUS');
print $tr->translit(@ARGV ? shift : join'',<>);
