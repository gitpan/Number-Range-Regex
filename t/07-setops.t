#!perl -w
$|++;

use strict;
use Test::More tests => 327;

use lib "./t";
use _nrr_test_util;

use lib "./blib/lib";
use Number::Range::Regex qw ( range rangespec );
use Number::Range::Regex::Util qw (multi_union );

my ($sr1, $sr2, $r1, $r2, $r, $re);

$sr1 = Number::Range::Regex::TrivialRange->new(3, 9, '[3-9]');
ok($sr1);
$sr2 = range(10, 11);
ok($sr2);
ok($sr1->touches($sr2));
$r = $sr1->union($sr2);
ok($r);
ok(check_type($r, 'Simple'));
$re = $r->regex;
ok($re);
ok(test_range_regex(3, 11, $re));
$r = $sr1->intersection($sr2);
ok($r);
ok(check_type($r, 'Empty'));
$re = $r->regex;
ok($re);
for my $c (2..12) {
  ok($c !~ /^$re$/);
}

# sr1 = 3..9
$sr2 = Number::Range::Regex::TrivialRange->new(6, 8, '[6-8]');
ok($sr2);
ok($sr1->touches($sr2));
$r = $sr1->union($sr2);
ok($r);
ok(check_type($r, 'Simple,Trivial'));
$re = $r->regex;
ok($re);
ok(test_range_regex(3, 9, $re));
$r = $sr1->intersection($sr2);
ok($r);
ok(check_type($r, 'Simple,Trivial'));
$re = $r->regex;
ok($re);
ok(test_range_regex(6, 8, $re));



$sr1 = Number::Range::Regex::TrivialRange->new(100, 109, '10[0-9]');
ok($sr1);
$sr2 = Number::Range::Regex::TrivialRange->new(120, 129, '12[0-9]');
ok($sr2);
ok(!$sr1->touches($sr2));
$r = $sr1->union($sr2);
ok($r);
ok(check_type($r, 'Compound'));
$re = $r->regex;
ok($re);
ok(test_range_regex(100, 109, $re));
ok(test_range_regex(120, 129, $re));
$r = $sr1->intersection($sr2);
ok($r);
ok(check_type($r, 'Empty'));
$re = $r->regex;
ok($re);
for my $c (99..130) {
  ok($c !~ /^$re$/);
}

# tr2 = 120..129
$sr1 = Number::Range::Regex::TrivialRange->new(110, 189, '1[1-8]\d');
ok($sr1);
ok($sr1->touches($sr2));
$r = $sr1->union($sr2);
ok($r);
ok(check_type($r, 'Simple,Trivial'));
$re = $r->regex;
ok($re);
ok(test_range_regex(110, 189, $re));
$r = $sr1->intersection($sr2);
ok($r);
ok(check_type($r, 'Simple,Trivial'));
$re = $r->regex;
ok($re);
ok(110 !~ /^$re$/);
ok(test_range_regex(120, 129, $re));
ok(130 !~ /^$re$/);

# tr2 = 120..129
$sr1 = Number::Range::Regex::TrivialRange->new(190, 199, '19[0-9]');
ok($sr1);
ok(!$sr1->touches($sr2));
$r = $sr1->union($sr2);
ok($r);
ok(check_type($r, 'Compound'));
$re = $r->regex;
ok(test_range_regex(120, 129, $re));
ok(135 !~ /^$re$/);
ok(test_range_regex(190, 199, $re));
$r = $sr1->intersection($sr2);
ok($r);
ok(check_type($r, 'Empty'));
$re = $r->regex;
ok($re);
for my $c (119..130,189..200) {
  ok($c !~ /^$re$/);
}

$r1 = range(100, 109);
ok($r1);
$r2 = range(110, 189);
ok($r2);
$r = $r1->union($r2);
ok($r);
ok(check_type($r, 'Simple'));
$re = $r->regex;
ok($re);
ok(test_range_regex(100, 189, $re));
$r = $r1->intersection($r2);
ok($r);
$re = $r->regex;
ok($re);
ok(check_type($r, 'Empty'));
for my $c (108..112) {
  ok($c !~ /^$re$/);
}

# r1 = 100..109
$r2 = range(109, 189);
ok($r2);
$r = $r1->union($r2);
ok($r);
ok(check_type($r, 'Simple'));
$re = $r->regex;
ok($re);
ok(test_range_regex(100, 189, $re));
$r = $r1->intersection($r2);
ok($r);
ok(check_type($r, 'Simple'));
$re = $r->regex;
ok($re);
ok(108 !~ /^$re$/);
ok(109 =~ /^$re$/);
ok(110 !~ /^$re$/);

# r1 = 100..109
$r2 = range(111, 189);
ok($r2);
$r = $r1->union($r2);
ok($r);
ok(check_type($r, 'Compound'));
$re = $r->regex;
# should be something like: "10[0-9]", "11[1-9]", "1[2-8]\d"
ok($re);
ok(test_range_regex(100, 109, $re));
ok(110 !~ /^$re$/);
ok(test_range_regex(111, 189, $re));
$r = $r1->intersection($r2);
ok($r);
ok(check_type($r, 'Empty'));
$re = $r->regex;
ok($re);
ok(108 !~ /^$re$/);
ok(109 !~ /^$re$/);
ok(110 !~ /^$re$/);
ok(111 !~ /^$re$/);
ok(112 !~ /^$re$/);

$r1 = range(9725, 10033);
ok($r1);
$r2 = range(10032, 10036);
ok($r2);
$r = $r1->union($r2);
ok($r);
ok(check_type($r, 'Simple'));
$re = $r->regex;
ok($re);
ok(test_range_regex(9725, 10036, $re));
$r = $r1->intersection($r2);
ok($r);
ok(check_type($r, 'Simple'));
$re = $r->regex;
ok($re);
ok(10031 !~ /^$re$/);
ok(10032 =~ /^$re$/);
ok(10033 =~ /^$re$/);
ok(10034 !~ /^$re$/);

# r1 = 9725..10033
$r2 = range(10033, 10036);
ok($r2);
$r = $r1->union($r2);
ok($r);
ok(check_type($r, 'Simple'));
$re = $r->regex;
ok($re);
ok(test_range_regex(9725, 10036, $re));
$r = $r1->intersection($r2);
ok($r);
ok(check_type($r, 'Simple'));
$re = $r->regex;
ok($re);
ok(10032 !~ /^$re$/);
ok(10033 =~ /^$re$/);
ok(10034 !~ /^$re$/);

# r1 = 9725..10033
$r2 = range(10034, 10036);
ok($r2);
$r = $r1->union($r2);
ok($r);
ok(check_type($r, 'Simple'));
$re = $r->regex;
ok($re);
ok(test_range_regex(9725, 10036, $re));
$r = $r1->intersection($r2);
ok($r);
ok(check_type($r, 'Empty'));
$re = $r->regex;
ok($re);
ok(10032 !~ /^$re$/);
ok(10033 !~ /^$re$/);
ok(10034 !~ /^$re$/);

# r1 = 9725..10033
$r2 = range(10035, 10036);
ok($r2);
$r = $r1->union($r2);
ok($r);
ok(check_type($r, 'Compound'));
$re = $r->regex;
ok($re);
ok(10033 =~ /^$re$/);
ok(10034 !~ /^$re$/);
ok(10035 =~ /^$re$/);
$r = $r1->intersection($r2);
ok($r);
ok(check_type($r, 'Empty'));
$re = $r->regex;
ok($re);
ok(10032 !~ /^$re$/);
ok(10033 !~ /^$re$/);
ok(10034 !~ /^$re$/);

$sr1 = range( 1, 7 );
$sr2 = range( 2, 11 );
$r = $sr1->minus( $sr2 );
ok($r);
ok(check_type($r, 'Simple'));
$re = $r->regex;
ok($re);
ok(0 !~ /^$re$/);
ok(1 =~ /^$re$/);
ok(2 !~ /^$re$/);
$r = $sr1->xor( $sr2 );
ok(check_type($r, 'Compound'));
$re = $r->regex;
ok($re);
ok(0 !~ /^$re$/);
ok(1 =~ /^$re$/);
ok(2 !~ /^$re$/);
ok(test_range_regex(8, 11, $re));
$r = $sr2->minus( $sr1 );
ok($r);
ok(check_type($r, 'Simple'));
$re = $r->regex;
ok($re);
ok(test_range_regex(8, 11, $re));
$r = $sr2->xor( $sr1 );
ok(check_type($r, 'Compound'));
$re = $r->regex;
ok($re);
ok(0 !~ /^$re$/);
ok(1 =~ /^$re$/);
ok(2 !~ /^$re$/);
ok(test_range_regex(8, 11, $re));

# sr1 = 1..7
$sr2 = range( 2, 6 );
$r = $sr1->minus( $sr2 );
ok($r);
ok(check_type($r, 'Compound'));
$re = $r->regex;
ok($re);
ok(0 !~ /^$re$/);
ok(1 =~ /^$re$/);
ok(2 !~ /^$re$/);
ok(6 !~ /^$re$/);
ok(7 =~ /^$re$/);
ok(8 !~ /^$re$/);
$r = $sr1->xor( $sr2 );
ok(check_type($r, 'Compound'));
$re = $r->regex;
ok($re);
ok(0 !~ /^$re$/);
ok(1 =~ /^$re$/);
ok(2 !~ /^$re$/);
ok(6 !~ /^$re$/);
ok(7 =~ /^$re$/);
ok(8 !~ /^$re$/);
$r = $sr2->minus( $sr1 );
ok($r);
ok(check_type($r, 'Empty'));
$re = $r->regex;
ok($re);
for my $c (0..8) {
  ok($c !~ /^$re$/);
}
$r = $sr1->xor( $sr2 );
ok(check_type($r, 'Compound'));
$re = $r->regex;
ok($re);
ok(0 !~ /^$re$/);
ok(1 =~ /^$re$/);
ok(2 !~ /^$re$/);
ok(6 !~ /^$re$/);
ok(7 =~ /^$re$/);
ok(8 !~ /^$re$/);

# tests of compound ranges
my $mul2 = rangespec(0,2,4,6,8); #multi_union( map { range($_, $_) } (0,2,4,6,8));
my $mul3 = rangespec("0,3,6,9"); #multi_union( map { range($_, $_) } (0,3,6,9));

$r = $mul2->union($mul3);
ok($r);
$re = $r->regex;
ok($re);
ok( $_ =~ /^$re$/ ) for ( 0,2,3,4,6,8,9 );
ok( $_ !~ /^$re$/ ) for ( 1,5,7 );

$r = $mul2->intersection($mul3);
ok($r);
$re = $r->regex;
ok($re);
ok( $_ =~ /^$re$/ ) for ( 0,6 );
ok( $_ !~ /^$re$/ ) for ( 1..5,7..9 );

$r = $mul2->minus($mul3);
ok($r);
$re = $r->regex;
ok($re);
ok( $_ =~ /^$re$/ ) for ( 2,4,8 );
ok( $_ !~ /^$re$/ ) for ( 0,1,3,5..7,9 );

$r = $mul3->minus($mul2);
ok($r);
$re = $r->regex;
ok($re);
ok( $_ =~ /^$re$/ ) for ( 3,9 );
ok( $_ !~ /^$re$/ ) for ( 0..2,4..8 );

$r = $mul3->xor($mul2);
ok($r);
$re = $r->regex;
ok($re);
ok( $_ =~ /^$re$/ ) for ( 2,3,4,8,9 );
ok( $_ !~ /^$re$/ ) for ( 0,1,5..7 );

#TODO: need more xor tests on SimpleRanges

