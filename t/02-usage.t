#!perl -w
$|++;

use strict;
use Test::More tests => 1419;
use lib "./blib/lib";

use Number::Range::Regex qw ( regex_range );
my $features = Number::Range::Regex::features();
my $range;

Number::Range::Regex->init( foo => "bar" );
ok(1); #called init() without dying
eval {
  Number::Range::Regex->regex_range( 3, 4 );
}; ok($@);
eval { regex_range( "three", 4 ); }; ok($@);
eval { regex_range( 0, "four" ); }; ok($@);
Number::Range::Regex->init();
ok(1); #called init() without dying (again)

# min must not be less than max unless autoswap option is set
$range = eval { regex_range( 12, 8 ) }; ok($@); # min > max
$range = eval { regex_range( 12, 8, { autoswap => 1 } ) }; ok(!$@);
ok( $range );
ok(7 !~ /^$range$/);
ok(8 =~ /^$range$/);
ok(9 =~ /^$range$/);
ok(10 =~ /^$range$/);
ok(11 =~ /^$range$/);
ok(12 =~ /^$range$/);
ok(13 !~ /^$range$/);

# tests for regex_range(undef, undef) aka "wildcarding"
eval { regex_range() }; ok($@); # must specify at least a min or a max
my $wildcard_range = eval { regex_range( undef, undef, { allow_wildcard => 1 } ) };
ok(!$@);
ok($wildcard_range);
ok( $features->{negative} ? "-90" =~ /^$wildcard_range$/ : 1 );
ok( "67" =~ /^$wildcard_range$/ );
ok( "+67" =~ /^$wildcard_range$/ );
ok( "0" =~ /^$wildcard_range$/ );
ok( ".3" !~ /^$wildcard_range$/ ); #no decimal support

my $equals_four = regex_range( 4, 4 );
ok($equals_four);
ok("3" !~ /^$equals_four$/);
ok("4" =~ /^$equals_four$/);
ok("4.1" !~ /^$equals_four$/);
ok("40" !~ /^$equals_four$/);
ok("5" !~ /^$equals_four$/);

my $equals_one = regex_range( 1, 1 );
ok($equals_one);
ok("0" !~ /^$equals_one$/);
ok("1" =~ /^$equals_one$/);
ok("1.1" !~ /^$equals_one$/);
ok("10" !~ /^$equals_one$/);
ok("2" !~ /^$equals_one$/);

my $equals_zero = regex_range( 0, 0 );
ok($equals_zero);
ok("-1" !~ /^$equals_zero$/);
ok("0" =~ /^$equals_zero$/);
ok("0.1" !~ /^$equals_zero$/);
ok("00" =~ /^$equals_zero$/); # leading zeroes ok for zero!
ok("1" !~ /^$equals_zero$/);

my $four_or_five = regex_range( 4, 5 );
ok($four_or_five);
ok("3" !~ /^$four_or_five$/);
ok("4" =~ /^$four_or_five$/);
ok("4.1" !~ /^$four_or_five$/);
ok("40" !~ /^$four_or_five$/);
ok("5" =~ /^$four_or_five$/);
ok("6" !~ /^$four_or_five$/);

my $nine_or_ten = regex_range( 9, 10 );
ok($nine_or_ten);
ok("8" !~ /^$nine_or_ten$/);
ok("9" =~ /^$nine_or_ten$/);
ok("9.1" !~ /^$nine_or_ten$/);
ok("90" !~ /^$nine_or_ten$/);
ok("10" =~ /^$nine_or_ten$/);
ok("11" !~ /^$nine_or_ten$/);

my $zero_or_more = regex_range( 0, undef );
ok($zero_or_more);
ok("0" =~ /^$zero_or_more$/);
ok("1" =~ /^$zero_or_more$/);
ok("1.5" !~ /^$zero_or_more$/);
ok("99" =~ /^$zero_or_more$/);

my $zero_or_less = regex_range( undef, 0 );
ok($zero_or_less);
ok("0" =~ /^$zero_or_less$/);
ok("1" !~ /^$zero_or_less$/);

my $one_or_more = regex_range( 1, undef );
ok($one_or_more);
ok("0" !~ /^$one_or_more$/);
ok("1" =~ /^$one_or_more$/);
ok("1.5" !~ /^$zero_or_more$/);
ok("99" =~ /^$one_or_more$/);

my $one_or_less = regex_range( undef, 1 );
ok($one_or_less);
ok("0" =~ /^$one_or_less$/);
ok("1" =~ /^$one_or_less$/);
ok("2" !~ /^$one_or_less$/);

my $nine_ninety_seven_or_more = regex_range( 997, undef );
ok($nine_ninety_seven_or_more);
ok("0" !~ /^$nine_ninety_seven_or_more$/);
ok("9" !~ /^$nine_ninety_seven_or_more$/);
ok("99" !~ /^$nine_ninety_seven_or_more$/);
ok("996" !~ /^$nine_ninety_seven_or_more$/);
ok("997" =~ /^$nine_ninety_seven_or_more$/);
ok("998" =~ /^$nine_ninety_seven_or_more$/);
ok("1000" =~ /^$nine_ninety_seven_or_more$/);
ok("23456" =~ /^$nine_ninety_seven_or_more$/);

my $nine_ninety_seven_or_less = regex_range( undef, 997 );
ok($nine_ninety_seven_or_less);
ok("0" =~ /^$nine_ninety_seven_or_less$/);
ok("9" =~ /^$nine_ninety_seven_or_less$/);
ok("99" =~ /^$nine_ninety_seven_or_less$/);
ok("996" =~ /^$nine_ninety_seven_or_less$/);
ok("997" =~ /^$nine_ninety_seven_or_less$/);
ok("998" !~ /^$nine_ninety_seven_or_less$/);
ok("1000" !~ /^$nine_ninety_seven_or_less$/);
ok("23456" !~ /^$nine_ninety_seven_or_less$/);

# no_leading_zeroes tests
$range = regex_range( 0, 0, {no_leading_zeroes => 0} );
ok(0 =~ /^$range$/);
ok("00" =~ /^$range$/);
$range = regex_range( 0, 0, {no_leading_zeroes => 1} );
ok(0 =~ /^$range$/);
ok("00" !~ /^$range$/);
$range = regex_range( 1, 1, {no_leading_zeroes => 0} );
ok(1 =~ /^$range$/);
ok("01" =~ /^$range$/);
$range = regex_range( 1, 1, {no_leading_zeroes => 1} );
ok(1 =~ /^$range$/);
ok("01" !~ /^$range$/);
$range = regex_range( 9, 10, {no_leading_zeroes => 0} );
ok(8 !~ /^$range$/);
ok("08" !~ /^$range$/);
ok(9 =~ /^$range$/);
ok("09" =~ /^$range$/);
ok(10 =~ /^$range$/);
ok("010" =~ /^$range$/);
ok(11 !~ /^$range$/);
ok("011" !~ /^$range$/);
$range = regex_range( 9, 10, {no_leading_zeroes => 1} );
ok(8 !~ /^$range$/);
ok("08" !~ /^$range$/);
ok(9 =~ /^$range$/);
ok("09" !~ /^$range$/);
ok(10 =~ /^$range$/);
ok("010" !~ /^$range$/);
ok(11 !~ /^$range$/);
ok("011" !~ /^$range$/);


$range = test_range_exhaustive(19825, 20120);

$range = test_range_partial(19825, 32101, [19800, 19911]);
$range = test_range_partial(19825, 32101, [31990, 32200]);
$range = test_range_random(19825, 32101, 100);
ok(0 !~ /^$range$/);
ok(1982 !~ /^$range$/);
ok(2000 !~ /^$range$/);
ok(3000 !~ /^$range$/);
ok(25000 =~ /^$range$/);

$range = test_range_random(354, 13123, 100);
ok(0 !~ /^$range$/);
ok(3 !~ /^$range$/);
ok(35 !~ /^$range$/);
ok(354 =~ /^$range$/);
ok(355 =~ /^$range$/);
ok(1000 =~ /^$range$/);
ok(2000 =~ /^$range$/);
ok(3000 =~ /^$range$/);
ok(4000 =~ /^$range$/);
ok(5000 =~ /^$range$/);
ok(6000 =~ /^$range$/);
ok(7000 =~ /^$range$/);
ok(8000 =~ /^$range$/);
ok(9000 =~ /^$range$/);
ok(10000 =~ /^$range$/);
ok(11000 =~ /^$range$/);
ok(12000 =~ /^$range$/);
ok(13000 =~ /^$range$/);
ok(13100 =~ /^$range$/);
ok(13120 =~ /^$range$/);
ok(13123 =~ /^$range$/);
ok(131234 !~ /^$range$/);

test_range_exhaustive(123, 129);
test_range_exhaustive(103, 129);
test_range_exhaustive(1234, 1239);
test_range_exhaustive(1229, 1239);
test_range_exhaustive(1129, 1239);

# leading zero tests
$range = test_range_exhaustive("07", 128);
ok(6 !~ /^$range$/);
ok("06" !~ /^$range$/);
ok("006" !~ /^$range$/);
ok(7 =~ /^$range$/);
ok("07" =~ /^$range$/);
ok("007" =~ /^$range$/);
ok(8 =~ /^$range$/);
ok("08" =~ /^$range$/);
ok("008" =~ /^$range$/);
ok(60 =~ /^$range$/);
ok("060" =~ /^$range$/);
ok(600 !~ /^$range$/);
ok("0600" !~ /^$range$/);
ok("0700" !~ /^$range$/);
ok("0800" !~ /^$range$/);

$range = test_range_exhaustive(7, "0128");
ok(128 =~ /^$range$/);
ok("0128" =~ /^$range$/);
ok(129 !~ /^$range$/);
ok("0129" !~ /^$range$/);
ok(130 !~ /^$range$/);
ok("0130" !~ /^$range$/);

sub test_range_random {
  my($min, $max, $trials) = @_;
  my $range = regex_range($min, $max);
  ok($range);
  my $spread = $max - $min;
  ok(($min-1) !~ /^$range$/);
  for(my $trial=0; $trial<$trials; $trial++) {
    my $c = $min + int rand $spread * 1.5;
    my $desired = ($c >= $min) && ($c <= $max);
    my $actual  = "$c" =~ /^$range$/;
    if( ($desired and $actual) or (!$desired && !$actual) ) {
      ok(1);
    } else {
      warn "failed (random) test $c =~ /^$range$/\n";
    }
  }
  ok(($max+1) !~ /^$range$/);
  return $range;
}

sub test_range_partial {
  my($min, $max, @tranges) = @_;
  my $range = regex_range($min, $max);
  ok($range);
  foreach my $test (@tranges) { 
    my ($tmin, $tmax) = ($test->[0], $test->[1]);
    for(my $c=$tmin; $c<=$tmax; ++$c) {
      my $desired = ($c >= $min) && ($c <= $max);
      my $actual  = "$c" =~ /^$range$/;
      if( ($desired and $actual) or (!$desired && !$actual) ) {
        ok(1);
      } else {
        warn "failed (partial range) test $c =~ /^$range$/, min: $min, max: $max\n";
      }
    }
  }
  return $range;
}

sub test_range_exhaustive {
  my($min, $max) = @_;
  my $range = regex_range($min, $max);
  ok($range);
  ok(($min-1) !~ /^$range$/);
  for(my $c=$min; $c<=$max; ++$c) {
    if("$c" =~ /^$range$/) {
      ok(1);
    } else {
      warn "failed (exhaustive) test $c =~ /^$range$/, min: $min, max: $max\n";
    }
  }
  ok(($max+1) !~ /^$range$/);
  return $range;
}

