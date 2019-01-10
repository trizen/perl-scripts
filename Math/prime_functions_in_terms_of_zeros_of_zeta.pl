#!/usr/bin/perl

# Approximate the Chebyshev function and the weighted prime counting function, using zeros of the Riemann zeta function.

# See also:
#   https://oeis.org/A267712
#   https://en.wikipedia.org/wiki/Chebyshev_function
#   https://en.wikipedia.org/wiki/Logarithmic_integral_function
#   https://en.wikipedia.org/wiki/Riemann_zeta_function

use utf8;
use 5.020;
use strict;
use warnings;

binmode(STDOUT, ':utf8');

use ntheory qw(forprimes prime_count);
use experimental qw(signatures);
use Math::AnyNum qw(:overload gamma complex tau ilog iroot log Li harmreal);

my @zeta_ρ = map { chomp; complex(1 / 2, $_) } <DATA>;

sub Li_approx ($x) {

    my $sum = 0;
    foreach my $k (0 .. 0) {
        $sum += gamma($k + 1) / log($x)**$k;
    }

    return ($sum * ($x / log($x)));
}

sub chebyshev_ψ ($x) {

    my $sum = 0;
    forprimes {
        $sum += ilog($x, $_) * log($_)
    } $x;

    return $sum;
}

sub weighted_prime_count ($x) {
    my $sum = 0;

    foreach my $k (1 .. ilog($x, 2)) {
        $sum += Math::AnyNum->new(prime_count(iroot($x, $k))) / $k;
    }

    return $sum;
}

sub weighted_prime_count_from_zeta_zeros ($x) {
    my $sum = Li($x);

    foreach my $ρ (@zeta_ρ) {
        $sum -= Li_approx($x**$ρ);
    }

    return abs($sum - log(2));
}

sub chebyshev_ψ_from_zeta_zeros($x) {
    my $sum = $x - log(tau) - log(1 - $x**(-2)) / 2;

    foreach my $ρ (@zeta_ρ) {
        $sum -= $x**$ρ / $ρ;
    }

    return abs($sum);
}

my $x = 10**3;

say "ψ($x) = ", chebyshev_ψ($x);                    # 996.680912247175240263021765666421541665778436902
say "ψ($x) ≅ ", chebyshev_ψ_from_zeta_zeros($x);    # 996.068434632130345546023799228964726756917555651

say "\n=> Weighted prime count approximation: ";
foreach my $k (10 .. 14) {
    my $exact  = weighted_prime_count(10**$k);
    my $approx = weighted_prime_count_from_zeta_zeros(10**$k);
    say "Π(10^$k) = ", $exact->as_dec, " ≅ ", $approx, ' -> ', abs($exact - $approx);
}

__DATA__
14.1347251417346937904572519835624702707842571157
21.0220396387715549926284795938969027773343405249
25.0108575801456887632137909925628218186595496726
30.4248761258595132103118975305840913201815600237
32.9350615877391896906623689640749034888127156035
37.5861781588256712572177634807053328214055973508
40.9187190121474951873981269146332543957261659628
43.3270732809149995194961221654068057826456683718
48.0051508811671597279424727494275160416868440011
49.7738324776723021819167846785637240577231782997
52.9703214777144606441472966088809900638250178888
56.4462476970633948043677594767061275527822644717
59.3470440026023530796536486749922190310987728065
60.8317785246098098442599018245240038029100904512
65.1125440480816066608750542531837050293481492952
67.0798105294941737144788288965222167701071449517
69.5464017111739792529268575265547384430124742096
72.0671576744819075825221079698261683904809066215
75.7046906990839331683269167620303459228119035307
77.1448400688748053726826648563046370157960324492
79.3373750202493679227635928771162281906132467431
82.9103808540860301831648374947706094975088805938
84.7354929805170501057353112068277414171066279342
87.4252746131252294065316678509192132521718864013
88.8091112076344654236823480795093783954448934098
92.4918992705584842962597252418106848787217940277
94.6513440405198869665979258152081539377280270157
95.870634228245309758741029219246781695256461225
98.8311942181936922333244201386223278206580390634
101.317851005731391228785447940292308906332866384
103.725538040478339416398408108695280834481173069
105.446623052326094493670832414111808997282753929
107.168611184276407515123351963086191213476707881
111.02953554316967452465645030994435041534596839
111.874659176992637085612078716770594960311749873
114.320220915452712765890937276191079809917657724
116.226680320857554382160804312064755127329851232
118.790782865976217322979139702699824347306210593
121.370125002420645918945532970499922723001310632
122.946829293552588200817460330770016496214389874
124.256818554345767184732007966129924441573538775
127.516683879596495124279323766906076268088309882
129.578704199956050985768033906179973608640953265
131.087688530932656723566372461501349059203547503
133.497737202997586450130492042640607664974174944
134.756509753373871331326064157169736178396068614
138.116042054533443200191555190282447859835274624
139.736208952121388950450046523382460846790052565
141.12370740402112376194035381847535509030066088
143.11184580762063273940512386891392996623310243
146.000982486765518547402507596424682428975741233
147.42276534255960204952118501043150616877277525
150.05352042078488035143246723695937062303732156
150.925257612241466761852524678305627602426770473
153.024693811198896198256544255185446508590434904
156.112909294237867569750189310169194746535308501
157.597591817594059887530503158498765730723899519
158.849988171420498724174994775540271414335083049
161.188964137596027519437344129369554364915790327
163.030709687181987243311039000687994896964461416
165.537069187900418830038919354874797328367251745
167.184439978174513440957756246210378736460769243
169.09451541556882148950587118143183479666764858
169.911976479411698966699843595821792288394437125
173.411536519591552959846118649345595254156066063
174.754191523365725813378762455866917938755717621
176.441434297710418888892641057860933528118497109
178.377407776099977285830935414184426183132361461
179.916484020256996139340036612051237453687607553
182.207078484366461915407037226987798690797457778
184.874467848387508800960646617234258413351022912
185.59878367770747146652770426839264661293471765
187.228922583501851991641540586131243016810734604
189.416158656016937084852289099845324491357103023
192.026656360713786547283631425583430105839920298
193.079726603845704047402205794376054604020615811
195.265396679529235321463187814862250926905052452
196.876481840958316948622263914696207735746028692
198.015309676251912424919918702208867155062695439
201.264751943703788733016133427548173222402863639
202.493594514140534277686660637864315821020244899
204.189671803104554330716438386313685136534529229
205.394697202163286025212379390693090923722914772
207.906258887806209861501967907753644268659403769
209.576509716856259852835644289886752175390783181
211.690862595365307563907486730719294253394030983
213.347919359712666190639122021072608821897183277
214.547044783491423222944201072590691045599888053
216.169538508263700265869563354498128575453714274
219.067596349021378985677256590437241245149182927
220.714918839314003369115592633906339656761145078
221.430705554693338732097475119276077950222331077
224.00700025460433521172887552850489535608598995
224.983324669582287503782523680528656772090054486
227.421444279679291310461436160659639963969148322
229.337413305525348107760083306055740082752341388
231.250188700499164773806186770010372606708495843
231.987235253180248603771668539197862205419833995
233.693404178908300640704494732569788179537227755
236.524229665816205802475507955662978689529495212