#!perl -w
$|++;

use strict;
use Test::More 'no_plan';

use lib "./t";
use _nrr_test_util;

use lib "./blib/lib";
use Number::Range::Regex;

my ($r1, $r2);
$r1 = rangespec('-inf..+inf', {allow_wildcard => 1});
ok($r1);
$r2 = range(undef, undef, {allow_wildcard => 1});
ok($r2);
