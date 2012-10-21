#!perl -w
$|++;

use strict;
use Test::More tests => 137;

use lib "./t";
use _nrr_test_util;

use lib "./blib/lib";
use Number::Range::Regex::Util ':all';
use Number::Range::Regex::Util::inf ':all';

# make sure overloaded <=>, <, <=, ==, !=, >=, > work as expected
my @order = ( neg_inf, -1, 0, 1, pos_inf );
foreach my $l_pos (0..$#order) {
  foreach my $r_pos (0..$#order) {
    # don't short circuit based on == which we are testing now
    next if ($l_pos == 1 || $l_pos == 2 || $l_pos == 3) &&
            ($r_pos == 1 || $r_pos == 2 || $r_pos == 3);
    my ($l, $r) = ($order[$l_pos], $order[$r_pos]);
    my $expected = $l_pos <=> $r_pos;
    is( _cmp($l, $r), $expected, "_cmp($l, $r)" );
    is( $l <=> $r, $expected, "$l <=> $r" );
    if($expected == 1) {
      is( $l == $r?1:0, 0, "$l == $r" );
      is( $l != $r?1:0, 1, "$l != $r" );
      is( $l >  $r?1:0, 1, "$l > $r" );
      is( $l >= $r?1:0, 1, "$l >= $r" );
      is( $l <= $r?1:0, 0, "$l <= $r" );
      is( $l <  $r?1:0, 0, "$l < $r" );
    } elsif($expected == -1) {
      is( $l == $r?1:0, 0, "$l == $r" );
      is( $l != $r?1:0, 1, "$l != $r" );
      is( $l >  $r?1:0, 0, "$l > $r" );
      is( $l >= $r?1:0, 0, "$l >= $r" );
      is( $l <= $r?1:0, 1, "$l <= $r" );
      is( $l <  $r?1:0, 1, "$l < $r" );
    } else { # $expected == 0
      is( $l == $r?1:0, 1, "$l == $r" );
      is( $l != $r?1:0, 0, "$l != $r" );
      is( $l >  $r?1:0, 0, "$l > $r" );
      is( $l >= $r?1:0, 1, "$l >= $r" );
      is( $l <= $r?1:0, 1, "$l <= $r" );
      is( $l <  $r?1:0, 0, "$l < $r" );
    }
  }
}

ok( -3 == most { $a == -3 ? 1 : undef } ( 42, -3, 22 ) );
ok( 22 == most { $a == 22 ? 1 : undef } ( 42, -3, 22 ) );
ok( 42 == most { $a == 42 ? 1 : undef } ( 42, -3, 22 ) );

ok( -41    == min( -3, 6,     42,    -41, 17 ) );
ok(  42    == max( -3, 6,     42,    -41, 17 ) );
ok( -41    == min( -3, 6, pos_inf,    -41, 17 ) );
ok(  42    == max( -3, 6,     42, neg_inf, 17 ) );
ok( neg_inf == min( -3, 6, pos_inf, neg_inf, 17 ) );
ok( pos_inf == max( -3, 6, pos_inf, neg_inf, 17 ) );

# note: option_mangler, multi_union, has_re_overloading tested elsewhere
