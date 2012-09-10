# Number::Range::Regex::Range
#
# Copyright 2012 Brian Szymanski.  All rights reserved.  This module is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.

package Number::Range::Regex::Range;

use strict;
use Number::Range::Regex::TrivialRange;
use vars qw ( @ISA @EXPORT @EXPORT_OK $VERSION ); 
eval { require warnings; }; #it's ok if we can't load warnings

require Exporter;
use base 'Exporter';
@ISA    = qw( Exporter );

$VERSION = '0.08';

our $default_opts = {
  allow_wildcard => 0,
  autoswap => 0,

  no_leading_zeroes => 0,
  no_sign           => 0,
  comment           => 1,
  readable          => 0,
};

sub new_by_trivial_range {
  my ($class, $trivial_range) = @_;
  my ($min, $max) = ($trivial_range->{min}, $trivial_range->{max});
  my $self = bless { min => $min, max => $max, ranges => [ $trivial_range ] }, $class;
  $self->{contiguous} = 1;
  return $self;
}

sub new_by_range {
  my ($class, $min, $max, $passed_opts) = @_;
  my $self = bless { min => $min, max => $max, ranges => [] }, $class;
  $self->{contiguous} = 1;

  # local options can override defaults
  my $opts;
  if($passed_opts) {
    die "too many arguments" unless ref $passed_opts eq 'HASH';
    # make a copy of options hashref, add overrides
    $opts = { %{$default_opts} };
    while (my ($key, $val) = each %$passed_opts) {
      $opts->{$key} = $val;
    }
  } else {
    $opts = $default_opts;
  }

  #canonicalize min and max by removing leading zeroes unless the value is 0
  if(defined $min) { $min =~ s/^0+//; $min = 0 if $min eq ''; }
  if(defined $max) { $max =~ s/^0+//; $max = 0 if $max eq ''; }

  if(defined $min) {
    if( $min !~ /^[+]?\d+$/ ) {
    #if( $min !~ /^[-+]?\d+$/ ) {
      die "min ($min) must be a positive number or undef";
    }
  }
  if(defined $max) {
    if( $max !~ /^[+]?\d+$/ ) {
#    if( $max !~ /^[-+]?\d+$/ ) {
      die "max ($max) must be a positive number or undef";
    }
  }

  if( !defined($min) && !defined($max)) {
    if($opts->{allow_wildcard}) {
      $self->{ranges} = [ Number::Range::Regex::TrivialRange->new(
                            undef, undef, '\d+' ) ];
      return $self;
    } else {
      die "must specify either a min or a max";
    }
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

  if($min > $max) {
    if($opts->{autoswap}) {
      ($min, $max) = ($max, $min);
    } else {
      die "min must be less than or equal to max";
    }
  }

  die "TODO: support for negative values not yet implemented" if $min < 0;

  if ($min == $max) {
    $self->{ranges} = [ Number::Range::Regex::TrivialRange->new(
                          $min, $min, "$min" ) ];
    return $self;
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

  push @{$self->{ranges}},
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

  push @{$self->{ranges}},
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
    push @{$self->{ranges}}, Number::Range::Regex::TrivialRange->new(
                               $min_range, undef, "\\d{$min_digits,}");
  }

  $self->_collapse_tranges();

  return $self; 
}

sub _collapse_tranges {
  my ($self) = @_;
  # collapse (TODO: we should keep more info in TrivialRange.pm and
  #           avoid parsing the dern regex here!
  my $last_one = [];
  my $range_n = 0;
  while($range_n <= $#{$self->{ranges}}) {
    if($self->{ranges}->[$range_n]->{regex} =~ /,\}$/) {
      #warn "cannot collapse infinite ranges\n";
      $last_one = [];
      $range_n++;
      last;
    }
    my $norm = _normalize_re($self->{ranges}->[$range_n]->{regex});
#warn "norm: $norm";
#warn "$self->{ranges}->[$range_n]->{regex} -> $norm ...\n";
    $norm =~ s/((?:\\d)*)$//;
    my $wildcard_len = length($1)/2;
    my ($digmin, $digmax);
    if($norm =~ s/\[(\d+)-(\d+)\]$//) {
      ($digmin, $digmax) = ($1, $2);
    } else {
      $norm =~ s/(\d)$//;
      $digmin = $digmax = $1;
    }
    my $header = $norm;
#warn "  -> $header/$digmin..$digmax/$wildcard_len";
    if($range_n && $last_one->[0] eq $header && $last_one->[3] == $wildcard_len) {
#      warn "collapsible: $header/$digmin..$digmax/$wildcard_len and ".
#           "$last_one->[0]/$last_one->[1]..$last_one->[2]/$last_one->[3]";
      my @set = map { 0 } 0..9;
      $set[$_] = 1  for  $digmin..$digmax;
      $set[$_] = 1  for  $last_one->[1]..$last_one->[2];
      my $first = 0;
      $first++  while  !$set[$first];
      # don't collapse 0-ranges or else we'll get e.g. [0-4]\d for 0..49
      # (which recognizes e.g. "03" but not "3")
      if(!length($header) && $first == 0) {
        $range_n++;
        next;
      }
      my $last = 9;
      $last--  while  !$set[$last];
      my $min_n = $header.$first.(0 x $wildcard_len);
      my $max_n = $header.$last.(9 x $wildcard_len);
      my $has_gap = 0;
      for(my $c=$first; $c<=$last; ++$c) {
        if(!$set[$c]) {
          $has_gap = 1;
          last;
        }
      }

#warn "set: @set, first: $first, last: $last, min_n: $min_n, max_n: $max_n";
      if(!$has_gap) {
        my $new_tr = Number::Range::Regex::TrivialRange->new(
                 $min_n,
                 $max_n,
                 $header."[$first-$last]".('\d' x $wildcard_len) );
#warn "new_tr: $new_tr->{regex}";
        splice(@{$self->{ranges}}, $range_n-1, 2, $new_tr);
#warn "ranges: ".join(" - ", map { $_->{regex} } @{$self->{ranges}});
        $digmin = $first;
        $digmax = $last;
        $range_n--;
      }
    }
    $last_one = [ $header, $digmin, $digmax, $wildcard_len ];
    $range_n++;
  }
}

sub _normalize_re {
  my ($re) = shift;
  $re =~ s/\[0-9\]/\\d/g;
  $re .= '\d' x $1  if  $re =~ s/\\d[{](\d+)[}]//;
  $re = '[0-9]'  if  $re eq '\\d';
  return $re;
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

sub regex {
  my ($self, $passed_opts) = @_;

  # the empty set has no regex
  return  unless  @{$self->{ranges}};

  # local options can override defaults
  my $opts;
  if($passed_opts) {
    die "too many arguments" unless ref $passed_opts eq 'HASH';
    # make a copy of options hashref, add overrides
    $opts = { %{$default_opts} };
    while (my ($key, $val) = each %$passed_opts) {
      $opts->{$key} = $val;
    }
  } else {
    $opts = $default_opts;
  }

  my $separator = $opts->{readable} ? ' | ' : '|';
  my $regex_str = join $separator, map { $_->{regex} } @{$self->{ranges}};
  $regex_str = " $regex_str " if $opts->{readable};

  my $modifier_maybe = $opts->{readable} ? '(?x)' : '';
  my $sign_maybe     = $opts->{no_sign} ? '' : '[+]?';
  my $zeroes_maybe   = $opts->{no_leading_zeroes} ? '' : '0*';
  my $comment_maybe  = '';
  if($opts->{comment}) {
    if($self->{contiguous}) {
      my ($min, $max) = ($self->{min}, $self->{max});
      ($min, $max) = map { defined $_ ? $_ : '[unset]' } ($min, $max);
      my $comment = "Number::Range::Regex[$min..$max]";
      $comment_maybe = $opts->{readable} ? " # $comment" : "(?#$comment)";
    } else {
      my $comment = "Number::Range::Regex[compound range]";
      $comment_maybe = $opts->{readable} ? " # $comment" : "(?#$comment)";
    }
  }
  return qr/$modifier_maybe$sign_maybe$zeroes_maybe(?:$regex_str)$comment_maybe/; 
}

sub union {
  my ($self, $other) = @_;
  
  my @s_ranges = @{$self->{ranges}};
  my @o_ranges = @{$other->{ranges}};
  my @new_ranges;
  if( $s_ranges[0]->{min} < $o_ranges[0]->{min} ) {
    @new_ranges = shift @s_ranges;
  } else {
    @new_ranges = shift @o_ranges;
  }

  while(@s_ranges || @o_ranges) {
    my $next_tr;
#warn "top loop new_ranges: ".join(" ", map { $_->regex } @new_ranges);
    if( defined $s_ranges[0] ) {
      if( defined $o_ranges[0] ) {
        if( $s_ranges[0]->{min} < $o_ranges[0]->{min} ) {
          $next_tr = shift @s_ranges;
        } else {
          $next_tr = shift @o_ranges;
        }
      } else {
        $next_tr = shift @s_ranges;
      } 
    } else {
      if( defined $o_ranges[0] ) {
        $next_tr = shift @o_ranges;
      } else {
        die "internal error";
      } 
    } 

    if($next_tr->touches($new_ranges[-1])) {
      my $last_tr = pop @new_ranges;
#warn "last_tr: $last_tr->{min}..$last_tr->{max}";
#warn "next_tr: $next_tr->{min}..$next_tr->{max}";
      my $tr_union = $next_tr->union($last_tr);
      if($tr_union->isa('Number::Range::Regex::TrivialRange')) {
        push @new_ranges, $tr_union;
      } else {
        push @new_ranges, @{$tr_union->{ranges}};
      }
    } else {
      push @new_ranges, $next_tr;
    }
  }
  my $union = bless { ranges => [ @new_ranges ] }, 'Number::Range::Regex::Range';
  $union->_collapse_tranges();
  $union->_set_minmax();

  return $union;
}

sub _set_minmax {
  my ($self) = @_;
  my $pos = $self->{ranges}->[0]->{min};
  foreach my $tr (@{$self->{ranges}}) {
    # nothing to do if not contiguous
    return  if  $pos != $tr->{min};
    $pos = $tr->{max}+1;
  }
#warn "_set_minmax'd ".join(" ", map { $_->regex } @{$self->{ranges}});
  $self->{contiguous} = 1;
  $self->{min} = $self->{ranges}->[0]->{min};
  $self->{max} = $self->{ranges}->[-1]->{max};
}

1;

