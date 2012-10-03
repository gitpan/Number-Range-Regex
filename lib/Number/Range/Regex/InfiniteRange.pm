# Number::Range::Regex::InfiniteRange
#
# Copyright 2012 Brian Szymanski.  All rights reserved.  This module is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.

package Number::Range::Regex::InfiniteRange;

use strict;
use vars qw ( @ISA @EXPORT @EXPORT_OK $VERSION ); 
eval { require warnings; }; #it's ok if we can't load warnings

require Exporter;
use base 'Exporter';
@ISA    = qw( Exporter Number::Range::Regex::Range );

$VERSION = '0.20';

use Number::Range::Regex::Util;

sub new_both {
  my ($class) = @_;
  return bless { min => undef, max => undef }, $class; 
}

sub new_negative_infinity {
  my ($class, $max) = @_;
#  warn "no negatives!"; return bless { min => 0, max => $max }, $class;
  return bless { min => undef, max => $max }, $class; 
}

sub new_positive_infinity {
  my ($class, $min) = @_;
  return bless { min => $min, max => undef }, $class; 
}

sub to_string {
  my ($self, $passed_opts) = @_;
  my ($print_min, $print_max) = ($self->{min}, $self->{max});
  $print_min = '-inf'  unless defined $self->{min};
  $print_max = '+inf'  unless defined $self->{max};
  return "$print_min..$print_max"; 
}

sub regex {
  my ($self, $passed_opts) = @_;

  my $opts = option_mangler( $passed_opts );

  my $separator  = $opts->{readable} ? ' | ' : '|';
  my $sign_maybe = $opts->{no_sign} ? '' : '[+]?';
  my $regex_str;
  if(defined $self->{min}) {
    if($self->{min} < 0) {
      my $re1 = Number::Range::Regex::SimpleRange->new($self->{min}, -1)->
          regex( { %$opts, comment => 0, no_sign => 1, no_leading_zeroes => 1 } );
      my $re2 = '\d+'; #0..+inf
      $re2 = "$sign_maybe$re2";
      $regex_str = join $separator, $re1, $re2;
    } else {
      # iterate from $self->{min} up to the next (power of 10) - 1 (e.g. 9999)
      # then spit out a regex for any integer with a longer length
      my $min_digits = length($self->{min})+1;
      my $tmp = '9' x length $self->{min};
      my $re1 = Number::Range::Regex::SimpleRange->new($self->{min}, $tmp)->
          regex( { %$opts, comment => 0, no_sign => 1, no_leading_zeroes => 1 } );
      my $re2 = "\\d{$min_digits,}"; # $tmp+1..+inf
      $re2 = "$sign_maybe$re2";
      $regex_str = join $separator, $re1, $re2;
    }
  } elsif(defined $self->{max}) {
    if($self->{max} < 0) {
      # iterate from $self->{max} down to the next (power of 10) - 1 (e.g. -9999)
      # then spit out a regex for any negative integer with a longer length
      my $min_digits = length($self->{max})-1;
      my $tmp = '-'.('9' x $min_digits);
      my $re1 = "-\\d{$min_digits,}"; # -inf..$tmp-1
      my $re2 = Number::Range::Regex::SimpleRange->new($tmp, $self->{max})->
          regex( { %$opts, comment => 0, no_sign => 1, no_leading_zeroes => 1 } );
      $regex_str = join $separator, $re1, $re2;
    } else {
      my $re1 = '-\d+'; # -inf..-1
      my $re2 = Number::Range::Regex::SimpleRange->new(0, $self->{max})->
          regex( { %$opts, comment => 0, no_sign => 1, no_leading_zeroes => 1 } );
      $regex_str = join $separator, $re1, $re2;
    }
  } else { #!defined $self->{min} && !defined $self->{max}
    $regex_str = '[+-]?\d+';
  }
  $regex_str = " $regex_str " if $opts->{readable};

  my $modifier_maybe = $opts->{readable} ? '(?x)' : '';
  my ($begin_comment_maybe, $end_comment_maybe) = ('', '');
  if($opts->{comment}) {
    my ($min, $max) = map { defined $_ ? $_ : '[unset]' } ($self->{min}, $self->{max});
    my $comment = "Number::Range::Regex::InfiniteRange[$min..$max]";
    $begin_comment_maybe = $opts->{readable} ? " # begin $comment" : "(?# begin $comment )";
    $end_comment_maybe = $opts->{readable} ? " # end $comment" : "(?# end $comment )";
  }
  return qr/$begin_comment_maybe$modifier_maybe(?:$regex_str)$end_comment_maybe/; 
}

sub contains {
  my ($self, $n) = @_;
  return if(defined $self->{min} && $self->{min} > $n);
  return if(defined $self->{max} && $self->{max} < $n);
  return 1;
}

sub touches {
  my ($self, $other) = @_;
#warn "$self ¿touches? $other";
  if( $other->isa('Number::Range::Regex::EmptyRange') ) {
    return;
  } elsif( $other->isa('Number::Range::Regex::InfiniteRange') ) {
    if(defined $self->{min} && defined $other->{max}) {
      return $self->{min} <= $other->{max}+1;
    } elsif(defined $self->{max} && defined $other->{min}) {
      return $self->{max}+1 >= $other->{min};
    } else {
      return $self->overlaps( $other );
    }
  } elsif( $other->isa('Number::Range::Regex::SimpleRange') ) {
    if(defined $self->{min}) {
      return $self->{min} <= $other->{max};
    } elsif(defined $self->{max}) {
      return $other->{min} <= $self->{max};
    } else { # self is the full -inf..+inf
      return 1;
    }
  } elsif( $other->isa('Number::Range::Regex::CompoundRange') ) {
    foreach my $r (@{$other->{ranges}}) {
      return 1  if  $self->touches($r);
    }
    return;
  } else {
    die "internal error: $other has unknown type in InfiniteRange::touches()";
  }
}

sub overlaps {
  my ($self, $other) = @_;
#warn "$self ¿overlaps? $other";
  if($other->isa('Number::Range::Regex::EmptyRange') ) {
    return;
  } elsif($other->isa('Number::Range::Regex::CompoundRange') ) {
    foreach my $r ($other->{ranges}) {
      return 1  if  $self->overlaps($r);
    }
    return;
  } else { #SimpleRange or InfiniteRange
    if(defined $self->{min}) {
      if(defined $other->{min}) {
        # both extend to positive infinity
        return 1;
      } elsif(defined $other->{max}) {
        return $other->{max} >= $self->{min};
      } else { #other is the full -inf..+inf
        return 1;
      }
    } elsif(defined $self->{max}) {
      if(defined $other->{min}) {
        return $self->{max} >= $other->{min};
      } elsif(defined $other->{max}) {
        # both extend to negative infinity
        return 1;
      } else { #other is the full -inf..+inf
        return 1;
      }
    } else { # self is the full -inf..+inf
      return 1;
    }
  }
}

sub union {
  my ($self, @other) = @_;
  return multi_union( $self, @other )  if  @other > 1;
  my $other = shift @other;
#warn "IR->union(): s: $self, o: $other";
  if( $other->isa('Number::Range::Regex::EmptyRange') ) {
    return $self;
  } elsif( $other->isa('Number::Range::Regex::CompoundRange') ) {
    my $result = $self;
    foreach my $r (@{$other->{ranges}}) {
      $result = $result->union( $r );
    }
    return $result;
  } elsif( $other->isa('Number::Range::Regex::SimpleRange') ) {
    if(defined $self->{min}) {
      if($other->{min} >= $self->{min}) { 
        return $self;
      } elsif($other->{max} >= $self->{min}-1) {
        return Number::Range::Regex::InfiniteRange->new_positive_infinity( $other->{min} );
      } else { # other->{max} < self->{min}
        return Number::Range::Regex::CompoundRange->new( $other, $self );
      }
    } elsif(defined $self->{max}) {
      if($other->{max} <= $self->{max}) { 
        return $self;
      } elsif($other->{min} <= $self->{max}+1) {
        return Number::Range::Regex::InfiniteRange->new_negative_infinity( $other->{max} );
      } else { # other->{min} > self->{max}
        return Number::Range::Regex::CompoundRange->new( $self, $other );
      }
    } else { # neither smin nor smax set, this is -inf..inf
      return $self;
    }
  } else { #Infinite
    if(defined $self->{min}) {
      if(defined $other->{min}) {
        return $self->{min} < $other->{min} ? $self : $other;
      } elsif(defined $other->{max}) {
        if($self->{min} <= $other->{max}+1) {
          return Number::Range::Regex::InfiniteRange->new_both();
        } else {
          return Number::Range::Regex::CompoundRange->new( $other, $self );
        }
      } else { #neither omin nor omax are set, this is -inf..inf
        return $other;
      }
    } elsif(defined $self->{max}) {
      if(defined $other->{min}) {
        if($other->{min} <= $self->{max}+1) {
          return Number::Range::Regex::InfiniteRange->new_both();
        } else {
          return Number::Range::Regex::CompoundRange->new( $self, $other );
        }
      } elsif(defined $other->{max}) {
        return $self->{max} > $other->{max} ? $self : $other;
      } else { #neither omin nor omax are set, this is -inf..inf
        return $other;
      }
    } else { # neither smin nor smax set, this is -inf..inf
      return $self;
    }
  }
  die "internal error - unhandled case in IR::union";
}

sub intersection {
  my ($self, $other) = @_;
die "TODO";
}

sub subtract { 
  my ($self, @other) = @_;
die "TODO";
}

sub xor {
  my ($self, $other) = @_;
die "TODO";
}

sub invert {
  my ($self) = @_;
  if(defined $self->{min}) {
    return Number::Range::Regex::InfiniteRange->new_negative_infinity( $self->{min}-1 );
  } elsif(defined $self->{max}) {
    return Number::Range::Regex::InfiniteRange->new_positive_infinity( $self->{max}+1 );
  } else {
    return Number::Range::Regex::EmptyRange->new();
  }
}

sub has_lower_bound {
  my ($self) = @_;
  return defined $self->{min};
}

sub has_upper_bound {
  my ($self) = @_;
  return defined $self->{max};
}



1;

