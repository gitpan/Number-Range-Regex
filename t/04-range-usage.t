#!perl -w
$|++;

use strict;
use Test::More tests => 124;

use lib "./t";
use _nrr_test_util;

use lib "./blib/lib";
use Number::Range::Regex;

my $r_1XX = Number::Range::Regex::Range->new_by_range(100, 199);
ok(test_rangeobj_exhaustive($r_1XX));
my $r_12X = Number::Range::Regex::Range->new_by_range(120, 129);
ok(test_rangeobj_exhaustive($r_12X));
my $r_14X = Number::Range::Regex::Range->new_by_range(140, 149);
ok(test_rangeobj_exhaustive($r_14X));
my $r_100_to_149 = Number::Range::Regex::Range->new_by_range(100, 149);
ok(test_rangeobj_exhaustive($r_100_to_149));
my $r_130_to_179 = Number::Range::Regex::Range->new_by_range(130, 179);
ok(test_rangeobj_exhaustive($r_130_to_179));

my ($range, $c, $re);

# self is superset
$range = $r_1XX->union($r_12X);
$re = $range->regex;
ok($range);
ok($re);
ok($range->{min} == $r_1XX->{min});
ok($range->{max} == $r_1XX->{max});
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
$range = $r_12X->union($r_1XX);
$re = $range->regex;
ok($range);
ok($re);
ok($range->{min} == $r_1XX->{min});
ok($range->{max} == $r_1XX->{max});
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
$range = $r_100_to_149->union($r_130_to_179);
$re = $range->regex;
ok($range);
ok($re);
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
$range = $r_130_to_179->union($r_100_to_149);
$re = $range->regex;
ok($range);
ok($re);
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
$range = $r_12X->union($r_14X);
$re = $range->regex;
ok($range);
ok($re);
ok(!defined $range->{min});
ok(!defined $range->{max});
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
$range = $r_14X->union($r_12X);
$re = $range->regex;
ok($range);
ok($re);
ok(!defined $range->{min});
ok(!defined $range->{max});
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


$range = Number::Range::Regex::Range->new_by_range(100, 104);
ok($range);
ok($range->regex);
ok(test_range_regex(100, 104, $range->regex));
ok($range->{contiguous});

$range = $range->union( Number::Range::Regex::Range->new_by_range(106, 109) );
ok($range);
ok($range->regex);
ok(test_range_regex(100, 104, $range->regex));
ok(test_range_regex(106, 109, $range->regex));
ok(!$range->{contiguous});

$range = $range->union( Number::Range::Regex::Range->new_by_range(104, 106) );
ok($range);
ok($range->regex);
ok(test_range_regex(100, 109, $range->regex));
ok($range->{contiguous});

$range = Number::Range::Regex::Range->new_by_range(99, 104);
ok($range);
ok($range->regex);
ok(test_range_regex(99, 104, $range->regex));
ok($range->{contiguous});

$range = $range->union( Number::Range::Regex::Range->new_by_range(106, 109) );
ok($range);
ok($range->regex);
ok(test_range_regex(99, 104, $range->regex));
ok(test_range_regex(106, 109, $range->regex));
ok(!$range->{contiguous});

$range = $range->union( Number::Range::Regex::Range->new_by_range(105, 105) );
ok($range);
ok($range->regex);
ok(test_range_regex(99, 109, $range->regex));
ok($range->{contiguous});

$range = Number::Range::Regex::Range->new_by_range(3, 37);
ok($range);
ok($range->{contiguous});
$range = $range->union( Number::Range::Regex::Range->new_by_range(40,50) );
ok($range);
ok(!$range->{contiguous});
$range = $range->union( Number::Range::Regex::Range->new_by_range(61, 71) );
ok($range);
ok(!$range->{contiguous});
$range = $range->union( Number::Range::Regex::Range->new_by_range(82, 92) );
ok($range);
my $rlength = length($range->regex);
ok(!$range->{contiguous});
$range = $range->union( Number::Range::Regex::Range->new_by_range(7, 85) );
ok($range);
ok($rlength > length($range->regex));
ok($range->{contiguous});

