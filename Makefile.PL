use ExtUtils::MakeMaker;
#use Getopt::Long;

use strict;

WriteMakefile(
  'NAME'	=> 'Number::Range::Regex',
  'VERSION_FROM' => 'lib/Number/Range/Regex.pm', # finds $VERSION
  'PREREQ_PM' => { 'overload' => 0 },
#  'PREREQ_PM' => { 'overload' => '1.10' },

  'dist'	=> { COMPRESS => 'gzip -9', SUFFIX => 'gz' },
);
