# Number::Range::Regex::Iterator
#
# Copyright 2012 Brian Szymanski.  All rights reserved.  This module is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.

package Number::Range::Regex::Iterator;

use strict;
use vars qw ( @ISA @EXPORT @EXPORT_OK $VERSION ); 
eval { require warnings; }; #it's ok if we can't load warnings

require Exporter;
use base 'Exporter';
@ISA    = qw( Exporter );

$VERSION = '0.11';

use overload bool => \&in_range,
             '""' => sub { return $_[0] };

sub new {
  my ($class, $range) = @_;

  my $self = bless { range => $range }, $class; 

  if($range->isa('Number::Range::Regex::CompoundRange')) {
    $self->{ranges} = $range->{ranges};
  } elsif($range->isa('Number::Range::Regex::SimpleRange')) {
    $self->{ranges} = [ $range ];
  } elsif($range->isa('Number::Range::Regex::EmptyRange')) {
    die "can't iterate over an empty range";
  } else {
    die "unknown arg: $range, usage: Iterator->new( \$range )";
  } 

  foreach my $range ( @{$self->{ranges}} ) {
    $self->{size} += $range->{max} - $range->{min} + 1;
  }
  $self->first();

  return $self; 
}

sub first {
  my ($self) = @_;
  $self->{number}       = $self->{ranges}->[0]->{min};
  $self->{offset}       = 0;
  $self->{rangenum}     = 0;
  $self->{rangepos}     = 0;
  $self->{out_of_range} = 0;
  return $self; 
}

sub last {
  my ($self) = @_;
  my $last_tr = $self->{ranges}->[-1];
  $self->{number}       = $last_tr->{max};
  $self->{offset}       = $self->{size}-1;
  $self->{rangenum}     = $#{$self->{ranges}};
  $self->{rangepos}     = $last_tr->{max} - $last_tr->{min};
  $self->{out_of_range} = 0;
  return $self; 
}

sub fetch {
  my ($self) = @_;
  die "can't fetch() an out of range ($self->{out_of_range}) iterator"  if  $self->{out_of_range};
  return $self->{number};
}

sub next {
  my ($self) = @_;
  die "can't next() an out of range ($self->{out_of_range}) iterator"  if  $self->{out_of_range};

  if($self->{number} == $self->{ranges}->[-1]->{max}) {
    $self->{out_of_range} = 'overflow';
    return $self;
  }

#warn "next: number: $self->{number}, offset: $self->{offset}, rangenum: $self->{rangenum}, rangepos: $self->{rangepos}\n";
  $self->{offset}++;
  my $this_tr = $self->{ranges}->[ $self->{rangenum} ];
  if( $self->{rangepos} < $this_tr->{max} - $this_tr->{min} ) {
    $self->{rangepos}++;
    $self->{number}++;
  } else {
    $self->{rangenum}++;
    $self->{rangepos} = 0;
    $self->{number} = $self->{ranges}->[ $self->{rangenum} ]->{min};
  }
  return $self;
}

sub prev {
  my ($self) = @_;
  die "can't prev() an out of range ($self->{out_of_range}) iterator"  if  $self->{out_of_range};

  if($self->{offset} == 0) {
    $self->{out_of_range} = 'underflow';
    return $self;
  }

#warn "prev: number: $self->{number}, offset: $self->{offset}, rangenum: $self->{rangenum}, rangepos: $self->{rangepos}\n";
  $self->{offset}--;
  if( $self->{rangepos} > 0 ) {
    $self->{rangepos}--;
    $self->{number}--;
  } else {
    $self->{rangenum}--;
    my $tr = $self->{ranges}->[ $self->{rangenum} ];
    $self->{rangepos} = $tr->{max} - $tr->{min};
    $self->{number} = $tr->{max};
  }
  return $self;
}

sub in_range {
  my ($self) = @_;
  return ! $self->{out_of_range};
}

1;

