#!/usr/bin/perl

$\ = "\n";
my $prime = 0;
my $limit = shift() || 100;

while ($prime++ < $limit) {
    $_ .= 0;

    print $prime if $prime > 1 and not /^(00+?)\1+$/;

    # How it works?
    # When length(${^MATCH}) is not equal to length($_), then is a prime number
    # Uncomment the following lines to see how it actually works...

#    if(/^(00+?)\1+$/p){
#        print "number = $prime\ndolar1 = $1 (",length($1),")\n\$& = $& (",length(${^MATCH}),")\n\$_ = $_ (",length($_),")\n\n";
#    }elsif(!/^(00+?)\1+$/p){
#        print "number = $prime\ndolar1 = $1 (",length($1),")\n\$& = $& (",length(${^MATCH}),")\n\$_ = $_ (",length($_),")\n\n";
#    }

}
