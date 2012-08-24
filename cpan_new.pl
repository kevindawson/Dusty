#!/usr/bin/env perl

use 5.014;
use strict;
use warnings;

# Turn on $OUTPUT_AUTOFLUSH
$| = 1;

use feature 'unicode_strings';
use autodie;
use diagnostics;
# use Data::Printer {caller_info => 1, colored => 1,};

say 'START';

use CPAN;

CPAN::HandleConfig->load;
CPAN::Shell::setup_output;
CPAN::Index->reload;


my @modules
  = qw( Term::ReadKey Term::ReadLine::Perl YAML YAML::XS CPAN::SQLite CPAN::Reporter JSON JSON::XS Test::Reporter::Transport::Metabase LWP::UserAgent Crypt::SSLeay LWP::Protocol::https IO::Socket::SSL Module::Install::DSL App::perlbrew App::cpanminus IPC::System::Simple );

# install into a virgin perlbrew:
for my $mod (@modules) {
  CPAN::Shell->install($mod);
}


say 'END';

1;

__END__

