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
# 4) it depends on the underlying libc's definition of the string
#    version of infinity, which on win32 is '1.#INF', solaris
#    'Infinity', and libc 'inf'

use strict;
use vars qw ( @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION ); 
eval { require warnings; }; #it's ok if we can't load warnings

require Exporter;
use base 'Exporter';
@ISA    = qw( Exporter );
@EXPORT = qw ( );
@EXPORT_OK = qw ( _cmp _lt _le _eq _ge _gt _ne pos_inf neg_inf is_inf );
%EXPORT_TAGS = ( all => [ @EXPORT, @EXPORT_OK ] );

$VERSION = '0.31';

use overload '<=>' => \&_cmp, # also defines <, <=, ==, !=, >, >=
             '+'   => \&_add, # with neg, also defines non-unary -
             'neg' => \&neg,
             '""'  => sub { my $self = shift; return $$self };

sub pos_inf { my $v = '+inf'; return bless \$v, __PACKAGE__; }
sub neg_inf { my $v = '-inf'; return bless \$v, __PACKAGE__; }

# returns -1 if this is neg_inf, 0 if this is non-infinite, 1 if pos_inf
sub is_inf {
  my ($val) = @_;
  return -1  if  "$val" eq '-inf';
  return  1  if  "$val" eq '+inf';
  return 0;
}

sub neg {
  my ($val) = @_;
  return pos_inf  if  is_inf($val)==-1;
  return neg_inf  if  is_inf($val)==1;
  return -$val;
}

sub _add {
  my ($l, $r, $swapped) = @_;
  ($l, $r) = ($r, $l) if $swapped;
  if(is_inf($l) && is_inf($r)) {
    die "neg_inf + pos_inf is undefined"  if  is_inf($l) != is_inf($r);
    return $l; # -inf + -inf == -inf, +inf + +inf == +inf
  } elsif(is_inf($l)) {
    return $l; #+-inf + any non infinite quantity = +-inf
  } elsif(is_inf($r)) {
    return $r; #+-inf + any non infinite quantity = +-inf
  } else {
    die __PACKAGE__."::_add: internal error: neither $l nor $r are infinite?";
  }
}

sub _cmp {
  my ($l, $r, $swapped) = @_;
  ($l, $r) = ($r, $l) if $swapped;
  die 'internal error' unless defined $l and defined $r; # phase this out
  if("$l" eq '-inf') {
    return "$r" eq '-inf' ? 0 : -1;
  } elsif("$l" eq '+inf') {
    return "$r" eq '+inf' ? 0 : 1;
  } elsif("$r" eq '-inf') {
    return 1; #we know $l ne '-inf', we checked it above
  } elsif("$r" eq '+inf') {
    return -1; #we know $l ne '+inf', we checked it above
  } else {
    die __PACKAGE__."::_add: internal error: neither $l nor $r are infinite?";
  }
}

1;

