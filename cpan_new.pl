#!/usr/bin/env perl

use 5.010001;
use strict;
use warnings;

use English qw( -no_match_vars );    # Avoids regex performance penalty
$OUTPUT_AUTOFLUSH = 1;

our $VERSION = '0.101';

use autodie;
use diagnostics;

use CPAN;

CPAN::HandleConfig->load;
CPAN::Shell::setup_output;
CPAN::Index->reload;

say 'START';

my @modules = qw(
  Term::ReadKey
  Term::ReadLine::Perl
  YAML
  YAML::XS
  CPAN::SQLite
  CPAN::Reporter
  JSON
  JSON::XS
  Test::Reporter::Transport::Metabase
  Crypt::SSLeay
  LWP::UserAgent
  LWP::Protocol::https
  IO::Socket::SSL
  Module::Install::DSL
  App::cpanminus
  App::cpanminus::reporter
  App::pmuninstall
  Perl::Version
  IPC::System::Simple
  Carp::Always::Color
  App::perlbrew
);

# install into a virgin perlbrew:
for my $mod (@modules) {
  CPAN::Shell->install($mod);
}

say 'END';

__END__

