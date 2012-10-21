# Number::Range::Regex::CompoundRange
#
# Copyright 2012 Brian Szymanski.  All rights reserved.  This module is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.

package Number::Range::Regex::CompoundRange;

use strict;

use vars qw ( @ISA @EXPORT @EXPORT_OK $VERSION ); 
eval { require warnings; }; #it's ok if we can't load warnings

require Exporter;
use base 'Exporter';
@ISA    = qw( Exporter Number::Range::Regex::Range );

$VERSION = '0.31';

use Number::Range::Regex::Util;
use Number::Range::Regex::Util::inf qw ( neg_inf pos_inf );

sub new {
  my ($class, @ranges) = @_;
  my $opts;
  if(ref $ranges[-1] eq 'HASH') {
    $opts = option_mangler( pop @ranges );
  }
  # TODO: should/can we deduplicate here by calling union for each of @ranges?
#  my @sorted_ranges = sort { 
#    #return 0  if  $a->{min} == '-inf' && $b->{min} == '-inf'; #shouldnt happen
#    return -1  if  $a->{min} == '-inf';
#    return 1   if  $b->{min} == '-inf';
#    return $a->{min} <=> $b->{min}
#  } @ranges;
  return bless { ranges => [ @ranges ], opts => $opts }, $class;
#  return bless { ranges => [ @sorted_ranges ], opts => $opts }, $class;
}

sub to_string {
  my ($self, $passed_opts) = @_;

  return Number::Range::Regex::EmptyRange->to_string( @_ ) unless (@{$self->{ranges}});

  return join(',', map { $_->to_string() } @{$self->{ranges}});
}

sub regex {
  my ($self, $passed_opts) = @_;

  my $opts = option_mangler( $self->{opts}, $passed_opts );

#  # handle empty ranges
#  return Number::Range::Regex::EmptyRange->regex( @_ ) unless (@{$self->{ranges}});

  my $separator = $opts->{readable} ? ' | ' : '|';
  my $regex_str = join $separator,
      map { $_->regex( { %$opts, comment => 0 } ) }
      @{$self->{ranges}};
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

sub _do_unequal_min {
#warn "in _do_unequal_min";
  my ($self, $lower, $upper, $ptr, $ranges) = @_;
  if( $lower->{max} > $upper->{max} ) {
    # 3 ranges, last of which may yet overlap
    my $r1 = Number::Range::Regex::SimpleRange->new( $lower->{min}, $upper->{min}-1, $self->{opts} );
    my $r2 = $upper;
    my $r3 = Number::Range::Regex::SimpleRange->new( $upper->{max}+1, $lower->{max}, $self->{opts} );
#warn "l: $lower->{min}..$lower->{max} -> $r1->{min}..$r1->{max},$r2->{min}..$r2->{max},$r3->{min}..$r3->{max}";
    splice( @$ranges, $$ptr, 1, ($r1, $r2, $r3) );
    $$ptr += 2; # $r3 may overlap something else
  } elsif( $lower->{max} >= $upper->{min} ) {
    # 2 ranges, latter of which may yet overlap
    my $r1 = Number::Range::Regex::SimpleRange->new( $lower->{min}, $upper->{min}-1, $self->{opts} );
    my $r2 = Number::Range::Regex::SimpleRange->new( $upper->{min}, $lower->{max}, $self->{opts} );
#warn "l: $lower->{min}..$lower->{max} -> $r1->{min}..$r1->{max},$r2->{min}..$r2->{max}";
    splice( @$ranges, $$ptr, 1, ($r1, $r2 ) );
    $$ptr += 1;
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
                 die "other is neither a simple nor compound range!";

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
#warn "s_ranges: @s_ranges, o_ranges: @o_ranges";
    my $this_s = $s_ranges[$s_ptr];
    my $this_o = $o_ranges[$o_ptr];
#warn "checking this_s: $this_s->{min}..$this_s->{max}, this_o: $this_o->{min}..$this_o->{max}";
    if( $this_s->{min} < $this_o->{min} ) {
#printf STDERR "l==s, ";
      $self->_do_unequal_min($this_s, $this_o, \$s_ptr, \@s_ranges );
    } elsif( $this_s->{min} > $this_o->{min} ) {
#printf STDERR "l==o, ";
      $self->_do_unequal_min($this_o, $this_s, \$o_ptr, \@o_ranges );
    } else { # $this_s->{min} == $this_o->{min}
      if( $this_s->{max} < $this_o->{max} ) {
        # 2 ranges, latter of which may yet overlap
        my $r1 = $this_s;
        my $r2 = Number::Range::Regex::SimpleRange->new($this_s->{max}+1, $this_o->{max}, $self->{opts} );
        splice( @o_ranges, $o_ptr, 1, ($r1, $r2) );
#warn "o: $this_o->{min}..$this_o->{max} -> $r1->{min}..$r1->{max},$r2->{min}..$r2->{max}";
        $o_ptr++; # $r2 may overlap something else
      } elsif( $this_s->{max} > $this_o->{max} ) {
        # 2 ranges, latter of which may yet overlap
        my $r1 = $this_o;
        my $r2 = Number::Range::Regex::SimpleRange->new($this_o->{max}+1, $this_s->{max}, $self->{opts});
        splice( @s_ranges, $s_ptr, 1, ($r1, $r2) );
#warn "s: $this_s->{min}..$this_s->{max} -> $r1->{min}..$r1->{max},$r2->{min}..$r2->{max}";
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


sub intersection {
  my ($self, $other) = @_;
  my $sections = $self->sectionify( $other );
  return multi_union( @{$sections->{in_both}}, $self->{opts} );
}

sub subtract {
  my ($self, $other) = @_; 
  my $sections = $self->sectionify( $other );
  return multi_union( @{$sections->{just_self}}, $self->{opts} );
}  

sub xor {
  my ($self, $other) = @_; 
  my $sections = $self->sectionify( $other );
  return multi_union( @{$sections->{just_self}}, @{$sections->{just_other}}, $self->{opts} );
}

sub invert {
  my ($self) = @_; 
  #TODO: do i need that sort? probably not...
#  my @included = sort {
#    return -1  if  $a->{min} == '-inf';
#    return 1   if  $b->{min} == '-inf';
#    return $a->{min} <=> $b->{min}
#  } @{$self->{ranges}};
  my @included = @{$self->{ranges}};
  my @excluded = ();
  if($included[0]->{min} != neg_inf ) {
    push @excluded, Number::Range::Regex::SimpleRange->new( neg_inf, $included[0]->{min}-1, $self->{opts} );
  }
  for(my $c=1; $c<@included; ++$c) {
    my $last = $included[$c-1];
    my $this = $included[$c];
    if($last->{max}+1 > $this->{min}-1) {
      die "internal error - overlapping SRs?";
    } else {
      push @excluded, Number::Range::Regex::SimpleRange->new( $last->{max}+1, $this->{min}-1, $self->{opts} );
    }
  }
  if($included[-1]->{max} != pos_inf) {
    push @excluded, Number::Range::Regex::SimpleRange->new( $included[-1]->{max}+1, pos_inf, $self->{opts} );
  }
  return Number::Range::Regex::CompoundRange->new( @excluded, $self->{opts} );
}

sub union {
  my ($self, @other) = @_;
  return multi_union( $self, @other, $self->{opts} )  if  @other > 1;
  my $other = shift @other;

  my @new_ranges;
  my @s_ranges = @{$self->{ranges}};
  my @o_ranges = $other->isa('Number::Range::Regex::CompoundRange') ? @{$other->{ranges}} :
                 $other->isa('Number::Range::Regex::SimpleRange') ? ( $other ) :
                 die "other is neither a simple nor compound range!";

  # TODO: might not need the first two clauses here since we can now
  # compare infinite values to integers properly
  if($s_ranges[0]->{min} == neg_inf) {
    @new_ranges = shift @s_ranges;
  } elsif($o_ranges[0]->{min} == neg_inf) {
    @new_ranges = shift @o_ranges;
  } elsif( $s_ranges[0]->{min} < $o_ranges[0]->{min} ) {
    @new_ranges = shift @s_ranges;
  } else {
    @new_ranges = shift @o_ranges;
  }

  while(@s_ranges || @o_ranges) {
    my $next_range;
#warn "top loop new_ranges: ".join(" ", map { $_->regex } @new_ranges);
    if( defined $s_ranges[0] ) {
      if( defined $o_ranges[0] ) {
        if($s_ranges[0]->{min} == neg_inf) {
          $next_range = shift @s_ranges;
        } elsif($o_ranges[0]->{min} == neg_inf) {
          $next_range = shift @o_ranges;
        } elsif( $s_ranges[0]->{min} < $o_ranges[0]->{min} ) {
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
#warn "last_range: $last_range, next_range: $next_range";
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

  my $result = bless { ranges => [ _collapse_ranges(@new_ranges) ],
                       opts => $self->{opts} },
               'Number::Range::Regex::CompoundRange';
  my @minmax = $result->_is_contiguous();
  return Number::Range::Regex::SimpleRange->new( @minmax, $self->{opts} )  if  @minmax;

  return $result; 
}

sub _collapse_ranges {
  my @ranges = @_;
  my $last_r;
  my $this_r = $ranges[0];
  for (my $rpos = 1; $rpos < @ranges; $rpos++ ) {
    $last_r = $this_r;
    $this_r = $ranges[$rpos];
    if($last_r->touches($this_r)) {
      splice(@ranges, $rpos-1, 2, $last_r->union($this_r));
      $rpos--;
    }
  }
  return @ranges; 
}

sub _is_contiguous {
  my ($self) = @_;
  my $last_r;
  my $this_r = $self->{ranges}->[0];
  for (my $rpos = 1; $rpos < @{$self->{ranges}}; $rpos++ ) {
    $last_r = $this_r;
    $this_r = $self->{ranges}->[$rpos];
    return  if  $last_r->{max}+1 < $this_r->{min};
  }
  return ($self->{ranges}->[0]->{min}, $self->{ranges}->[-1]->{max});
}

sub contains {
  my ($self, $n) = @_;
  foreach my $r (@{$self->{ranges}}) {
    return 1  if  $r->contains( $n );
  }
  return;
}

sub has_lower_bound { 
  my ($self) = @_;
  return $self->{ranges}->[0]->has_lower_bound;
}

sub has_upper_bound { 
  my ($self) = @_;
  return $self->{ranges}->[-1]->has_upper_bound;
}

sub is_infinite {      
  my ($self) = @_;
  my $ranges = $self->{ranges};
  return ! ( $ranges->[0]->has_lower_bound && $ranges->[-1]->has_upper_bound );
}

1;

