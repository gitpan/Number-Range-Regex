#!perl -w
$|++;

use strict;
use Test::More tests => 458;

use lib "./t";
use _nrr_test_util;

use lib "./blib/lib";
use Number::Range::Regex;

# test the code from the perldoc and some variations thereon
my $lt_20    = range( 0, 19 );
ok($lt_20);
my $lt_20_re = $lt_20->regex();
ok($lt_20_re);
ok( "the number is 17 and the color is orange" =~ /$lt_20_re/ );
ok( "the number is 17 and the color is orange" !~ /^$lt_20_re$/ );
ok( /$lt_20_re/ ) for (0..19);
ok( /^$lt_20_re$/ ) for (0..19);
ok(-1 !~ /^$lt_20_re$/);
ok(20 !~ /^$lt_20_re$/);
ok( "field1 17 rest of line" =~ /^\S+\s+$lt_20_re\s/ );
my $nice_numbers = rangespec( "42,175..192" );
my $special_values_re = $lt_20->union( $nice_numbers )->regex;
my $line = "field1 42 rest of line";
ok( $line =~ /^\S+\s+$special_values_re\s/ );

my $lt_10        = range( 0, 9 );
ok($lt_10);
my $primes_lt_30 = rangespec( "2,3,5,7,11,13,17,19,23,29" );
ok($primes_lt_30);
my $primes_lt_10 = $lt_10->intersection( $primes_lt_30 );
ok($primes_lt_10);
my $primes_lt_10_re = $primes_lt_10->regex;
ok($primes_lt_10_re);
ok( /^$primes_lt_10_re$/ ) for (2,3,5,7);
ok( !/^$primes_lt_10_re$/ ) for (0,1,4,6,8,9);
my $nonprimes_lt_10 = $lt_10->minus( $primes_lt_30 );
ok($nonprimes_lt_10);
my $nonprimes_lt_10_re = $nonprimes_lt_10->regex;
ok($nonprimes_lt_10_re);
ok( !/^$nonprimes_lt_10_re$/ ) for (2,3,5,7);
ok( /^$nonprimes_lt_10_re$/ ) for (0,1,4,6,8,9);
ok( !$nonprimes_lt_10->contains($_) ) for (2,3,5,7);
ok( $nonprimes_lt_10->contains($_) ) for (0,1,4,6,8,9);

my $octet = range(0, 255)->regex;
ok($octet);
ok( /^$octet$/ ) for (0..255);
my $ip4_match = qr/^$octet\.$octet\.$octet\.$octet$/;
ok($ip4_match);
ok( /^$ip4_match$/ ) for ("1.2.3.4", "74.125.228.5", "173.203.36.104" );
ok( !/^$ip4_match$/ ) for ("256.2.3.4", "1.256.3.4", "1.2.256.4", "1.2.3.256");
ok( !/^$ip4_match$/ ) for ("-1.2.3.4", "1.-1.3.4", "1.2.-1.4", "1.2.3.-1");
my $re_96_to_127 = range(96, 127)->regex;
ok($re_96_to_127);
ok( /^$re_96_to_127$/ ) for (96..127);
ok( !/^$re_96_to_127$/ ) for (95,128);
my $my_slash26_match = qr/^192\.168\.42\.$re_96_to_127$/;
ok($my_slash26_match);
ok( /^$my_slash26_match$/ ) for map { "192.168.42.$_" } ( 96..127 );
ok( !/^$my_slash26_match$/ ) for map { "192.168.42.$_" } ( 95,128 );
my $my_slash19_match = qr/^192\.168\.$re_96_to_127\.$octet$/;
ok($my_slash19_match);
ok( /^$my_slash19_match$/ ) for map { "192.168.$_.".int rand 255 } ( 96..127 );
ok( !/^$my_slash19_match$/ ) for map { "192.168.$_.".int rand 255 } ( 95,128 );


