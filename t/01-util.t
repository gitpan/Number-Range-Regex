#!perl -w
$|++;

use strict;
use Test::More tests => 64;

use lib "./t";
use _nrr_test_util;

use lib "./blib/lib";
use Number::Range::Regex::Util ':all';
use Number::Range::Regex::Util::inf ':all';

# first, make sure _cmp didn't break basic <=> functionality
ok( _cmp(-1, -1) == 0 );
ok( _cmp(-1, 0)  == -1 );
ok( _cmp(-1, 1)  == -1 );
ok( _cmp(0, -1)  == 1 );
ok( _cmp(0, 0)   == 0 );
ok( _cmp(0, 1)   == -1 );
ok( _cmp(1, -1)  == 1 );
ok( _cmp(1, 0)   == 1 );
ok( _cmp(1, 1)   == 0 );
# now check some infinite values
ok( _cmp('-inf', '-inf') == 0 );
ok( _cmp('-inf', 0)      == -1 );
ok( _cmp('-inf', '+inf') == -1 );
ok( _cmp(0, '-inf')      == 1 );
ok( _cmp(0, 0)           == 0 );
ok( _cmp(0, '+inf')      == -1 );
ok( _cmp('+inf', '-inf') == 1 );
ok( _cmp('+inf', 0)      == 1 );
ok( _cmp('+inf', '+inf') == 0 );
# finally make sure _lt/_le/_ge/_gt work as expected
ok( ! _lt(0, -1) );
ok( ! _lt(0, 0) );
ok( _lt(0, 1) );
ok( ! _lt(0, '-inf') );
ok( ! _lt(0, 0) );
ok( _lt(0, '+inf') );
ok( ! _le(0, -1) );
ok( _le(0, 0) );
ok( _le(0, 1) );
ok( ! _le(0, '-inf') );
ok( _le(0, 0) );
ok( _le(0, '+inf') );
ok( _ge(0, -1) );
ok( _ge(0, 0) );
ok( ! _ge(0, 1) );
ok( _ge(0, '-inf') );
ok( _ge(0, 0) );
ok( ! _ge(0, '+inf') );
ok( _gt(0, -1) );
ok( ! _gt(0, 0) );
ok( ! _gt(0, 1) );
ok( _gt(0, '-inf') );
ok( ! _gt(0, 0) );
ok( ! _gt(0, '+inf') );

ok( -3 == most { $a == -3 ? 1 : undef } ( 42, -3, 22 ) );
ok( 22 == most { $a == 22 ? 1 : undef } ( 42, -3, 22 ) );
ok( 42 == most { $a == 42 ? 1 : undef } ( 42, -3, 22 ) );

ok( -41    == min( -3, 6,     42,    -41, 17 ) );
ok(  42    == max( -3, 6,     42,    -41, 17 ) );
ok( -41    == min( -3, 6, '+inf',    -41, 17 ) );
ok(  42    == max( -3, 6,     42, '-inf', 17 ) );
ok( '-inf' == min( -3, 6, '+inf', '-inf', 17 ) );
ok( '+inf' == max( -3, 6, '+inf', '-inf', 17 ) );

ok( _eq($_, $_) ) for (-3, 0, 7, '-inf', '+inf');
ok( _ne(3, 4) );
ok( _ne(-1, 2) );
ok( _ne('-inf', '+inf') );
ok( _ne('+inf', '-inf') );
ok( _ne('-inf', 12) );
ok( _ne('+inf', 12) );
ok( _ne('-inf', -12) );
ok( _ne('+inf', -12) );

# note: option_mangler, multi_union, has_re_overloading tested elsewhere
