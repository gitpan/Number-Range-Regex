#!perl -w
$|++;

use strict;
use Test::More tests => 492;

use lib "./t";
use _nrr_test_util;

use lib "./blib/lib";
use Number::Range::Regex qw ( range rangespec );

my $er = Number::Range::Regex::EmptyRange->new();
ok($er); #in boolean context, should return the object
ok("$er" eq ""); #in string context, should return empty string
ok( !/^$er$/ ) for( 0,1,-1,"foo" ); #in regex context, a pattern that never matches
ok( !/$er/ ) for( 0,1,-1,"foo" ); #regex context (part 2)
my $er_re = qr/^$er$/;
ok($er_re ne ""); #make sure we don't get the empty string as regex

my $sr = Number::Range::Regex::SimpleRange->new( 2,44 );
ok($sr); #boolean context
ok("$sr" eq "2..44"); #string context
ok( !/^$sr$/ ) for( 0,1,45 ); #regex context
ok( /^$sr$/ ) for( 2..44 ); #regex context (part 2)
ok( !$sr->contains($_) ) for( 0,1,45 ); #as an object
ok( $sr->contains($_) ) for( 2..44 ); #as an object (part 2)
my $sr_re = qr/^$sr$/;
ok($sr_re ne "2..44"); #make sure we don't get the rangestring as regex

my $tr = Number::Range::Regex::TrivialRange->new( 130, 179, '1[3-7]\d' );
ok($tr); #boolean context
ok("$tr" eq "130..179"); #string context
ok( !/^$tr$/ ) for( 129,180 ); #regex context
ok( /^$tr$/ ) for( 130..179 ); #regex context (part 2)
ok( !$tr->contains($_) ) for( 129,180 ); #as an object
ok( $tr->contains($_) ) for( 130..179 ); #as an object (part 2)
my $tr_re = qr/^$tr$/;
ok($tr_re ne "130..179"); #make sure we don't get the rangestring as regex

my $cr = rangespec( "2..15,111..137" );
ok($cr); #boolean context
ok("$cr" eq "2..15,111..137"); #string context
ok( !/^$cr$/ ) for( 1,16..110,138 ); #regex context
ok( /^$cr$/ ) for( 2..15,111..137 ); #regex context (part 2)
ok( !$cr->contains($_) ) for( 1,16..110,138 ); #as an object
ok( $cr->contains($_) ) for( 2..15,111..137 ); #as an object (part 2)
my $cr_re = qr/^$cr$/;
ok($cr_re ne "2..15,111..137"); #make sure we don't get the rangestring as regex
