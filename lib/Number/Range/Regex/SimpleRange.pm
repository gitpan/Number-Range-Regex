# Number::Range::Regex::SimpleRange
#
# Copyright 2012 Brian Szymanski.  All rights reserved.  This module is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.

package Number::Range::Regex::SimpleRange;

# a contiguous, finite range, can be expressed as an array of TrivialRange

use strict;
use vars qw ( @ISA @EXPORT @EXPORT_OK $VERSION ); 
eval { require warnings; }; #it's ok if we can't load warnings

require Exporter;
use base 'Exporter';
@ISA    = qw( Exporter Number::Range::Regex::Range );

$VERSION = '0.20';

use Number::Range::Regex::Util ':all';

sub new {
  my ($class, $min, $max, $passed_opts) = @_;

  my $opts = option_mangler( $passed_opts );

  die "min ($min) must be an integer"  if  $min !~ /^[-+]?\d+$/;
  die "max ($max) must be an integer"  if  $max !~ /^[-+]?\d+$/;

  if($min > $max) {
    if($opts->{autoswap}) {
      ($min, $max) = ($max, $min);
    } else {
      die "min > max (autoswap option not specified";
    }
  }
  return bless { min => $min, max => $max }, $class; 
}

sub to_string {
  my ($self, $passed_opts) = @_;
  #my $opts = option_mangler( $passed_opts );
  if($self->{min} == $self->{max}) {
    return $self->{min};
  # the prefer_comma option is dangerous because if you read in 3,4
  # you don't get 3..4, but instead 3..3,4..4 which requires collapsing
  #} elsif($self->{min}+$opts->{prefer_comma} >= $self->{max}) {
  } elsif($self->{min} > $self->{max}) {
    return join ',', ($self->{min}..$self->{max});
  } else {
    return "$self->{min}..$self->{max}";
  }
}

sub regex {
  my ($self, $passed_opts) = @_;

  my $opts = option_mangler( $passed_opts );

  if(!defined $self->{tranges}) {
    $self->{tranges} = [ $self->_calculate_tranges( $opts ) ];
  }

  my $separator      = $opts->{readable} ? ' | ' : '|';
  my $regex_str = join $separator, map { $_->regex() } @{$self->{tranges}};
  $regex_str = " $regex_str "  if  $opts->{readable};

  my $modifier_maybe = $opts->{readable} ? '(?x)' : '';
  my $sign_maybe     = $opts->{no_sign} ? '' : '[+]?';
  my $zeroes_maybe   = $opts->{no_leading_zeroes} ? '' : '0*';
  $sign_maybe = $zeroes_maybe = '' if $self->{min} < 0;
  my ($begin_comment_maybe, $end_comment_maybe) = ('', '');
  if($opts->{comment}) {
    my ($min, $max) = ($self->{min}, $self->{max});
    my $comment = "Number::Range::Regex::SimpleRange[$min..$max]";
    $begin_comment_maybe = $opts->{readable} ? " # begin $comment" : "(?# begin $comment )";
    $end_comment_maybe = $opts->{readable} ? " # end $comment" : "(?# end $comment )";
  }
  return qr/$begin_comment_maybe$modifier_maybe$sign_maybe$zeroes_maybe(?:$regex_str)$end_comment_maybe/; 
}

sub _calculate_tranges {
  my ($self, $opts) = @_; 
  my $min = $self->{min};
  my $max = $self->{max};

  #canonicalize min and max by removing leading zeroes unless the value is 0
  $min =~ s/^0+//; $min = 0 if $min eq '';
  $max =~ s/^0+//; $max = 0 if $max eq '';

  if($min < 0 && $max < 0) {
    my $pos_sr = Number::Range::Regex::SimpleRange->new( -$max, -$min );
    my @tranges = $pos_sr->_calculate_tranges( $opts );
    @tranges = reverse map { Number::Range::Regex::TrivialRange->new(
                         -$_->{max}, -$_->{min}, "-$_->{regex}" ) } @tranges;
    return @tranges;
  } elsif($min < 0 && $max >= 0) {
    # min..-1, 0..max
    my $pos_lo_sr = Number::Range::Regex::SimpleRange->new( 1, -$min );
    my @tranges = $pos_lo_sr->_calculate_tranges( $opts );
    @tranges = reverse map { Number::Range::Regex::TrivialRange->new(
                         -$_->{max}, -$_->{min}, "-$_->{regex}" ) } @tranges;
    push @tranges, Number::Range::Regex::TrivialRange->new( 0, undef, '\d+' );
    return @tranges;
  } elsif($min >= 0 && $max < 0) {
    die "_calculate_tranges() - internal error - min($min)>=0 but max($max)<0?";
  }
  # if we get here, $min >= 0 and $max >= 0

  if ($min == $max) {
    return Number::Range::Regex::TrivialRange->new( $min, $min, "$min" );
  }

#  $min-- unless $opts->{exclusive_min} || $opts->{exclusive};
#  $max++ unless $opts->{exclusive_max} || $opts->{exclusive};
#  warn "WARNING: exclusive ranges untested!" if($opts->{exclusive_min} || $opts->{exclusive_max} || $opts->{exclusive});

  my $ndigits = length($max);
  my $padded_min = sprintf("%0${ndigits}d", $min);

  my $samedigits = 0;
  for my $digit (0..length($max)-1) {
    last unless substr($padded_min, $digit, 1) eq substr($max, $digit, 1);
    $samedigits++;
  }

  my ($rightmost, $leftmost) = (length $max, $samedigits+1);

  my @tranges = ();
  push @tranges, 
    $self->_do_range_setting_loop($min, $padded_min, length($max) - length($min), $rightmost,
      [ reverse ($leftmost..$rightmost) ],
      sub {
        my ( $digit, $trailer_len, $header ) = @_;
        my $digit_min = $trailer_len ? $digit+1 : $digit; #inclusive in ones column only!
        my $digit_max = $max - ($header.('0'x($trailer_len+1)));
        $digit_max = substr($digit_max, 0, length($digit_max)-$trailer_len);
        $digit_max-- if $trailer_len; # inclusive only when this is the last
        $digit_max = 9 if $digit_max > 9;
        return ($digit_min, $digit_max);
      }
    );

  push @tranges, 
    $self->_do_range_setting_loop($max, $max, 0, $rightmost,
      [ ($leftmost+1)..$rightmost ],
      sub {
        my ( $digit, $trailer_len, $header ) = @_;
        return (0, $trailer_len ? $digit-1 : $digit);
      }
    );

  return @tranges; 
}

sub _do_range_setting_loop {
  my ($self, $string_base, $padded_string_base, $string_offset,
      $rightmost, $digit_pos_range, $digit_range_sub) = @_;

  my @ranges = ();
  foreach my $digit_pos (@$digit_pos_range) {
    my $pos = $digit_pos - $string_offset - 1;
    my $header = $pos < 0 ? "" : substr($string_base, 0, $pos);
    my $trailer_len = $rightmost - $digit_pos;
    my $trailer = $trailer_len == 0 ? "" :
                  $trailer_len > 1 ? "\\d{$trailer_len}" :
                  '\d';

    my $digit   = substr($padded_string_base, $digit_pos-1, 1);

    my ($digit_min, $digit_max) = $digit_range_sub->( $digit, $trailer_len, $header );

    my $digit_range = ($digit_max < $digit_min)  ? next :
                      ($digit_max == $digit_min) ? $digit_min :
                      "[$digit_min-$digit_max]";

    my $range_min = $header.$digit_min.(0 x $trailer_len);
    my $range_max = $header.$digit_max.(9 x $trailer_len);
    my $range_re  = $header.$digit_range.$trailer;
    push @ranges, Number::Range::Regex::TrivialRange->new(
                    $range_min, $range_max, $range_re);
  }
  return @ranges; 
}

sub intersection {
  my ($self, $other) = @_;
  if( $other->isa('Number::Range::Regex::CompoundRange') ) {
    return Number::Range::Regex::CompoundRange->new( $self )->intersection( $other);
  } elsif( $other->isa('Number::Range::Regex::InfiniteRange') ) {
    return $other->intersection( $self );
  }
  my ($lower, $upper) = _sort_by_min( $self, $other );
  if($upper->{min} <= $lower->{max}) {
    return $upper  if  $upper->{max} <= $lower->{max};
    return Number::Range::Regex::SimpleRange->new(
               $upper->{min}, $lower->{max} );
  } else {
    return Number::Range::Regex::EmptyRange->new();
  }
}

sub union {
  my ($self, @other) = @_;
  return multi_union( $self, @other )  if  @other > 1;
  my $other = shift @other;
  if( $other->isa('Number::Range::Regex::CompoundRange') ) {
    return Number::Range::Regex::CompoundRange->new( $self )->union( $other);
  } elsif( $other->isa('Number::Range::Regex::InfiniteRange') ) {
    return $other->union( $self );
  }
  my ($lower, $upper) = _sort_by_min( $self, $other );
  if($upper->{min} <= $lower->{max}+1) {
    return $lower  if  $lower->{max} >= $upper->{max};
    return Number::Range::Regex::SimpleRange->new( 
               $lower->{min}, max( $lower->{max}, $upper->{max} ) );
  } else {
    return Number::Range::Regex::CompoundRange->new( $lower, $upper );
  }
}

sub subtract {
  my ($self, $other) = @_;
  if( $other->isa('Number::Range::Regex::CompoundRange') ) {
    return Number::Range::Regex::CompoundRange->new( $self )->subtract( $other);
  } elsif( $other->isa('Number::Range::Regex::InfiniteRange') ) {
    return $other->subtract( $self );
  }
  return $self  unless  $self->touches($other);

  if($self->{min} < $other->{min}) {
    if($self->{max} <= $other->{max}) {
      # e.g. (1..7)-(3..11) = (1..2)
      # e.g. (1..11)-(3..11) = (1..2)
      return Number::Range::Regex::SimpleRange->new(
                 $self->{min}, $other->{min}-1 );
    } else {
      # e.g. (1..7)-(2..6) = (1, 7)
      my $r1 = Number::Range::Regex::SimpleRange->new(
                   $self->{min}, $other->{min}-1 );
      my $r2 = Number::Range::Regex::SimpleRange->new(
                   $other->{max}+1, $self->{max} );
      return $r1->union( $r2 );
    }
  } else {
    if($self->{max} <= $other->{max}) {
      # e.g. (1..7)-(1..11) = ()
      # e.g. (1..7)-(1..7) = ()
      return Number::Range::Regex::EmptyRange->new();
    } else {
      # e.g. (1..7)-(1..4) = (5..7)
      return Number::Range::Regex::SimpleRange->new(
                 $other->{max}+1, $self->{max} );
    }
  }
}

sub xor {
  my ($self, $other) = @_;
  if( $other->isa('Number::Range::Regex::CompoundRange') ) {
    return Number::Range::Regex::CompoundRange->new( $self )->xor( $other);
  } elsif( $other->isa('Number::Range::Regex::InfiniteRange') ) {
    return $other->xor( $self );
  }
  return $self->union($other)  unless  $self->touches($other);

  if($self->{min} == $other->{min}) {
    if($self->{max} < $other->{max}) {
      # e.g. (1..7)xor(1..11) = (8..11)
      return Number::Range::Regex::SimpleRange->new(
                 $self->{max}+1, $other->{max} );
    } elsif($self->{max} == $other->{max}) {
      # e.g. (1..11)xor(1..11) = ()
      return Number::Range::Regex::EmptyRange->new();
    } else {
      # e.g. (1..7)xor(1..6) = (7)
      return Number::Range::Regex::SimpleRange->new(
                 $other->{max}+1, $self->{max} );
    }
  } else {
    my ($lower, $upper) = _sort_by_min( $self, $other );
    if($lower->{max} < $upper->{max}) {
      # e.g. (1..7)xor(3..11) = (1..2, 8..11)
      my $r1 = Number::Range::Regex::SimpleRange->new(
                   $lower->{min}, $upper->{min}-1 );
      my $r2 = Number::Range::Regex::SimpleRange->new(
                   $lower->{max}+1, $upper->{max} );
      return $r1->union( $r2 );
    } elsif($lower->{max} == $upper->{max}) {
      # e.g. (1..11)xor(3..11) = (1..2)
      return Number::Range::Regex::SimpleRange->new(
                 $lower->{min}, $upper->{min}-1 );
    } else {
      # e.g. (1..7)xor(3..6) = (1, 7)
      my $r1 = Number::Range::Regex::SimpleRange->new(
                   $lower->{min}, $upper->{min}-1 );
      my $r2 = Number::Range::Regex::SimpleRange->new(
                   $upper->{max}+1, $lower->{max} );
      return $r1->union( $r2 );
    }
  }
}

sub invert {
  my ($self) = @_;
  my $r1 = Number::Range::Regex::InfiniteRange->new_negative_infinity( $self->{min}-1 );
  my $r2 = Number::Range::Regex::InfiniteRange->new_positive_infinity( $self->{max}+1 );
  return $r1->union( $r2 );
}


sub overlaps {
  my ($self, @other) = @_;
  foreach my $other (@other) {
    if(!$other->isa( 'Number::Range::Regex::SimpleRange') ) {
      return 1  if  $other->overlaps($self);
    } else {
      die "other argument is not a simple range (try swapping your args)"  unless  $other->isa('Number::Range::Regex::SimpleRange');
      my ($lower, $upper) = _sort_by_min( $self, $other );
      return 1  if  $upper->{min} <= $lower->{max};
    }
  }
  return;
}

sub touches {
  my ($self, @other) = @_;
  foreach my $other (@other) {
    if(!$other->isa( 'Number::Range::Regex::SimpleRange') ) {
      return 1  if  $other->touches($self);
    } else {
      die "other argument is not a simple range (try swapping your args)"  unless  $other->isa('Number::Range::Regex::SimpleRange');
      my ($lower, $upper) = _sort_by_min( $self, $other );
      return 1  if  $upper->{min} <= $lower->{max}+1;
    }
  }
  return;
}

sub contains {
  my ($self, $n) = @_;
  return ($n >= $self->{min}) && ($n <= $self->{max});
}

sub has_lower_bound { return 1; }
sub has_upper_bound { return 1; }

1;

