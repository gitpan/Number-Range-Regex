#!perl -w
$|++;

use strict;
use Test::More tests => 28;

use lib "./t";
use _nrr_test_util;

use lib "./blib/lib";
use Number::Range::Regex qw ( range rangespec );

my ($r, $re);

$r = range( 3, 4 );
check_type($r, 'Simple');
ok(test_rangeobj_exhaustive($r));

$r = rangespec( "3" );
check_type($r, 'Simple');
ok(test_rangeobj_exhaustive($r));

$r = rangespec( "3..6" );
check_type($r, 'Simple');
ok(test_rangeobj_exhaustive($r));

$r = rangespec( "3,6" );
check_type($r, 'Compound');
$re = $r->regex;
map { ok( $_ =~ /^$re$/ ) } ( 3,6 );
map { ok( $_ !~ /^$re$/ ) } ( 2,4,5,7 );

$r = rangespec( "3..6,9" );
check_type($r, 'Compound');
$re = $r->regex;
map { ok( $_ =~ /^$re$/ ) } ( 3..6,9 );
map { ok( $_ !~ /^$re$/ ) } ( 2,7..8 );

$r = rangespec( "3..6,9..11" );
check_type($r, 'Compound');
$re = $r->regex;
map { ok( $_ =~ /^$re$/ ) } ( 3..6,9..11 );
map { ok( $_ !~ /^$re$/ ) } ( 2,7..8,12 );

