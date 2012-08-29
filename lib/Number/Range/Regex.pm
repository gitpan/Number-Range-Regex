# Number::Range::Regex
#
# Copyright 2012 Brian Szymanski.  All rights reserved.  This module is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.

package Number::Range::Regex;

use strict;
use vars qw (@ISA @EXPORT @EXPORT_OK $VERSION ); 
eval { require warnings; }; #it's ok if we can't load warnings

require Exporter;
use base 'Exporter';
@ISA    = qw( Exporter );
@EXPORT = @EXPORT_OK = qw( regex_range );

$VERSION = '0.04';

my $default_opts = {
  allow_wildcard    => 0,
  autoswap          => 0,
  no_leading_zeroes => 0,
  comment           => 1,
};
my $init_opts;

sub features {
  return { negative => 0 };
}

sub init {
  my ($self, %opts) = @_;
  $init_opts = $default_opts;
  while (my ($key, $value) = each %opts) {
    $init_opts->{$key} = $value;
  }
}

# TODO: support for auto-swapping of min, max if necessary via an option (instead of die'ing)

# regex_range( $min, $max ); #undef = no limit, so. e.g.
#   regex_range(3, undef) yields the equivalent of qr/[+]?[3-9]|\d+/;
sub regex_range {
  my ($min, $max, $passed_opts) = @_;

  # local options can override defaults from init()
  my $opts;
  if($passed_opts) {
    die "regex_range: too many arguments" unless ref $passed_opts eq 'HASH';
    $opts = { %$init_opts };
    while (my ($key, $val) = each %$passed_opts) {
      $opts->{$key} = $val;
    }
  } else {
    $opts = $init_opts;
  }

  #canonicalize min and max by removing leading zeroes unless the value is 0
  if(defined $min) { $min =~ s/^0+//; $min = 0 if $min eq ''; }
  if(defined $max) { $max =~ s/^0+//; $max = 0 if $max eq ''; }

  # regex_range() => error by default
  if( $opts->{allow_wildcard} ) {
    if(!defined $min and !defined $max) {
      return qr/[+]?\d+/;
      #return qr/[-+]?\d+/;
    }
  } else {
    die "regex_range: must specify either a min, a max, or the allow_wildcard option" unless defined $min or defined $max;
  }

  if(defined $min) {
    if( $min !~ /^[+]?\d+$/ ) {
    #if( $min !~ /^[-+]?\d+$/ ) {
      die "regex_range: min ($min) must be a positive number or undef";
    }
  }
  if(defined $max) {
    if( $max !~ /^[+]?\d+$/ ) {
#    if( $max !~ /^[-+]?\d+$/ ) {
      die "regex_range: max ($max) must be a positive number or undef";
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
  if($opts->{autoswap} && ($min > $max)) {
    ($min, $max) = ($max, $min);
  }

  my $zeroes_maybe = $opts->{no_leading_zeroes} ? '' : '0*';

  die "regex_range; min must be less than or equal to max" if $max < $min;

  die "TODO: support for negative values not yet implemented" if $min < 0;

  return qr/$zeroes_maybe$min/ if $min == $max;

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

#warn "min: $min, max: $max, samedigits: $samedigits, rightmost: $rightmost, leftmost: $leftmost";

  my @patterns = ();

  my $header = substr($min, 0, $rightmost);
  for(my $digit_pos = $rightmost; $digit_pos >= $leftmost; $digit_pos--) {
    $header = substr($header, 0, length($header)-1);
    my $trailer_len = $rightmost - $digit_pos;
    my $trailer = '\d'x$trailer_len;

    my $digit   = substr($padded_min, $digit_pos-1, 1);

    my $digit_min = $digit+1;
    $digit_min-- if $digit_pos == $rightmost; #inclusive in ones column only!
    my $digit_max = $max - ($header.('0'x($trailer_len+1)));
    $digit_max = int($digit_max / (10**$trailer_len));
    $digit_max-- if $trailer_len; # inclusive only when this is the last
    $digit_max = 9 if $digit_max > 9;
#warn "digit_min: $digit_min, digit_max: $digit_max, header: $header, padded_header: ".($header.('0'x($trailer_len+1)))."\n";

    my $digit_range;
    if($digit_max < $digit_min) {
      #warn "empty digit_range, skipping: min: $digit_min, max: $digit_max";
      next;
    } elsif($digit_max == $digit_min) {
      $digit_range = $digit_min;
    } else {
      $digit_range = "[$digit_min-$digit_max]";
    }
    push @patterns, $header.$digit_range.$trailer;
#warn "digit_pos: $digit_pos, header: $header, digit: $digit, header: $header, digit_range: $digit_range, trailer: $trailer\n";
  }
#warn "leaving top loop";

  for(my $digit_pos = $leftmost+1; $digit_pos <= $rightmost; $digit_pos++) {
    my $header = substr($max, 0, $digit_pos-1);
    my $trailer_len = $rightmost - $digit_pos;
    my $trailer = '\d'x$trailer_len;

    my $digit   = substr($max, $digit_pos-1, 1);

    my $digit_min = 0;
    my $digit_max = $digit;
    $digit_max-- if $trailer_len; # inclusive only when this is the last
#warn "digit_min: $digit_min, digit_max: $digit_max, header: $header, padded_header: ".($header.('0'x($trailer_len+1)))."\n";

    my $digit_range;
    if($digit_max < $digit_min) {
      #warn "empty digit_range, skipping: min: $digit_min, max: $digit_max";
      next;
    } elsif($digit_max == $digit_min) {
      $digit_range = $digit_min;
    } else {
      $digit_range = "[$digit_min-$digit_max]";
    }
    push @patterns, $header.$digit_range.$trailer;
#warn "digit_pos: $digit_pos, header: $header, digit: $digit, header: $header, digit_range: $digit_range, trailer: $trailer\n";
  }
  if( $goto_positive_infinity ) {
    my $min_digits = length($max)+1;
    push @patterns, "\\d{$min_digits,}";
  }

  my $regex_str = join '|', @patterns;
  my $optional_comment = $opts->{comment} ? "(?#Number::Range::Regex[$min..$max])" : '';
warn "comment: $optional_comment";
  return qr/$zeroes_maybe(?:$regex_str)$optional_comment/;

}

1;

# TODO: do we want an oop version? seems kinda pointless considering
# that we are only generating a regex/string...

__END__

=head1 NAME

Number::Range::Regex - create regular expressions that check for
                       integers in a given range

=head1 SYNOPSIS

  use Number::Range::Regex;
  my $range = regex_range( 15, 3210 );
  if( $jibberish =~ /$range/ ) {
    print "your jibberish contains an integer between 15 and 3210";
  }
  if( $num =~ /^$range$/ ) {
    print "$num is an integer between 15 and 3210";
  }
  if( $line =~ /^\S+\s+$range\s/ ) {
    print "the second field is an integer between 15 and 3210";
  }
  my $octet = regex_range(0, 255);
  my $ip4_match = qr/^$octet\.$octet\.$octet\.$octet$/;
  my $range_96_to_127 = regex_range(96, 127);
  my $my_slash26_match = qr/^192\.168\.42\.$range_96_to_127$/;
  my $my_slash19_match = qr/^192\.168\.$range_96_to_127\.$octet$/;
  

=head1 DESCRIPTION

which is more legible - this?

  $date =~ m/^0*(?:[1-9]|[12][0-9]|3[01])\/0*(?:[0-9]|1[012])$/;

or this?

  my $day_range = regex_range(1, 31);
  my $month_range = regex_range(1, 12);
  $date =~ m/^$day_range\/$month_range$/;

(bonus points if you spotted the bug)


=head1 NOTES

It's usually better to check for number-ness only in the regular
expression and verify the range of the number separately, eg:
  $line =~ /^\S+\s+(\d+)/ && $1 > 15 && $1 < 32;
but it's not always practical to refactor in that way.

If you like one-liners, something like the following may suit you...
  m{^${\( regex_range(1, 31) )}\/${\( regex_range(1, 12) )}$}
but i certainly don't recommend it!

=head1 NOTES

Non-negative integers only for now.

=head1 AUTHOR

Brian Szymanski  B<< <ski-cpan@allafrica.com> >> -- be sure to put
Number::Range::Regex in the subject line if you want me to read
your message.

=head1 SEE ALSO

perl(1), etc.

=cut
