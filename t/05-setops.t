#!perl -w
$|++;

use strict;
use Test::More tests => 84;

use lib "./t";
use _nrr_test_util;

use lib "./blib/lib";
use Number::Range::Regex;

my ($tr1, $tr2, $r1, $r2, $u, $i, $re);

$tr1 = Number::Range::Regex::TrivialRange->new(3, 9, '[3-9]');
ok($tr1);
$tr2 = Number::Range::Regex::TrivialRange->new(10, 11, '1[0-1]');
ok($tr2);
ok($tr1->touches($tr2));
$u = $tr1->union($tr2);
ok($u);
ok($u->isa('Number::Range::Regex::Range'));
$re = $u->regex;
ok($re);
ok(test_range_regex(3, 11, $re));

$tr1 = Number::Range::Regex::TrivialRange->new(100, 109, '10[0-9]');
ok($tr1);
$tr2 = Number::Range::Regex::TrivialRange->new(120, 129, '12[0-9]');
ok($tr2);
ok(!$tr1->touches($tr2));
$u = $tr1->union($tr2);
ok($u);
ok($u->isa('Number::Range::Regex::Range'));
$re = $u->regex;
ok($re);
ok(test_range_regex(100, 109, $re));
ok(test_range_regex(120, 129, $re));

# tr2 = 120..129
$tr1 = Number::Range::Regex::TrivialRange->new(110, 189, '1[1-8]\d');
ok($tr1);
ok($tr1->touches($tr2));
$u = $tr1->union($tr2);
ok($u);
ok($u->isa('Number::Range::Regex::TrivialRange'));
$re = $u->regex;
ok($re);
ok(test_range_regex(110, 189, $re));

# tr2 = 120..129
$tr1 = Number::Range::Regex::TrivialRange->new(190, 199, '19[0-9]');
ok($tr1);
ok(!$tr1->touches($tr2));
$u = $tr1->union($tr2);
ok($u);
ok($u->isa('Number::Range::Regex::Range'));
$re = $u->regex;
ok(test_range_regex(120, 129, $re));
ok(135 !~ /^$re$/);
ok(test_range_regex(190, 199, $re));

$r1 = Number::Range::Regex::Range->new_by_range(100, 109);
ok($r1);
$r2 = Number::Range::Regex::Range->new_by_range(110, 189);
ok($r2);
$u = $r1->union($r2);
ok($u);
ok($u->isa('Number::Range::Regex::Range'));
ok(1 == scalar @{$u->{ranges}});
$re = $u->regex;
ok($re);
ok(test_range_regex(100, 189, $re));

# r1 = 100..109
$r2 = Number::Range::Regex::Range->new_by_range(109, 189);
ok($r2);
$u = $r1->union($r2);
ok($u);
ok($u->isa('Number::Range::Regex::Range'));
ok(1 == scalar @{$u->{ranges}});
$re = $u->regex;
ok($re);
ok(test_range_regex(100, 189, $re));

# r1 = 100..109
$r2 = Number::Range::Regex::Range->new_by_range(111, 189);
ok($r2);
$u = $r1->union($r2);
ok($u);
ok($u->isa('Number::Range::Regex::Range'));
# should be something like: "10[0-9]", "11[1-9]", "1[2-8]\d"
ok(3 == scalar @{$u->{ranges}});
$re = $u->regex;
ok($re);
ok(test_range_regex(100, 109, $re));
ok(110 !~ /^$re$/);
ok(test_range_regex(111, 189, $re));

$r1 = Number::Range::Regex::Range->new_by_range(9725, 10033);
ok($r1);

$r2 = Number::Range::Regex::Range->new_by_range(10032, 10036);
ok($r2);
$u = $r1->union($r2);
ok($u);
ok($u->isa('Number::Range::Regex::Range'));
$re = $u->regex;
ok($re);
ok(test_range_regex(9725, 10036, $re));

$r2 = Number::Range::Regex::Range->new_by_range(10033, 10036);
ok($r2);
$u = $r1->union($r2);
ok($u);
ok($u->isa('Number::Range::Regex::Range'));
$re = $u->regex;
ok($re);
ok(test_range_regex(9725, 10036, $re));

$r2 = Number::Range::Regex::Range->new_by_range(10034, 10036);
ok($r2);
$u = $r1->union($r2);
ok($u);
ok($u->isa('Number::Range::Regex::Range'));
$re = $u->regex;
ok($re);
ok(test_range_regex(9725, 10036, $re));

$r2 = Number::Range::Regex::Range->new_by_range(10035, 10036);
ok($r2);
$u = $r1->union($r2);
ok($u);
ok($u->isa('Number::Range::Regex::Range'));
$re = $u->regex;
ok($re);
ok(10033 =~ /^$re$/);
ok(10034 !~ /^$re$/);
ok(10035 =~ /^$re$/);

$tr1 = Number::Range::Regex::TrivialRange->new(3, 9, '[3-9]');
ok($tr1);
$tr2 = Number::Range::Regex::TrivialRange->new(10, 11, '1[0-1]');
ok($tr2);
#note: touches, but does not intersect!
ok($tr1->touches($tr2));
$i = $tr1->intersection($tr2);
ok($i);
ok($i->isa('Number::Range::Regex::Range'));
$re = $i->regex;
ok(!$re);

# tr1 = 3..9
$tr2 = Number::Range::Regex::TrivialRange->new(6, 8, '[6-8]');
ok($tr2);
ok($tr1->touches($tr2));
$i = $tr1->intersection($tr2);
ok($i);
ok($i->isa('Number::Range::Regex::TrivialRange'));
$re = $i->regex;
ok($re);
ok(test_range_regex(6, 8, $re));

warn "TODO: full range intersect tests";
