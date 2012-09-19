#!perl -w
$|++;

use strict;
use Test::More tests => 89;

use lib "./t";
use _nrr_test_util;

use lib "./blib/lib";
use Number::Range::Regex;

my $tr_1XX = Number::Range::Regex::TrivialRange->new(100, 199, '1\d{2}');
ok(test_rangeobj_exhaustive($tr_1XX));
my $tr_12X = Number::Range::Regex::TrivialRange->new(120, 129, '12\d');
ok(test_rangeobj_exhaustive($tr_12X));
my $tr_14X = Number::Range::Regex::TrivialRange->new(140, 149, '14\d');
ok(test_rangeobj_exhaustive($tr_14X));
my $tr_100_to_149 = Number::Range::Regex::TrivialRange->new(100, 149, '1[0-4]\d');
ok(test_rangeobj_exhaustive($tr_100_to_149));
my $tr_130_to_179 = Number::Range::Regex::TrivialRange->new(130, 179, '1[3-7]\d');
ok(test_rangeobj_exhaustive($tr_130_to_179));

my ($range, $c, $re);

# self is superset
$range = $tr_1XX->union($tr_12X);
$re = $range->regex;
ok($range);
ok($re);
ok($range->isa('Number::Range::Regex::TrivialRange'));
ok($range->{min} == $tr_1XX->{min});
ok($range->{max} == $tr_1XX->{max});
ok(99  !~ /^$re$/);
ok(100 =~ /^$re$/);
ok(119 =~ /^$re$/);
ok(120 =~ /^$re$/);
ok(125 =~ /^$re$/);
ok(129 =~ /^$re$/);
ok(130 =~ /^$re$/);
ok(150 =~ /^$re$/);
ok(199 =~ /^$re$/);
ok(200 !~ /^$re$/);

# other is superset
$range = $tr_12X->union($tr_1XX);
$re = $range->regex;
ok($range);
ok($re);
ok($range->isa('Number::Range::Regex::TrivialRange'));
ok($range->{min} == $tr_1XX->{min});
ok($range->{max} == $tr_1XX->{max});
ok(99  !~ /^$re$/);
ok(100 =~ /^$re$/);
ok(119 =~ /^$re$/);
ok(120 =~ /^$re$/);
ok(125 =~ /^$re$/);
ok(129 =~ /^$re$/);
ok(130 =~ /^$re$/);
ok(150 =~ /^$re$/);
ok(199 =~ /^$re$/);
ok(200 !~ /^$re$/);

# overlap with an other that is higher
$range = $tr_100_to_149->union($tr_130_to_179);
$re = $range->regex;
ok($range);
ok($re);
ok(!$range->isa('Number::Range::Regex::TrivialRange'));
ok($range->{min} == 100);
ok($range->{max} == 179);
ok(99  !~ /^$re$/);
ok(100 =~ /^$re$/);
ok(129 =~ /^$re$/);
ok(130 =~ /^$re$/);
ok(149 =~ /^$re$/);
ok(150 =~ /^$re$/);
ok(179 =~ /^$re$/);
ok(180 !~ /^$re$/);

# overlap with an other that is lower
$range = $tr_130_to_179->union($tr_100_to_149);
$re = $range->regex;
ok($range);
ok($re);
ok(!$range->isa('Number::Range::Regex::TrivialRange'));
ok($range->{min} == 100);
ok($range->{max} == 179);
ok(99  !~ /^$re$/);
ok(100 =~ /^$re$/);
ok(129 =~ /^$re$/);
ok(130 =~ /^$re$/);
ok(149 =~ /^$re$/);
ok(150 =~ /^$re$/);
ok(179 =~ /^$re$/);
ok(180 !~ /^$re$/);

# discontinuous with an other that is higher
$range = $tr_12X->union($tr_14X);
$re = $range->regex;
ok($range);
ok($re);
ok(!$range->isa('Number::Range::Regex::TrivialRange'));
ok(119 !~ /^$re$/);
ok(120 =~ /^$re$/);
ok(125 =~ /^$re$/);
ok(129 =~ /^$re$/);
ok(130 !~ /^$re$/);
ok(135 !~ /^$re$/);
ok(139 !~ /^$re$/);
ok(140 =~ /^$re$/);
ok(145 =~ /^$re$/);
ok(149 =~ /^$re$/);
ok(150 !~ /^$re$/);

# discontinuous with an other that is lower
$range = $tr_14X->union($tr_12X);
$re = $range->regex;
ok($range);
ok($re);
ok(!$range->isa('Number::Range::Regex::TrivialRange'));
ok(119 !~ /^$re$/);
ok(120 =~ /^$re$/);
ok(125 =~ /^$re$/);
ok(129 =~ /^$re$/);
ok(130 !~ /^$re$/);
ok(135 !~ /^$re$/);
ok(139 !~ /^$re$/);
ok(140 =~ /^$re$/);
ok(145 =~ /^$re$/);
ok(149 =~ /^$re$/);
ok(150 !~ /^$re$/);

