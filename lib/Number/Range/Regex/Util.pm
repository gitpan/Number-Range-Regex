# Number::Range::Regex::Util
#
# Copyright 2012 Brian Szymanski.  All rights reserved.  This module is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.

package Number::Range::Regex::Util;

use strict;
use vars qw ( @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION ); 
eval { require warnings; }; #it's ok if we can't load warnings

require Exporter;
use base 'Exporter';
@ISA    = qw( Exporter );
@EXPORT = qw ( most min max multi_union
               option_mangler has_regex_overloading );
@EXPORT_OK = qw ( _sort_by_min ) ;
%EXPORT_TAGS = ( all => [ @EXPORT, @EXPORT_OK ] );

$VERSION = '0.30';

require overload;
sub has_regex_overloading {
  # http://www.gossamer-threads.com/lists/perl/porters/244314 
  # http://search.cpan.org/~jesse/perl-5.12.0/pod/perl5120delta.pod#qr_overload$ 
  # 1.08, 1.09 are too low. 1.10: works 
  # http://search.cpan.org/~jesse/perl-5.11.1/lib/overload.pm
  return defined $overload::VERSION && $overload::VERSION > '1.09';
}

sub most(&@) {
  my ($condition, $first, @rest) = @_;
  my $most = $first;
  no strict 'refs';
  my $pkg = caller;
  local *{ $pkg . '::b' } = \$most;
  foreach my $o (@rest) {
    local *{ $pkg . '::a' } = \$o;
    $most = $o  if  $condition->();
  }
  return $most; 
}

sub min { return most { $a < $b } @_ }
sub max { return most { $a > $b } @_ }

sub multi_union {
  my @ranges = @_;
  my $self = shift @ranges;
  $self = $self->union( $_ )  for  @ranges;
  return $self;
}

sub option_mangler {
  my ($passed_opts) = @_;
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
  return $opts;
}

sub _sort_by_min {
  my ($a, $b) = @_;
  return $a->{min} < $b->{min} ? ($a, $b) : ($b, $a);
}

1;

