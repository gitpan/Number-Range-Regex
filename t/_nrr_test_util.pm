#!perl -w
$|++;

use strict;

# usage: specify the types a range is - the range must NOT be
# of any type you do not mention (except NRR::Range), so e.g.:
#  check_type($range, 'Simple, Trivial' );
# checks for !Empty, !Compound. a TrivialRange should match. so:
#  check_type( $trivial, 'Trivial' ) -> returns false (also a Simple)
#  check_type( $trivial, 'Simple' ) -> returns false (also a Trivial)
# also note check_type($r, "foo bar") == check_type($r, qw ( foo bar ) );
sub check_type {
  my ($range, @yes_types) = @_;
  @yes_types = map { s/^\s*//; s/\s*$//; $_ } map { split /,/, $_ } @yes_types;
  my %types;
  $types{$_} = 0  for  ( qw ( Empty Simple Trivial Compound ) );
  $types{$_} = 1  for  ( '', map { s/^(.)/\u$1/; $_ } @yes_types );
  my $ret = 1;
  foreach my $key (keys %types) {
    my $type = $key;
    if ( $range->isa( "Number::Range::Regex::${type}Range" ) != $types{$key} ) {
      warn "check_type: error: range is not a ${type}Range";
      $ret = 0;
    }
  }
  return $ret;
}


sub test_rangeobj_exhaustive {
  my ($tr) = @_;
  my $regex = $tr->regex();
  die "cannot exhaustively test infinite/compound ranges"  if  !defined $tr->{min} or !defined $tr->{max};
  return  if  ($tr->{min}-1) =~ /^$regex$/;
  for(my $c=$tr->{min}; $c<=$tr->{max}; ++$c) {
    if("$c" !~ /^$regex$/) {
      warn "failed (exhaustive) test tr($tr->{min}, $tr->{max}, $tr->regex}) - failed $c =~ /^$regex$/\n";
      return;
    }
  }
  return  if  ($tr->{max}+1) =~ /^$regex$/;
  return $tr;
}

sub test_range_random {
  my($min, $max, $trials, $verbose, $opts) = @_;
  die "cannot randomly test infinite/compound ranges"  if  !defined $min or !defined $max;
  my $range = regex_range($min, $max);
  return  unless  $range;
  my $spread = $max - $min;
  my $test_start_min = $min - int( $spread / 2 );
  $test_start_min = 0  if  $test_start_min < 0;
  my @tests;
  return  if  ($min-1) =~ /^$range$/;
  return  if  $min !~ /^$range$/;
  for(my $trial=0; $trial<$trials; $trial++) {
    my $c = $test_start_min + int rand $spread * 2;
    push @tests, $c  if  $verbose;
    my $desired = ($c >= $min) && ($c <= $max);
    my $actual  = "$c" =~ /^$range$/;
    unless( ($desired and $actual) or (!$desired && !$actual) ) {
      warn "failed (random) test $c =~ /^$range$/\n";
      return;
    }
  }
  return  if  $max !~ /^$range$/;
  return  if  ($max+1) =~ /^$range$/;
  warn "\ninfo (***safe to ignore***): range $range seems to have worked for [$min..$max] in $trials trials (/***safe to ignore***)\n"  if  $verbose;
#  warn "\ninfo (***safe to ignore***): range $range seems to have worked for [$min..$max] in $trials trials. tested: ".join(", ", sort @tests)." (/***safe to ignore***)\n"  if  $verbose;
  return $range; 
}

sub test_range_partial {
  my $opts = ref($_[-1]) eq 'HASH' ? pop @_ : {};
  my($min, $max, @tranges) = @_;
  my $range = regex_range($min, $max);
  return  unless  $range;
  return  if  defined $min && ($min-1) =~ /^$range$/;
  return  if  defined $min && $min !~ /^$range$/;
  foreach my $test (@tranges) { 
    my ($tmin, $tmax) = ($test->[0], $test->[1]);
    for(my $c=$tmin; $c<=$tmax; ++$c) {
      my $desired = 1;
      $desired = $desired && ($c >= $min)  if  defined $min;
      $desired = $desired && ($c <= $max)  if  defined $max;
      my $actual  = "$c" =~ /^$range$/;
      unless( ($desired and $actual) or (!$desired && !$actual) ) {
        warn "failed (partial range) test $c =~ /^$range$/, min: $min, max: $max\n";
        return;
      }
    }
  }
  return  if  defined $max && $max !~ /^$range$/;
  return  if  defined $max && ($max+1) =~ /^$range$/;
  return $range; 
}

sub test_range_exhaustive {
  my($min, $max, $opts) = @_;
  die "cannot exhaustively test infinite/compound ranges"  if  !defined $min or !defined $max;
  my $range = regex_range($min, $max);
  return  unless  $range;
  return  if  ($min-1) =~ /^$range$/;
  for(my $c=$min; $c<=$max; ++$c) {
    if("$c" !~ /^$range$/) {
      warn "failed (exhaustive) test $c =~ /^$range$/, min: $min, max: $max\n";
      return;
    }
  }
  return  if  ($max+1) =~ /^$range$/;
  return $range;
}

sub test_all_ranges_exhaustively {
  my ($min_min, $max_max) = @_;
  for my $start ($min_min..$max_max) {
    for my $end ($start..$max_max) {
      my $range = test_range_exhaustive( $start, $end );
      return unless $range;
    }
  }
  return 1;
}

sub test_range_regex {
  my($min, $max, $regex, $opts) = @_;
  die "cannot test infinite/compound ranges"  if  !defined $min or !defined $max;
  return  unless  $regex;
  return  if  ($min-1) =~ /^$regex$/;
  for(my $c=$min; $c<=$max; ++$c) {
    if("$c" !~ /^$regex$/) {
      warn "failed (range_regex) test $c =~ /^$regex$/, min: $min, max: $max\n";
      return;
    }
  }
  return  if  ($max+1) =~ /^$regex$/;
  return $regex;
}



1;

