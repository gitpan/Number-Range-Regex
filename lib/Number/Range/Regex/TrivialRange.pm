# Number::Range::Regex::TrivialRange
#
# Copyright 2012 Brian Szymanski.  All rights reserved.  This module is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.

package Number::Range::Regex::TrivialRange;

use strict;
use vars qw ( @ISA @EXPORT @EXPORT_OK $VERSION ); 
eval { require warnings; }; #it's ok if we can't load warnings

require Exporter;
use base 'Exporter';
@ISA    = qw( Exporter );

$VERSION = '0.08';

sub new {
  my ($class, $min, $max, $regex) = @_;
  return bless { min => $min, max => $max, regex => $regex }, $class; 
}

sub regex {
  my ($self, $opts) = @_;
  return $self->{regex};
}

sub intersect { intersection(@_); }
sub intersection {
  my ($self, $other) = @_;
  my ($lower, $upper) = ($self->{min} < $other->{min}) ?
                        ($self, $other) : 
                        ($other, $self);
  if($upper->{min} <= $lower->{max}) {
    # they overlap
    return $upper  if  $upper->{max} <= $lower->{max};
    my $range = Number::Range::Regex::Range->new_by_range(
                  $upper->{min}, $lower->{max} );
#    return $range->{ranges}->[0]  if  @{$range->{ranges}} == 1;
    return $range;
  } else {
    # no intersection
    return bless { ranges => [] }, 'Number::Range::Regex::Range';
  }
}

sub union {
  my ($self, $other) = @_;
  my ($lower, $upper) = ($self->{min} < $other->{min}) ?
                        ($self, $other) : 
                        ($other, $self);
  if($upper->{min} <= $lower->{max}+1) {
    # they touch
    return $lower  if  $lower->{max} >= $upper->{max};
    my $range = Number::Range::Regex::Range->new_by_range( $lower->{min}, 
      $self->{max} > $other->{max} ? $self->{max} : $other->{max} );
#    return $range->{ranges}->[0]  if  @{$range->{ranges}} == 1;
    return $range;
  } else {
    # two disjount TrivialRanges
    return bless { ranges => [ $lower, $upper ] }, 'Number::Range::Regex::Range';
  }
}

sub touches {
  my ($self, @other) = @_;
  foreach my $other (@other) {
    my ($lower, $upper) = ($self->{min} < $other->{min}) ?
                          ($self, $other) : 
                          ($other, $self);
    return 1  if  $upper->{min} <= $lower->{max}+1;
  }
  return
}

#sub touches {
#  my ($self, $other) = @_;
#  my ($lower, $upper) = ($self->{min} < $other->{min}) ?
#                        ($self, $other) : 
#                        ($other, $self);
#  return $upper->{min} <= $lower->{max}+1;
#}  

1;

