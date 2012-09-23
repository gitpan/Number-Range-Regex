# Number::Range::Regex::EmptyRange
#
# Copyright 2012 Brian Szymanski.  All rights reserved.  This module is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.

package Number::Range::Regex::EmptyRange;

use strict;
use vars qw ( @ISA @EXPORT @EXPORT_OK $VERSION ); 
use Number::Range::Regex::Util;
eval { require warnings; }; #it's ok if we can't load warnings

require Exporter;
use base 'Exporter';
@ISA    = qw( Exporter Number::Range::Regex::Range );

$VERSION = '0.13';

sub new {
  my ($class) = @_;
  return bless {}, $class; 
}

sub to_string {
  my ($self, $passed_opts) = @_;
  return '';
}

sub regex {
  my ($self, $passed_opts) = @_;

  my $opts = option_mangler( $passed_opts );

  my $regex_str = '(?!)'; # never matches
  $regex_str = " $regex_str " if $opts->{readable};

  my $modifier_maybe = $opts->{readable} ? '(?x)' : '';
  my ($begin_comment_maybe, $end_comment_maybe) = ('', '');
  if($opts->{comment}) {
    my $comment = "Number::Range::Regex::EmptyRange";
    $begin_comment_maybe = $opts->{readable} ? " # begin $comment" : "(?# begin $comment )";
    $end_comment_maybe = $opts->{readable} ? " # end $comment" : "(?# end $comment )";
  }

  return qr/(?:$begin_comment_maybe$modifier_maybe(?:$regex_str)$end_comment_maybe)/;
}

sub touches { return; }
sub overlaps { return; }

sub intersect { intersection(@_); }
sub intersection {
  my ($self, $other) = @_;
  return $self; 
}

sub union {
  my ($self, @other) = @_;
  return multi_union( @other );
}

sub minus { subtract(@_); }
sub subtraction { subtract(@_); }
sub subtract { 
  my ($self, @other) = @_;
  return $self;
}

sub xor {
  my ($self, $other) = @_;
  return $other;
}

sub contains {
  my ($self, $n) = @_;
  return;
}

1;

