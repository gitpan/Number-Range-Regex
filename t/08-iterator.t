#!perl -w
$|++;

use strict;
use Test::More tests => 25;

use lib "./t";
use _nrr_test_util;

use lib "./blib/lib";
use Number::Range::Regex qw ( range rangespec );
use Number::Range::Regex::Iterator;

my ($it, $range);

$range = range(4, 55);
ok($range);

$it = Number::Range::Regex::Iterator->new($range);
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
