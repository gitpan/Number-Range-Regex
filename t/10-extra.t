#!perl -w
$|++;

use strict;
use Test::More 'no_plan';

use lib "./t";
use _nrr_test_util;

use lib "./blib/lib";
use Number::Range::Regex qw ( range rangespec );

ok(1);
