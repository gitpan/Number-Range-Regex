# Number::Range::Regex::Range
#
# Copyright 2012 Brian Szymanski.  All rights reserved.  This module is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.

package Number::Range::Regex::Range;

use strict;
use vars qw ( @ISA @EXPORT @EXPORT_OK $VERSION $default_opts ); 
eval { require warnings; }; #it's ok if we can't load warnings

require Exporter;
use base 'Exporter';
@ISA = qw( Exporter );

$VERSION = '0.30';

use Number::Range::Regex::CompoundRange;
use Number::Range::Regex::EmptyRange;
use Number::Range::Regex::SimpleRange;
use Number::Range::Regex::TrivialRange;
use Number::Range::Regex::Util;

$default_opts = {
  allow_wildcard => 0,
  autoswap       => 0,

  no_leading_zeroes => 0,
  no_sign           => 0,
  comment           => 1,
  readable          => 0,
};

use overload bool => sub { return $_[0] },
             '""' => sub { return $_[0]->overload_string() },
             'qr' => sub { return $_[0]->regex() };

sub overload_string {
  my ($self) = @_;
  $self->{has_regex_overloading} = has_regex_overloading()  unless  defined $self->{has_regex_overloading}; # be cheap, save some sub calls
  # if we can distinguish regex from string context, then return a
  # human-friendly format. otherwise, return the (probably hairy) regex
  return $self->{has_regex_overloading} ? $self->to_string() : $self->regex();
}

sub iterator {
  my ($self) = @_;        
  return Number::Range::Regex::Iterator->new( $self );
}

sub new { die "called abstract Range->new() on a ".ref($_[0]) }
sub to_string { die "called abstract Range->to_string() on a ".ref($_[0]) }
sub regex { die "called abstract Range->regex() on a ".ref($_[0]) }
sub union { die "called abstract Range->union() on a ".ref($_[0]) }
sub intersect { shift->intersection(@_); }
sub intersection { die "called abstract Range->intersection() on a ".ref($_[0]) }
sub minus { shift->subtract(@_); }
sub subtraction { shift->subtract(@_); }
sub subtract { die "called abstract Range->subtract() on a ".ref($_[0]) }
sub xor { die "called abstract Range->xor() on a ".ref($_[0]) }
sub not { shift->invert(@_); }
## relative complemet == subtraction, absolute complement == invert
## but it probably will cause more confusion to include this than not
#sub complement {
#  my ($self, $other) = @_;
#  return $self->subtract( $other )  if  $other;
#  return $self->invert();
#}
sub invert { die "called abstract Range->invert() on a ".ref($_[0]) }
sub touches { die "called abstract Range->touches() on a ".ref($_[0]) }
sub contains { die "called abstract Range->contains() on a ".ref($_[0]) }
sub has_lower_bound { die "called abstract Range->has_lower_bound() on a ".ref($_[0]) }
sub has_upper_bound { die "called abstract Range->has_upper_bound() on a ".ref($_[0]) }
sub is_infinite { die "called abstract Range->is_infinite() on a ".ref($_[0]) }

1;

