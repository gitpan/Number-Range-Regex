# Number::Range::Regex::TrivialRange
#
# Copyright 2012 Brian Szymanski.  All rights reserved.  This module is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.

package Number::Range::Regex::TrivialRange;

# one range, expressible in the form $header.$range.$trailer, where
#  header = \d+
#  range = [\d-\d]
#  trailer = \\d+
# e.g. 12[3-8]\d\d

use strict;
use vars qw ( @ISA @EXPORT @EXPORT_OK $VERSION ); 
eval { require warnings; }; #it's ok if we can't load warnings

require Exporter;
use base 'Exporter';
@ISA    = qw( Exporter Number::Range::Regex::SimpleRange );

use Number::Range::Regex::SimpleRange;

$VERSION = '0.12';

sub new {
  my ($class, $min, $max, $regex) = @_;
  return bless { min => $min, max => $max, regex => $regex }, $class; 
}

sub regex {
  my ($self, $opts) = @_;
  return $self->{regex};
}

# touches/union/intersect/subtract inherit from SimpleRange.pm

1;

