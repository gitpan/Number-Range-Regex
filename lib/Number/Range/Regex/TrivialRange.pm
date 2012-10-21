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

$VERSION = '0.31';

use Number::Range::Regex::SimpleRange;
use Number::Range::Regex::Util;
use Number::Range::Regex::Util::inf qw ( neg_inf pos_inf );

sub new {
  my ($class, $min, $max, $opts) = @_;
  return bless { min => $min, max => $max, opts => option_mangler( $opts ) }, $class; 
}

sub regex {
  my ($self, $passed_opts) = @_;

  my $opts = option_mangler( $self->{opts}, $passed_opts );

  my $zeroes_maybe = $opts->{no_leading_zeroes} ? '' : '0*';

  if($self->{min} < 0) {
    my $pmin = abs $self->{max};
    # -'-inf' == 'inf' according to perl. that's no good for us
    my $pmax = ($self->{min} == neg_inf) ? pos_inf : abs $self->{min};
    my $re_part = Number::Range::Regex::TrivialRange->new( $pmin, $pmax )->
                      regex( { no_leading_zeroes => 1, no_sign => 1 } );
    return qr/-$zeroes_maybe$re_part/;
  } else {
    my $sign_maybe   = $opts->{no_sign} ? '' : '[+]?';
    if($self->{min} == $self->{max}) {
      return qr/$sign_maybe$zeroes_maybe$self->{min}/;
    } else {
      #note: because of the nature of a trivial range, max must also be positive
      my $ndigits = length $self->{min};
      if($self->{max} == pos_inf) {
        # for a trivial range extending to +inf, min must be /^10+$/
        my $trailer;
        if($opts->{no_leading_zeroes}) {
          die "internal error"  if  $ndigits <= 1;
          $ndigits--; #change the first '\d' to '[1-9]'
          $trailer = "[1-9]\\d{$ndigits,}";
          return qr/$sign_maybe$trailer/;
        } else {
          $trailer = $ndigits == 0 ? '' :
                     $ndigits == 1 ? '\d' : "\\d{$ndigits,}";
          return qr/$sign_maybe$zeroes_maybe$trailer/;
        }
      } else {
        die "internal error"   if  $ndigits != length $self->{max};
        my $nsame = 0;
        for(; $nsame<$ndigits; $nsame++) {
          last  if  substr($self->{min}, $nsame, 1) ne substr($self->{max}, $nsame, 1);
        }
        my $static_header = substr($self->{min}, 0, $nsame);
        my $dig_min       = substr($self->{min}, $nsame, 1);
        my $dig_max       = substr($self->{max}, $nsame, 1);
        my $digit_range   = "[$dig_min-$dig_max]";
        my $extra_digits  = $ndigits-$nsame-1;
        my $trailer = $extra_digits == 0 ? '' :
                      $extra_digits == 1 ? '\d' : "\\d{$extra_digits}";
        return qr/$sign_maybe$zeroes_maybe$static_header$digit_range$trailer/;
      }
    }
  }
}

# touches/union/intersect/subtract inherit from SimpleRange.pm

1;

