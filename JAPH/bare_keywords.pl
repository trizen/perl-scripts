Just another Perl hacker

local+$,=$";package another;sub Just{print(substr((caller(0))[3],3**2),@_)}
package hacker;sub Perl{Just another((split/:./,(caller(0))[3])[1,0]),exit}
