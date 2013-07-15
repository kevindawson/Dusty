#!/usr/bin/env perl

use 5.010001;
use strict;
use warnings FATAL => 'all';

use English qw( -no_match_vars );    # Avoids reg-ex performance penalty
local $OUTPUT_AUTOFLUSH = 1;

use feature 'unicode_strings';

# use open qw( :encoding (UTF-8) :STD );

use autodie;
use diagnostics;

# use Data::Printer {caller_info => 1, colored => 1,};

say 'START';

use CPAN;

CPAN::HandleConfig->load;
CPAN::Shell::setup_output;
CPAN::Index->reload;


my @modules = qw(
  Code::Explain
  DBI
  Data::Printer
  DateTime
  IRC::Utils
  POE
  POE::Component::IRC
  POE::Component::IRC::Plugin::AutoJoin
  POE::Component::IRC::Plugin::FollowTail
  POE::Component::IRC::Plugin::Logger
  POE::Component::IRC::State
  YAML::XS
);

# install Padre on top of perlbrew and cpan_new.pl:
for my $mod (@modules) {
  CPAN::Shell->install($mod);
}


say 'END';

1;

__END__
