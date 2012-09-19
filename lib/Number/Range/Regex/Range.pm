# Number::Range::Regex::Range
#
# Copyright 2012 Brian Szymanski.  All rights reserved.  This module is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.

package Number::Range::Regex::Range;

use strict;
use vars qw ( @ISA @EXPORT @EXPORT_OK $VERSION ); 
eval { require warnings; }; #it's ok if we can't load warnings

require Exporter;
use base 'Exporter';
@ISA    = qw( Exporter );

use Number::Range::Regex::EmptyRange;
use Number::Range::Regex::SimpleRange;
use Number::Range::Regex::CompoundRange;

$VERSION = '0.09';

our $default_opts = {
  allow_wildcard => 0,
  autoswap => 0,

  no_leading_zeroes => 0,
  no_sign           => 0,
  comment           => 1,
  readable          => 0,
};

sub defaults { return $default_opts };

sub new { die "called abstract Range->new() on a ".ref($_[0]) }
sub regex { die "called abstract Range->regex() on a ".ref($_[0]) }
sub intersect { intersection(@_); }
sub intersection { die "called abstract Range->intersection() on a ".ref($_[0]) }
sub union { die "called abstract Range->union() on a ".ref($_[0]) }
sub touches { die "called abstract Range->touches() on a ".ref($_[0]) }
sub minus { subtract(@_); }
sub subtraction { subtract(@_); }
sub subtract { die "called abstract Range->subtract() on a ".ref($_[0]) }

1;

