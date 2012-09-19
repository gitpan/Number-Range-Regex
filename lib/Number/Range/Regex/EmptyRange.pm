# Number::Range::Regex::EmptyRange
#
# Copyright 2012 Brian Szymanski.  All rights reserved.  This module is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.

package Number::Range::Regex::EmptyRange;

use strict;
use vars qw ( @ISA @EXPORT @EXPORT_OK $VERSION ); 
eval { require warnings; }; #it's ok if we can't load warnings

require Exporter;
use base 'Exporter';
@ISA    = qw( Exporter Number::Range::Regex::Range );

$VERSION = '0.09';

sub new {
  my ($class) = @_;
  return bless {}, $class; 
}

sub regex {
  my ($self, $opts) = @_;
  return qr /(?!)/; # never matches
}

sub touches { return; }
sub overlaps { return; }

sub intersect { intersection(@_); }
sub intersection {
  my ($self, $other) = @_;
  return $self; 
}

sub union {
  my ($self, @other) = @_;
  return Number::Range::Regex::Util::multi_union( @other );
}

sub minus { subtract(@_); }
sub subtraction { subtract(@_); }
sub subtract { 
  my ($self, @other) = @_;
  return $self;
}

sub xor {
  my ($self, $other) = @_;
  return $other;
}

1;

