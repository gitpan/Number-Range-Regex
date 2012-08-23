use ExtUtils::MakeMaker;
#use Getopt::Long;

use strict;

WriteMakefile(
  'NAME'	=> 'Number::Range::Regex',
  'VERSION_FROM' => 'lib/Number/Range/Regex.pm', # finds $VERSION

  'dist'	=> { COMPRESS => 'gzip -9', SUFFIX => 'gz' },
);
