# Number::Range::Regex::CompoundRange
#
# Copyright 2012 Brian Szymanski.  All rights reserved.  This module is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.

package Number::Range::Regex::CompoundRange;

use strict;
use Number::Range::Regex::Util;
use vars qw ( @ISA @EXPORT @EXPORT_OK $VERSION ); 
eval { require warnings; }; #it's ok if we can't load warnings

require Exporter;
use base 'Exporter';
@ISA    = qw( Exporter Number::Range::Regex::Range );

$VERSION = '0.10';

sub new {
  my ($class, @ranges) = @_;
  # TODO: should/can we deduplicate here by calling union for each of @ranges?
  my @sorted_ranges = sort { $a->{min} <=> $b->{min} } @ranges;
  my $self = bless { ranges => [ @sorted_ranges ] }, $class;
  return $self; 
}

sub to_string {
  my ($self, $passed_opts) = @_;
  #my $opts = option_mangler( $passed_opts );

  return Number::Range::Regex::EmptyRange->to_string( @_ ) unless (@{$self->{ranges}});

  return join(',', map { $_->to_string() } @{$self->{ranges}});
}

sub regex {
  my ($self, $passed_opts) = @_;

  # handle empty ranges
  return Number::Range::Regex::EmptyRange->regex( @_ ) unless (@{$self->{ranges}});

  my $opts = option_mangler( $passed_opts );

  my $separator = $opts->{readable} ? ' | ' : '|';
  my $regex_str = join $separator, map { $_->regex() } @{$self->{ranges}};
  $regex_str = " $regex_str " if $opts->{readable};

  my $modifier_maybe = $opts->{readable} ? '(?x)' : '';
  my ($begin_comment_maybe, $end_comment_maybe) = ('', '');
  if($opts->{comment}) {
    my $comment = "Number::Range::Regex::CompoundRange[".$self->to_string."]";
    $begin_comment_maybe = $opts->{readable} ? " # begin $comment" : "(?# begin $comment )";
    $end_comment_maybe = $opts->{readable} ? " # end $comment" : "(?# end $comment )";
  }
  return qr/(?:$begin_comment_maybe$modifier_maybe(?:$regex_str)$end_comment_maybe)/; 
}

sub _sr_new_wrapper {
  my ($min, $max) = @_;
  $min = 0  if  $min < 0;
  $max = 0  if  $max < 0;
  die "internal error in _sr_new_wrapper"  if  $max < $min;
  return Number::Range::Regex::SimpleRange->new( $min, $max );
}

sub _do_unequal_min {
  my ($lower, $upper, $ptr, $ranges) = @_;
  if( $lower->{max} > $upper->{max} ) {
    # 3 ranges, last of which may yet overlap
    my $r1 = _sr_new_wrapper( $lower->{min}, $upper->{min}-1 );
    my $r2 = $upper;
    my $r3 = _sr_new_wrapper( $upper->{max}+1, $lower->{max} );
#warn "l: $lower->{min}..$lower->{max} -> $r1->{min}..$r1->{max},$r2->{min}..$r2->{max},$r3->{min}..$r3->{max}";
    splice( @$ranges, $$ptr, 1, ($r1, $r2, $r3) );
    $$ptr += 2; # $r3 may overlap something else
  } elsif( $lower->{max} >= $upper->{min} ) {
    # 2 ranges, neither of which can overlap anything else
    my $r1 = _sr_new_wrapper( $lower->{min}, $upper->{min}-1 );
    my $r2 = $upper;
#warn "l: $lower->{min}..$lower->{max} -> $r1->{min}..$r1->{max},$r2->{min}..$r2->{max}";
    splice( @$ranges, $$ptr, 1, ($r1, $r2 ) );
    $$ptr += 2;
  } else { # $lower->{max} < $upper->{min} 
    # 1 range, no overlap
#warn "l: $lower->{min}..$lower->{max} is ok";
    $$ptr++;
  }
}

sub sectionify {
  my ($self, $other) = @_;

  my @s_ranges = @{$self->{ranges}};
  my @o_ranges = $other->isa('Number::Range::Regex::CompoundRange') ? @{$other->{ranges}} :
                 $other->isa('Number::Range::Regex::SimpleRange') ? ( $other ) :
                 die "other is neither a simple nor complex range!";

#warn "s_ranges1: ".join ",", map { "$_->{min}..$_->{max}" } @s_ranges;
#warn "o_ranges1: ".join ",", map { "$_->{min}..$_->{max}" } @o_ranges;

  # munge ranges so that there are no partial overlaps - only
  # non-overlaps and complete overlaps e.g:
  #   if s=(6..12) and o=(7..13):
  #      s=(6,7..12) and o=(7..12,13);
  #   if s=(6..12) and o=(7..9):
  #      s=(6,7..9,10..12) and o=(7..9);
  my ($s_ptr, $o_ptr) = (0, 0);
  while( ($s_ptr < @s_ranges) && ($o_ptr < @o_ranges) ) {
    my $this_s = $s_ranges[$s_ptr];
    my $this_o = $o_ranges[$o_ptr];
#warn "checking this_s: $this_s->{min}..$this_s->{max}, this_o: $this_o->{min}..$this_o->{max}";
    if( $this_s->{min} < $this_o->{min} ) {
#printf STDERR "l==s, ";
      _do_unequal_min($this_s, $this_o, \$s_ptr, \@s_ranges );
    } elsif( $this_s->{min} > $this_o->{min} ) {
#printf STDERR "l==o, ";
      _do_unequal_min($this_o, $this_s, \$o_ptr, \@o_ranges );
    } else { # $this_s->{min} == $this_o->{min}
      if( $this_s->{max} < $this_o->{max} ) {
        # 2 ranges, latter of which may yet overlap
        my $r1 = $this_s;
        my $r2 = _sr_new_wrapper($this_s->{max}+1, $this_o->{max});
        splice( @s_ranges, $s_ptr, 1, ($r1, $r2) );
#warn "s: $this_s->{min}..$this_s->{max} -> $r1->{min}..$r1->{max},$r2->{min}..$r2->{max}";
        $s_ptr++; # $r2 may overlap something else
      } elsif( $this_s->{max} > $this_o->{max} ) {
        # 2 ranges, latter of which may yet overlap
        my $r1 = $this_o;
        my $r2 = _sr_new_wrapper($this_o->{max}+1, $this_s->{max});
        splice( @s_ranges, $s_ptr, 1, ($r1, $r2) );
#warn "o: $this_o->{min}..$this_o->{max} -> $r1->{min}..$r1->{max},$r2->{min}..$r2->{max}";
        $s_ptr++; # $r2 may overlap something else
      } else { # $this_s->{max} == $this_o->{min} 
        # 1 range, no overlap
#warn "s/o: $this_o->{min}..$this_o->{max} is ok";
        $s_ptr++;
        $o_ptr++;
      }
    }
  }

#warn "s_ranges2: ".join ",", map { "$_->{min}..$_->{max}" } @s_ranges;
#warn "o_ranges2: ".join ",", map { "$_->{min}..$_->{max}" } @o_ranges;

  my (@just_self, @just_other, @in_both);
  ($s_ptr, $o_ptr) = (0, 0);
  while( ($s_ptr < @s_ranges) && ($o_ptr < @o_ranges) ) {
    my $this_s = $s_ranges[$s_ptr];
    my $this_o = $o_ranges[$o_ptr];
    if( $this_s->{min} < $this_o->{min} ) {
      push @just_self, $this_s;
      $s_ptr++;
    } elsif( $this_o->{min} < $this_s->{min} ) {
      push @just_other, $this_o;
      $o_ptr++;
    } else { # $this_s->{min} == $this_o->{min} 
      die "internal error in sectionify"  unless  $this_s->{max} == $this_o->{max};
      push @in_both, $this_s;
      $s_ptr++;
      $o_ptr++;
    }     
  }
  push @just_other, @o_ranges[$o_ptr..$#o_ranges]  if  $o_ptr < @o_ranges;
  push @just_self,  @s_ranges[$s_ptr..$#s_ranges]  if  $s_ptr < @s_ranges;

#warn "just_self: ".join ",", map { "$_->{min}..$_->{max}" } @just_self;
#warn "in_both: ".join ",", map { "$_->{min}..$_->{max}" } @in_both;
#warn "just_other: ".join ",", map { "$_->{min}..$_->{max}" } @just_other;

  return { just_self  => [ @just_self ],
           in_both    => [ @in_both ],
           just_other => [ @just_other ] };
}


sub intersect { intersection(@_); }
sub intersection {
  my ($self, $other) = @_;
  my $sections = $self->sectionify( $other );
  return multi_union( @{$sections->{in_both}} );
}

sub minus { subtract(@_); }
sub subtraction { subtract(@_); }
sub subtract {
  my ($self, $other) = @_; 
  my $sections = $self->sectionify( $other );
  return multi_union( @{$sections->{just_self}} );
}  

sub xor {
  my ($self, $other) = @_; 
  my $sections = $self->sectionify( $other );
  return multi_union( @{$sections->{just_self}}, @{$sections->{just_other}} );
}

sub union {
  my ($self, @other) = @_;
  return multi_union( $self, @other )  if  @other > 1;
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
        die "internal error: nothing defined in s_ranges or o_ranges";
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

sub contains {
  my ($self, $n) = @_;
  foreach my $sr (@{$self->{ranges}}) {
    return 1  if  ($n >= $sr->{min}) && ($n <= $sr->{max});
  }
  return;
}


1;

