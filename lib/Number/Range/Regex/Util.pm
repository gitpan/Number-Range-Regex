# Number::Range::Regex::Util
#
# Copyright 2012 Brian Szymanski.  All rights reserved.  This module is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.

package Number::Range::Regex::Util;

use strict;
use vars qw ( @ISA @EXPORT @EXPORT_OK $VERSION ); 
eval { require warnings; }; #it's ok if we can't load warnings

require Exporter;
use base 'Exporter';
@ISA    = qw( Exporter );
@EXPORT = @EXPORT_OK = qw ( most min max multi_union );

$VERSION = '0.09';

sub min { return most( sub { $_[0] < $_[1] }, @_ ); }

sub max { return most( sub { $_[0] > $_[1] }, @_ ); }

sub most {
  my ($condition, $first, @rest) = @_;
  my $most = $first;
  foreach my $o (@rest) {
    $most = $o  if  $condition->($o, $most);
  }
  return $most; 
}

sub multi_union {
  my @ranges = @_;
  my $self = shift @ranges;
  $self = $self->union( $_ ) for @ranges;
  return $self;
}

1;

