#!perl -w
$|++;

use strict;
use Test::More tests => 48;

use lib "./t";
use _nrr_test_util;

use lib "./blib/lib";
use Number::Range::Regex qw ( range rangespec );
use Number::Range::Regex::Iterator;

my ($it, $range);

$range = range(4, 55);
ok($range);

$it = $range->iterator();
ok($it);
ok($it->isa('Number::Range::Regex::Iterator'));

# Iterator->new(...)->fetch == Iterator->new(...)->first->fetch
eval { $it->fetch }; ok(!$@);
ok($it->fetch == 4);

# check first and last
ok($it->first);
ok($it->fetch == 4);
ok($it->first->fetch == 4);
ok($it->last);
ok($it->fetch == 55);
ok($it->last->fetch == 55);

# prev()/next() not valid after going out of range
ok($it->first);
do {} while ($it->next);
eval { $it->next }; ok($@);
ok($it->first);
do {} while ($it->next);
eval { $it->prev }; ok($@);
ok($it->last);
do {} while ($it->prev);
eval { $it->next }; ok($@);
ok($it->last);
do {} while ($it->prev);
eval { $it->prev }; ok($@);

# one-liners involving new()
ok(Number::Range::Regex::Iterator->new( $range )->first->fetch == 4);
ok(Number::Range::Regex::Iterator->new( $range )->last->fetch == 55);

# some more one-liners
ok($it->first->next->next->fetch == 6);
ok($it->first->next->prev->next->fetch == 5);
ok($it->last->prev->prev->fetch == 53);
ok($it->last->prev->next->prev->fetch == 54);

$range = range( 3, 3 )->intersection( range( 4, 4 ) ); #empty range
ok($range);
eval { $it = $range->iterator(); };
ok($@); #can't iterate over an empty range

$range = rangespec('0,2,4,6,8');
ok($range);
$it = $range->iterator();
ok($it);
ok($it->isa('Number::Range::Regex::Iterator'));

# check first and last
ok($it->first->fetch == 0);
ok($it->last->fetch == 8);

ok( $it->first->fetch == 0);
ok( $it->next->fetch == 2);
ok( $it->next->fetch == 4);
ok( $it->next->fetch == 6);
ok( $it->next->fetch == 8);
eval { $it->next->fetch; }; ok($@);
ok( $it->last->fetch == 8);
ok( $it->prev->fetch == 6);
ok( $it->prev->fetch == 4);
ok( $it->prev->fetch == 2);
ok( $it->prev->fetch == 0);
eval { $it->prev->fetch; }; ok($@);

# test number of elements in a large iterator
$range = rangespec('1,10..19,100..199,1000..1999,10000..19999');
ok($range);
$it = $range->iterator();
ok($it);
ok($it->isa('Number::Range::Regex::Iterator'));
$it->first;
my $c = 0;
do { ++$c } while ($it->next);
ok($c == 11111);
