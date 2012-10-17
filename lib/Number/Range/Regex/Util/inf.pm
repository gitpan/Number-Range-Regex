# Number::Range::Regex::Util::inf
#
# Copyright 2012 Brian Szymanski.  All rights reserved.  This module is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.

package Number::Range::Regex::Util::inf;

# why don't we use perl's "support" for inf?
# 1) it is only supported if the underlying libc supports it
# 2) behaves in various different ways between 5.6.X where X <= 1
#    5.6.Y where Y >= 2, 5.8.X where X <= 7, and 5.8.Y where Y >= 8
# 3) it's annoying - you can't implement a function inf() because of
#    perl's desire to look like a shell script. because of this,
#     -inf is interpreted as a bareword so you can say dumb(-foo => bar);
#    but +inf and inf are not ok. and you can't simply "fix" that by
#    adding a sub inf { return 'inf' }; because that generates warning
#    about -inf being ambiguous between the literal and -&inf(); in
#    caller context. granted we can't do this with this implementation
#    either because perl has broken things for anyone who wants to
#    implement such an inf(), but it is annoying enough for me to list

use strict;
use vars qw ( @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION ); 
eval { require warnings; }; #it's ok if we can't load warnings

require Exporter;
use base 'Exporter';
@ISA    = qw( Exporter );
@EXPORT = qw ( );
@EXPORT_OK = qw ( _cmp _lt _le _eq _ge _gt _ne );
%EXPORT_TAGS = ( all => [ @EXPORT, @EXPORT_OK ] );

use overload '<=>' => \&_cmp,
             '<'   => \&_lt,
             '<='  => \&_le,
             '>='  => \&_ge,
             '>'   => \&_gt,
             '=='  => \&_eq,
             '!='  => \&_ne,
             '-'   => \&_add_to_inf,
             '+'   => \&_add_to_inf;

sub _add_to_inf {
  my ($l, $r) = @_;
  die "unimplemented"  if  $r =~ /inf$/;
  return $l  if  $l =~ /inf$/;
  die "unimplemented";
};

sub _cmp {
  my ($l, $r) = @_;
  die 'internal error' unless defined $l and defined $r; # phase this out
  if($l eq '-inf') {
    return $r eq '-inf' ? 0 : -1;
  } elsif($l eq '+inf') {
    return $r eq '+inf' ? 0 : 1;
  } elsif($r eq '-inf') {
    return 1; #we know $l ne '-inf', we checked it above
  } elsif($r eq '+inf') {
    return -1; #we know $l ne '+inf', we checked it above
  } else {
    return $l <=> $r;
  }
}
sub _le { my ($l, $r) = @_; return _cmp($l, $r) != 1; };
sub _lt { my ($l, $r) = @_; return _cmp($l, $r) == -1; };
sub _ge { my ($l, $r) = @_; return _cmp($l, $r) != -1; };
sub _gt { my ($l, $r) = @_; return _cmp($l, $r) == 1; };
sub _eq { my ($l, $r) = @_; return _cmp($l, $r) == 0; };
sub _ne { my ($l, $r) = @_; return _cmp($l, $r) != 0; };

1;

