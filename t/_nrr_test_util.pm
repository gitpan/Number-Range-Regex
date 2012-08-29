#!perl -w
$|++;

use strict;

sub test_range_random {
  my($min, $max, $trials, $verbose) = @_;
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
  my($min, $max, @tranges) = @_;
  my $range = regex_range($min, $max);
  return  unless  $range;
  return  if  ($min-1) =~ /^$range$/;
  return  if  $min !~ /^$range$/;
  foreach my $test (@tranges) { 
    my ($tmin, $tmax) = ($test->[0], $test->[1]);
    for(my $c=$tmin; $c<=$tmax; ++$c) {
      my $desired = ($c >= $min) && ($c <= $max);
      my $actual  = "$c" =~ /^$range$/;
      unless( ($desired and $actual) or (!$desired && !$actual) ) {
        warn "failed (partial range) test $c =~ /^$range$/, min: $min, max: $max\n";
        return;
      }
    }
  }
  return  if  $max !~ /^$range$/;
  return  if  ($max+1) =~ /^$range$/;
  return $range; 
}

sub test_range_exhaustive {
  my($min, $max) = @_;
  my $range = regex_range($min, $max);
  return  unless  $range;
  return  if  ($min-1) =~ /^$range$/;
  return  if  $min !~ /^$range$/;
  for(my $c=$min; $c<=$max; ++$c) {
    if("$c" !~ /^$range$/) {
      warn "failed (exhaustive) test $c =~ /^$range$/, min: $min, max: $max\n";
      return;
    }
  }
  return  if  $max !~ /^$range$/;
  return  if  ($max+1) =~ /^$range$/;
  return $range;
}

1;

