# Number::Range::Regex
#
# Copyright 2012 Brian Szymanski.  All rights reserved.  This module is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.

package Number::Range::Regex;

use strict;
use Number::Range::Regex::Range;
use vars qw ( @ISA @EXPORT @EXPORT_OK $VERSION ); 
eval { require warnings; }; #it's ok if we can't load warnings

require Exporter;
use base 'Exporter';
@ISA    = qw( Exporter );
@EXPORT = @EXPORT_OK = qw( regex_range );

$VERSION = '0.08';

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

  my $range = Number::Range::Regex::Range->new_by_range( $min, $max, $opts );

  return $range->regex( $opts );
}

1;

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
