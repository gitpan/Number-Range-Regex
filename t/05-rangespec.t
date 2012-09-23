#!perl -w
$|++;

use strict;
use Test::More;


use lib "./t";
use _nrr_test_util;

use lib "./blib/lib";
use Number::Range::Regex qw ( range rangespec );

my ($r, $re);

plan tests => $^V ge v5.8.0 ? 115 : 114;

$r = range( 3, 4 );
ok(check_type($r, 'Simple'));
ok($r->to_string() eq '3..4');
#ok($r->to_string( {prefer_comma => 1} ) eq '3,4');
ok(test_rangeobj_exhaustive($r));
ok($r->contains($_)) for (3,4);
ok(!$r->contains($_)) for (2,5);

$r = range( 3, 5 ); # == rangespec('3..5');
ok(check_type($r, 'Simple'));
ok($r->to_string() eq '3..5');
ok(test_rangeobj_exhaustive($r));
ok($r->contains($_)) for (3..5);
ok(!$r->contains($_)) for (2,6);

$r = rangespec( "3" );
ok(check_type($r, 'Simple'));
ok($r->to_string() eq '3');
ok(test_rangeobj_exhaustive($r));
ok($r->contains(3));
ok(!$r->contains($_)) for (2,4);

$r = rangespec( "3..6" );
ok(check_type($r, 'Simple'));
ok($r->to_string() eq '3..6');
ok(test_rangeobj_exhaustive($r));
ok($r->contains($_)) for (3..6);
ok(!$r->contains($_)) for (2,7);

$r = rangespec( "3,6" );
ok(check_type($r, 'Compound'));
ok($r->to_string() eq '3,6');
$re = $r->regex;
ok($re);
ok( $_ =~ /^$re$/ ) for ( 3,6 );
ok( $_ !~ /^$re$/ ) for ( 2,4,5,7 );
ok($r->contains($_)) for (3,6);
ok(!$r->contains($_)) for (2,4..5,7);

$r = rangespec( "3..6,9" );
ok(check_type($r, 'Compound'));
ok($r->to_string() eq '3..6,9');
$re = $r->regex;
ok($re);
ok( $_ =~ /^$re$/ ) for ( 3..6,9 );
ok( $_ !~ /^$re$/ ) for ( 2,7..8 );
ok($r->contains($_)) for (3..6,9);
ok(!$r->contains($_)) for (2,7..8);

$r = rangespec( "3..6,9..11" );
ok(check_type($r, 'Compound'));
ok($r->to_string() eq '3..6,9..11');
$re = $r->regex;
ok($re);
ok( $_ =~ /^$re$/ ) for ( 3..6,9..11 );
ok( $_ !~ /^$re$/ ) for ( 2,7..8,12 );
ok($r->contains($_)) for (3..6,9..11);
ok(!$r->contains($_)) for (2,7..8,12);

eval { $r = rangespec( "3..2" ); };
ok($@);
eval { $r = rangespec( "3..2", { autoswap => 1 } ); };
ok(!$@);

# if we have perl > 5.8 we can temporarily reopen STDERR to a var
# but don't warn "out loud" - redirect STDERR to variable
# otherwise skip the test of passing a literal range as an argument
# to rangespec and make sure we complain (but not out loud)
if($^V gt v5.8.0) {
  my $err;
  local *STDERR;
  open(STDERR, '>', \$err) or die "open: $!";
  $r = rangespec( 3..6,9..11 );
  ok(check_type($r, 'Compound'));
  ok($err); # passed literal range to rangespec
  close STDERR;
} else {
  diag "please ignore the following warning about passing a literal range to rangespec()";
  $r = rangespec( 3..6,9..11 );
  ok(check_type($r, 'Compound'));
}
$re = $r->regex;
ok( $_ =~ /^$re$/ ) for ( 3..6,9..11 );
ok( $_ !~ /^$re$/ ) for ( 2,7..8,12 );
ok($r->contains($_)) for (3..6,9..11);
ok(!$r->contains($_)) for (2,7..8,12);

