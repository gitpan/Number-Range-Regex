# Number::Range::Regex::CompoundRange
#
# Copyright 2012 Brian Szymanski.  All rights reserved.  This module is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.

package Number::Range::Regex::CompoundRange;

use strict;
#use Number::Range::Regex::TrivialRange;
use vars qw ( @ISA @EXPORT @EXPORT_OK $VERSION ); 
eval { require warnings; }; #it's ok if we can't load warnings

require Exporter;
use base 'Exporter';
@ISA    = qw( Exporter Number::Range::Regex::Range );

$VERSION = '0.09';

sub new {
  my ($class, @ranges) = @_;
  # TODO: should/can we deduplicate here by calling union for each of @ranges?
  my @sorted_ranges = sort { $a->{min} <=> $b->{min} } @ranges;
  my $self = bless { ranges => [ @sorted_ranges ] }, $class;
  return $self; 
}

sub regex {
  my ($self, $passed_opts) = @_;

  # handle empty ranges
  return Number::Range::Regex::EmptyRange->regex( @_ ) unless (@{$self->{ranges}});

  # local options can override defaults
  my $opts;
  if($passed_opts) {
    die "too many arguments" unless ref $passed_opts eq 'HASH';
    # make a copy of options hashref, add overrides
    $opts = { %{$Number::Range::Regex::Range::default_opts} };
    while (my ($key, $val) = each %$passed_opts) {
      $opts->{$key} = $val;
    }
  } else {
    $opts = $Number::Range::Regex::Range::default_opts;
  }

  my $separator = $opts->{readable} ? ' | ' : '|';
  my $regex_str = join $separator, map { $_->regex() } @{$self->{ranges}};
  $regex_str = " $regex_str " if $opts->{readable};

  my $modifier_maybe = $opts->{readable} ? '(?x)' : '';
  my ($begin_comment_maybe, $end_comment_maybe) = ('', '');
  if($opts->{comment}) {
    my $nparts = @{$self->{ranges}};
    my $comment = "Number::Range::Regex::CompoundRange[$nparts parts]";
    $begin_comment_maybe = $opts->{readable} ? " # begin $comment" : "(?# begin $comment )";
    $end_comment_maybe = $opts->{readable} ? " # end $comment" : "(?# end $comment )";
  }
  return qr/(?:$begin_comment_maybe$modifier_maybe(?:$regex_str)$end_comment_maybe)/; 
}

sub intersect { intersection(@_); }
sub intersection {
  my ($self, $other) = @_;

  # TODO: we don't need to do the full cross-product like this
  # ... and we shouldn't, because it's slower than it should be
  my @ranges;
  for my $s_range (@{$self->{ranges}}) {
    for my $o_range (@{$other->{ranges}}) {
      my $intersection = $s_range->intersection( $o_range );
      if( $intersection->isa('Number::Range::Regex::SimpleRange') ) {
        push @ranges, $intersection;
      } elsif( $intersection->isa('Number::Range::Regex::EmptyRange') ) {
        # don't bother adding empty ranges
      } else {
        die 'internal error - unexpected intersection result type: '.ref($intersection);
      }
    }
  }

  my $result = Number::Range::Regex::Util::multi_union( _collapse_ranges( @ranges ) );

  my @minmax = $result->_is_contiguous();
  return Number::Range::Regex::SimpleRange->new( @minmax )  if  @minmax;

  return $result; 
}

sub union {
  my ($self, @other) = @_;
  return Number::Range::Regex::Util::multi_union( $self, @other )  if  @other > 1;
  my $other = shift @other;

  my @new_ranges;
  my @s_ranges = @{$self->{ranges}};
  my @o_ranges = $other->isa('Number::Range::Regex::CompoundRange') ? @{$other->{ranges}} :
                 $other->isa('Number::Range::Regex::SimpleRange') ? ( $other ) :
                 die "other is neither a simple nor complex range!";

  if( $s_ranges[0]->{min} < $o_ranges[0]->{min} ) {
    @new_ranges = shift @s_ranges;
  } else {
    @new_ranges = shift @o_ranges;
  }

  while(@s_ranges || @o_ranges) {
    my $next_range;
#warn "top loop new_ranges: ".join(" ", map { $_->regex } @new_ranges);
    if( defined $s_ranges[0] ) {
      if( defined $o_ranges[0] ) {
        if( $s_ranges[0]->{min} < $o_ranges[0]->{min} ) {
          $next_range = shift @s_ranges;
        } else {
          $next_range = shift @o_ranges;
        }
      } else {
        $next_range = shift @s_ranges;
      } 
    } else {
      if( defined $o_ranges[0] ) {
        $next_range = shift @o_ranges;
      } else {
        die "internal error";
      } 
    } 

    if($next_range->touches($new_ranges[-1])) {
      my $last_range = pop @new_ranges;
#warn "last_range: $last_range->{min}..$last_range->{max}";
#warn "next_range: $next_range->{min}..$next_range->{max}";
      my $r_union = $next_range->union($last_range);
      if($r_union->isa('Number::Range::Regex::SimpleRange')) {
        push @new_ranges, $r_union;
      } elsif($r_union->isa('Number::Range::Regex::CompoundRange')) {
        my @ranges = @{$r_union->{ranges}};
        die "internal error: too many SimpleRanges in CompoundRange??"  if  @ranges > 2;
        push @new_ranges, @ranges;
      } else {
        die 'internal error - unexpected union result type: '.ref($r_union);
      }
    } else {
      push @new_ranges, $next_range;
    }
  }

  my $result = bless { ranges => [ _collapse_ranges(@new_ranges) ] },
                    'Number::Range::Regex::CompoundRange';
  my @minmax = $result->_is_contiguous();
  return Number::Range::Regex::SimpleRange->new( @minmax )  if  @minmax;

  return $result; 
}

sub minus { subtract(@_); }
sub subtraction { subtract(@_); }
sub subtract {
  my ($self, $other) = @_; 

  # TODO: we might not need to do the full cross-product like this
  # ... and if not, we shouldn't, because it's slower than it should be
  my @ranges;
  SUB_SELF_LOOP: for my $s_range (@{$self->{ranges}}) {
    my $good = $s_range;
    for my $o_range (@{$other->{ranges}}) {
      $good = $good->subtract( $o_range );
      next SUB_SELF_LOOP  if  $good->isa('Number::Range::Regex::EmptyRange');
    }

    if( $good->isa('Number::Range::Regex::SimpleRange') ) {
      push @ranges, $good;
    } else {
      die 'internal error - unexpected subtraction result type: '.ref($good);
    }
  }

  my $result = Number::Range::Regex::Util::multi_union( _collapse_ranges( @ranges ) );

  my @minmax = $result->_is_contiguous();
  return Number::Range::Regex::SimpleRange->new( @minmax )  if  @minmax;

  return $result; 
}

sub xor {
  my ($self, $other) = @_; 
  #TODO: this is slower than a direct implementation
  return $self->union($other)->minus( $self->intersection($other) );
}

sub _collapse_ranges {
  my @ranges = @_;

  for (my $rpos = 1; $rpos < @ranges; $rpos++ ) {
    my $last_range = $ranges[$rpos-1];
    my $this_range = $ranges[$rpos];
    if($last_range->touches($this_range)) {
      $ranges[$rpos] = $last_range->union($this_range);
      $rpos--;
    }
  }
  return @ranges; 
}

sub _is_contiguous {
  my ($self) = @_;
  my $pos = $self->{ranges}->[0]->{min};
  foreach my $sr (@{$self->{ranges}}) {
    # nothing to do if not contiguous
    return  if  $pos != $sr->{min};
    $pos = $sr->{max}+1;
  }
  return ($self->{ranges}->[0]->{min}, $self->{ranges}->[-1]->{max});
}

1;

