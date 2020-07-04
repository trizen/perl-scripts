#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 03 July 2015
# Website: https://github.com/trizen

#
# The problem:
#
# Mix the stars with the letters in the following pattern,
# in a random, but uniform way, preserving the original order
# of letters and preserving the original shape of the pattern.
#

my $pattern = <<'EOT';
 ******C*******w*******X*******y*******X*******o*******f******
 igpvAoBLhCffXgIIlyI8gFC8L88vILCg98Io81gaICXpIIg8CIvwFB8I8wXgC
 vIAgLA,L>8CgCCyywcIiF>L=8LX='CgCLfgvC8wXgXKef9B8CIggvIALKXLCv
y>IgXIXg8w1}CA=y8ylAyw=8Cgyffy8loKK88A8f=,II'gfFFwfvgvCAC8yyLIg
KXf'''IAX=yiovg>C,8gIAgvAIXFjgCy8Xv89v'XIILy=AC1A8yvov9KvXywffX
8CFyCC9LvfCvF8gg$yv8vALIIILKsKXyvgCI8yfIKF8L,I9C8BiFwfg,A8h8gF'
BvgL8C8FfXCC8gB,Iv88AgC8X1CCIFuCX8L>Xi=CCv8ICI8I>KC8IFB8oIFKAvA
LvgCIg'wBAFLg'1''f=yLLI'ff'fo9gIA>yFv8FIoy'CLfI8f8vk'y8F=vw>gKf
vy8X        >KLXgKw'og'vF1By'gBvLIXX8KB'XvA'8vofilg        CgC'
fyBA           8iLIy8IoIvoC,yg,gI=yC8i'I8gL>8'9{           8gB>
AF18              I8A=vyA'1pfwv,I8lvIABACffIy              AyFC
1Avpg               Cv'KIyK8C'g9IyFKIL8A=vo               yCABX
Ffv8A                C,9wyIKI,Kn=iXf8wL1w9                8,ygf
X88oKC                 ICII8'F8ILCLy>>If                 CC8LCy
 XCAIg                  CFAwBvCfyAIgIyA                  BI9'g
 gyIwL8                  lgXIXXXAX8gI8                  8IBiyX
  FXAygA                  vgoFFFXAggC                  i,LI>I
   KIXgt                   vXCA8prCI                   gAK=y
   ******                  *********                  ******
    *******                 *******                 *******
     *******                *******                *******
      ********               *****               ********
       *********             *****             *********
        **********           *****           **********
         ************       *******       ************
          *******************************************
           *****************************************
            ***************************************
             *************************************
               *********************************
                *******************************
                 *****************************
                   *************************
                     *********************
                       *****************
                         *************
                           *********
EOT

#
## Solution
#

my @chars = split(//, $pattern);

my @letters = grep { $_ ne '*' and /^\S/ } @chars;
my @stars = grep { $_ eq '*' } @chars;

my $ratio = @stars / (@letters + @stars);

foreach my $char (@chars) {
    if ($char =~ /^\s/) {
        print $char;
        next;
    }

    if (@stars) {
        if (rand(1) <= $ratio) {
            print shift @stars;
            next;
        }
    }

    print @letters ? shift(@letters) : shift(@stars);
}
