# Number::Range::Regex

#
# Copyright 2012 Brian Szymanski.  All rights reserved.  This module is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.

package Number::Range::Regex;

use strict;
use Number::Range::Regex::Range;
use Number::Range::Regex::Iterator;
use Number::Range::Regex::Util;
use vars qw ( @ISA @EXPORT @EXPORT_OK $VERSION ); 
eval { require warnings; }; #it's ok if we can't load warnings

require Exporter;
use base 'Exporter';
@ISA    = qw( Exporter );
@EXPORT = qw( range rangespec );
@EXPORT_OK =  qw( init range rangespec regex_range );

$VERSION = '0.12';

my $default_opts = $Number::Range::Regex::Range::default_opts;
my $init_opts = $default_opts;

sub features {
  return { negative => 0 };
}

sub init {
  my ($self, @opts) = @_;

  # vestigial limb: init( foo => "bar" ) == init( { foo => "bar" } );
  my %opts = (@opts == 1) ? %{$opts[0]} :
             (@opts % 2 == 0) ? @opts :
             die 'usage: init( $options_ref )';

  $init_opts = $default_opts;
  # override any values of init_opts that were passed to init
  while (my ($key, $value) = each %opts) {
    $init_opts->{$key} = $value;
  }
}

# regex_range( $min, $max ); #undef = no limit, so. e.g.
#   regex_range(3, undef) yields the equivalent of qr/[+]?[3-9]|\d+/;
sub regex_range {
  my ($min, $max, $passed_opts) = @_;

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

  my $range = Number::Range::Regex::SimpleRange->new( $min, $max, $opts );

  return $range->regex( $opts );
}

sub range {
  return Number::Range::Regex::SimpleRange->new( @_ );
}

sub rangespec {
  my $opts;
  if(ref $_[-1]) {
    $opts = option_mangler( pop );
  }
  # we allow (but do not like) e.g. rangespec(5,7,10..18);
  # we don't like it because it can make us run out of memory for
  # large ranges. preferred: rangespec('5,7,10..18');
  my $range;
  if(@_ > 1) {
    warn "passed literal range to rangespec!\n";
    $range = join ',', @_;
  } else {
    $range = $_[0];
  }

  # TODO: allow ..3 to mean less than 3, 3.. to mean more than 3 as in
  #       regex_range ?
  my $section_validate  = qr/(?:\d+\.\.\d+|\d+)/;
  my $range_validate = qr/$section_validate(?:,$section_validate)*/;
  $range =~ s/\s+//g;
  die "invalid range '$range'"  unless  $range =~ /^$range_validate$/;

  my @sections = split(',', $range);
  my @ranges;
  foreach my $section (@sections) {
    if($section =~ /^(\d+)\.\.(\d+)$/) {
      push @ranges, Number::Range::Regex::SimpleRange->new( $1, $2, $opts );
    } elsif($section =~ /^(\d+)$/) {
      push @ranges, Number::Range::Regex::SimpleRange->new( $1, $1, $opts );
    } else {
      die "can't parse section: '$section'";
    }
  }
  # note: multi_union() will have the side effect of sorting
  #       and de-overlap-ify-ing the input ranges
  return multi_union( @ranges );
}

1;

__END__

=head1 NAME

Number::Range::Regex - create regular expressions that check for
                       integers in a given range

=head1 SYNOPSIS

  use Number::Range::Regex;
  my $lt_20 = range( 0, 19 );

  print "foo($foo) contains an integer < 20" if $foo =~ /$lt_20/;
  print "foo($foo) is an integer < 20" if $foo =~ /^$lt_20$/;
  if( $line =~ /^\S+\s+($lt_20)\s/ ) {
    print "the second field ($1) is an integer < 20";
  }
  my $nice_numbers = rangespec( "42,175..192" );
  my $my_values = $lt_20->union( $nice_numbers );
  if( $line =~ /^\S+\s+($my_values)\s/ ) {
    print "the second field has one of my values ($1)";
  }

  my $lt_10        = rangespec( "0..9" );
  my $primes_lt_30 = rangespec( "2,3,5,7,11,13,17,19,23,29" );
  my $primes_lt_10 = $lt_10->intersection( $primes_lt_30 );
  my $nonprimes_lt_10 = $lt_10->minus( $primes_lt_30 );
  print "nonprimes under 10 contains: ".join",", $nonprimes_lt_10->to_string;
  if( $something =~ /^$nonprimes_lt_10$/ ) {
    print "something($something) is a nonprime less than 10";
  }
  if( $nonprimes_lt_10->contains( $something ) ) {
    print "something($something) is a nonprime less than 10";
  }
  
  my $octet = range(0, 255);
  my $ip4_match = qr/^$octet\.$octet\.$octet\.$octet$/;
  my $range_96_to_127 = range(96, 127);
  my $my_slash26_match = qr/^192\.168\.42\.$range_96_to_127$/;
  my $my_slash19_match = qr/^192\.168\.$range_96_to_127\.$octet$/;

  my $in_a_or_in_b_but_not_both = $a->xor($b);

  my $it = $range->iterator();
  $it->first;
  do { print $it->fetch } while ($it->next);
  $it->last;
  do { print $it->fetch } while ($it->prev);
  

=head1 DESCRIPTION

which is more legible - this?

  $date =~ m/^0*(?:[1-9]|[12][0-9]|3[01])\/0*(?:[0-9]|1[012])$/;

or this?

  my $day_range = range(1, 31);
  my $month_range = range(1, 12);
  $date =~ m/^$day_range\/$month_range$/;

(bonus points if you spotted the bug)


=head1 NOTES

It's usually better to check for number-ness only in the regular
expression and verify the range of the number separately, eg:
  $line =~ /^\S+\s+(\d+)/ && $1 > 15 && $1 < 32;
but it's not always practical to refactor in that way.

If you like one-liners, something like the following may suit you...
  m{^${\( range(1, 31) )}\/${\( range(1, 12) )}$}
but, for readability's sake, please don't do that!


=head1 NOTES

Non-negative integers only for now.


=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests through the
web interface at L<http://rt.cpan.org>.


=head1 AUTHOR

Brian Szymanski  B<< <ski-cpan@allafrica.com> >> -- be sure to put
Number::Range::Regex in the subject line if you want me to read
your message.


=head1 SEE ALSO

perl(1), Number::Range, etc.


=cut
