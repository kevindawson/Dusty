#!/usr/bin/env perl

use 5.014;
use strict;
use warnings;

use English qw( -no_match_vars );
local $OUTPUT_AUTOFLUSH = 1;

use feature 'unicode_strings';

use autodie;
use diagnostics;

say 'START';

use CPAN;

CPAN::HandleConfig->load;
CPAN::Shell::setup_output;
CPAN::Index->reload;

my @modules = qw(
  CPAN::Changes
  CPAN::Meta
  Perl::Critic
  Perl::MinimumVersion
  Test::CPAN::Changes
  Test::CPAN::Changes::ReallyStrict
  Test::CPAN::Meta
  Test::CheckChanges
  Test::DistManifest
  Test::EOL
  Test::HasVersion
  Test::Kwalitee
  Test::Kwalitee::Extra
  Test::MinimumVersion
  Test::Perl::Critic
  Test::Pod
  Test::Pod::Coverage
  Test::Portability::Files
  Test::Tabs
  Test::Requires
  Test::Spelling
  Test::Synopsis
  Test::Version
  Test::Vars
);

for my $mod (@modules) {
  CPAN::Shell->install($mod);
}

say 'END';

__END__
