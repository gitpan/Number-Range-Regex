# Number::Range::Regex::SimpleRange
#
# Copyright 2012 Brian Szymanski.  All rights reserved.  This module is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.

package Number::Range::Regex::SimpleRange;

# a contiguous range, can be expressed as an array of TrivialRange

use strict;
use vars qw ( @ISA @EXPORT @EXPORT_OK $VERSION ); 
eval { require warnings; }; #it's ok if we can't load warnings

require Exporter;
use base 'Exporter';
@ISA    = qw( Exporter Number::Range::Regex::Range );

use Number::Range::Regex::CompoundRange;
use Number::Range::Regex::TrivialRange;
use Number::Range::Regex::Util;

$VERSION = '0.10';

sub new {
  my ($class, $min, $max, $passed_opts) = @_;

  my $opts = option_mangler( $passed_opts );

  if(defined $min) {
    if( $min !~ /^[+]?\d+$/ ) {
    #if( $min !~ /^[-+]?\d+$/ ) {
      die "min ($min) must be a positive number or undef";
    }
  }
  if(defined $max) {
    if( $max !~ /^[+]?\d+$/ ) {
    #if( $max !~ /^[-+]?\d+$/ ) {
      die "max ($max) must be a positive number or undef";
    }
  }

  if( !defined($min) && !defined($max)) {
    if(!$opts->{allow_wildcard}) {
      die "must specify either a min or a max";
    }
  }

  if(defined $min && defined $max && $min > $max) {
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

  my $separator = $opts->{readable} ? ' | ' : '|';
  my $regex_str = join $separator, map { $_->regex() } @{$self->{tranges}};
  $regex_str = " $regex_str " if $opts->{readable};

  my $modifier_maybe = $opts->{readable} ? '(?x)' : '';
  my $sign_maybe     = $opts->{no_sign} ? '' : '[+]?';
  my $zeroes_maybe   = $opts->{no_leading_zeroes} ? '' : '0*';
  my ($begin_comment_maybe, $end_comment_maybe) = ('', '');
  if($opts->{comment}) {
    my ($min, $max) = ($self->{min}, $self->{max});
    ($min, $max) = map { defined $_ ? $_ : '[unset]' } ($min, $max);
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
  if(defined $min) { $min =~ s/^0+//; $min = 0 if $min eq ''; }
  if(defined $max) { $max =~ s/^0+//; $max = 0 if $max eq ''; }

  if( !defined($min) && !defined($max)) {
    return Number::Range::Regex::TrivialRange->new(undef, undef, '\d+' );
  }

  my $goto_positive_infinity = 0;
  if( !defined $min ) {
    $min = 0;
    #$goto_negative_infinity = 1;
  }
  if( !defined $max ) {
    die "min < 0 unsupported when max undefined" if($min < 0);

    # iterate from $min to the next (power of 10) - 1 (e.g. 9999)
    # then spit out a regex for any integer with a longer length
    $max = "9"x length $min;

    $goto_positive_infinity = 1;
  }

  die "TODO: support for negative values not yet implemented" if $min < 0;

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

  if( $goto_positive_infinity ) {
    my $min_range = '1'.(0 x length($max));
    my $min_digits = length($max)+1;
    push @tranges,  Number::Range::Regex::TrivialRange->new(
                               $min_range, undef, "\\d{$min_digits,}");
  }
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

sub intersect { intersection(@_); }
sub intersection {
  my ($self, $other) = @_;
  if( $other->isa('Number::Range::Regex::CompoundRange') ) {
    return Number::Range::Regex::CompoundRange->new( $self )->intersection( $other);
  }
  my ($lower, $upper) = ($self->{min} < $other->{min}) ?
                        ($self, $other) : 
                        ($other, $self);
  if($upper->{min} <= $lower->{max}) {
    return $upper  if  $upper->{max} <= $lower->{max};
    return Number::Range::Regex::SimpleRange->new(
               $upper->{min}, $lower->{max} );
  } else {
    return Number::Range::Regex::EmptyRange->new();
  }
}

sub _compound {
  my ($self) = @_;
  return Number::Range::Regex::CompoundRange->new( $self );
}

sub union {
  my ($self, @other) = @_;
  return multi_union( $self, @other )  if  @other > 1;
  my $other = shift @other;
  if( $other->isa('Number::Range::Regex::CompoundRange') ) {
    return Number::Range::Regex::CompoundRange->new( $self )->union( $other);
  }

  my ($lower, $upper) = ($self->{min} < $other->{min}) ?
                        ($self, $other) : 
                        ($other, $self);
  if($upper->{min} <= $lower->{max}+1) {
    return $lower  if  $lower->{max} >= $upper->{max};
    return Number::Range::Regex::SimpleRange->new( 
               $lower->{min}, max( $self->{max}, $other->{max} ) );
  } else {
    return Number::Range::Regex::CompoundRange->new( $lower, $upper );
  }
}

sub minus { subtract(@_); }
sub subtraction { subtract(@_); }
sub subtract {
  my ($self, $other) = @_;
  if( $other->isa('Number::Range::Regex::CompoundRange') ) {
    return Number::Range::Regex::CompoundRange->new( $self )->subtract( $other);
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
  }
  return $self->union($other)  unless  $self->touches($other);
  if($self->{min} < $other->{min}) {
    if($self->{max} < $other->{max}) {
      # e.g. (1..7)xor(3..11) = (1..2, 8..11)
      my $r1 = Number::Range::Regex::SimpleRange->new(
                   $self->{min}, $other->{min}-1 );
      my $r2 = Number::Range::Regex::SimpleRange->new(
                   $self->{max}+1, $other->{max} );
      return $r1->union( $r2 );
    } elsif($self->{max} == $other->{max}) {
      # e.g. (1..11)xor(3..11) = (1..2)
      return Number::Range::Regex::SimpleRange->new(
                 $self->{min}, $other->{min}-1 );
    } else {
      # e.g. (1..7)xor(3..6) = (1, 7)
      my $r1 = Number::Range::Regex::SimpleRange->new(
                   $self->{min}, $other->{min}-1 );
      my $r2 = Number::Range::Regex::SimpleRange->new(
                   $other->{max}+1, $self->{max} );
      return $r1->union( $r2 );
    }
  } elsif($self->{min} == $other->{min}) {
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
    if($self->{max} < $other->{max}) {
      # e.g. (3..7)xor(1..11) = (1..2, 8..11)
      my $r1 = Number::Range::Regex::SimpleRange->new(
                   $other->{min}, $self->{min}-1 );
      my $r2 = Number::Range::Regex::SimpleRange->new(
                   $self->{max}+1, $other->{max} );
      return $r1->union( $r2 );
    } elsif($self->{max} == $other->{max}) {
      # e.g. (3..7)xor(1..7) = (1..2)
      return Number::Range::Regex::SimpleRange->new(
                 $other->{min}, $self->{max}-1 );
    } else {
      # e.g. (3..7)xor(1..4) = (1..2, 5..7)
      my $r1 = Number::Range::Regex::SimpleRange->new(
                   $other->{min}, $self->{min}-1 );
      my $r2 = Number::Range::Regex::SimpleRange->new(
                   $other->{max}+1, $self->{max} );
      return $r1->union( $r2 );
    }
  }
}

sub overlaps {
  my ($self, @other) = @_;
  foreach my $other (@other) {
    die "other argument is not a simple range (try swapping your args)"  unless  $other->isa('Number::Range::Regex::SimpleRange');
    my ($lower, $upper) = ($self->{min} < $other->{min}) ?
                          ($self, $other) : 
                          ($other, $self);
    return 1  if  $upper->{min} <= $lower->{max};
  }
  return;
}

sub touches {
  my ($self, @other) = @_;
  foreach my $other (@other) {
    die "other argument is not a simple range (try swapping your args)"  unless  $other->isa('Number::Range::Regex::SimpleRange');
    my ($lower, $upper) = ($self->{min} < $other->{min}) ?
                          ($self, $other) : 
                          ($other, $self);
    return 1  if  $upper->{min} <= $lower->{max}+1;
  }
  return;
}

sub contains {
  my ($self, $n) = @_;
  return ($n >= $self->{min}) && ($n <= $self->{max});
}


1;

