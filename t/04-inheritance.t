#!perl -w
$|++;

use strict;
use Test::More tests => 27;

use lib "./t";
use _nrr_test_util;

use lib "./blib/lib";
use Number::Range::Regex;

my $r;

# note: we redundantly check with check_type too, just to make sure
#       check_type didn't get broken

$r = Number::Range::Regex::EmptyRange->new();
ok($r->isa('Number::Range::Regex::Range'));
ok($r->isa('Number::Range::Regex::EmptyRange'));
ok(!$r->isa('Number::Range::Regex::CompoundRange'));
ok(!$r->isa('Number::Range::Regex::SimpleRange'));
ok(!$r->isa('Number::Range::Regex::TrivialRange'));
ok(check_type($r, 'Empty'));

$r = Number::Range::Regex::SimpleRange->new( 3, 4 );
ok($r->isa('Number::Range::Regex::Range'));
ok(!$r->isa('Number::Range::Regex::EmptyRange'));
ok(!$r->isa('Number::Range::Regex::CompoundRange'));
ok($r->isa('Number::Range::Regex::SimpleRange'));
ok(!$r->isa('Number::Range::Regex::TrivialRange'));
ok(check_type($r, 'Simple'));

$r = $r->union( Number::Range::Regex::SimpleRange->new( 7, 11 ) );
ok($r->isa('Number::Range::Regex::Range'));
ok(!$r->isa('Number::Range::Regex::EmptyRange'));
ok($r->isa('Number::Range::Regex::CompoundRange'));
ok(!$r->isa('Number::Range::Regex::SimpleRange'));
ok(!$r->isa('Number::Range::Regex::TrivialRange'));
ok(check_type($r, 'Compound'));

$r = Number::Range::Regex::TrivialRange->new( 5, 8 );
ok($r->isa('Number::Range::Regex::Range'));
ok(!$r->isa('Number::Range::Regex::EmptyRange'));
ok(!$r->isa('Number::Range::Regex::CompoundRange'));
ok($r->isa('Number::Range::Regex::SimpleRange'));
ok($r->isa('Number::Range::Regex::TrivialRange'));
ok(check_type($r, 'Simple,Trivial'));

# some sanity checking of various other ways to call check_type
ok(check_type($r, ( qw ( Simple Trivial ) ) ));
ok(check_type($r, 'Simple, Trivial'));
ok(check_type($r, 'Simple , Trivial'));
