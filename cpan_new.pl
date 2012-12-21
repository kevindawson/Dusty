#!/usr/bin/env perl

use 5.012;
use strict;
use warnings;

use English qw( -no_match_vars ); # Avoids regex performance penalty
$OUTPUT_AUTOFLUSH = 1;

our $VERSION = '0.101';

use autodie;
use diagnostics;


say 'START';

use CPAN;

CPAN::HandleConfig->load;
CPAN::Shell::setup_output;
CPAN::Index->reload;


my @modules =
	qw( Term::ReadKey Term::ReadLine::Perl YAML YAML::XS CPAN::SQLite CPAN::Reporter JSON JSON::XS Test::Reporter::Transport::Metabase LWP::UserAgent Crypt::SSLeay LWP::Protocol::https IO::Socket::SSL Module::Install::DSL App::perlbrew App::cpanminus App::pmuninstall IPC::System::Simple );

# install into a virgin perlbrew:
for my $mod (@modules) {
	CPAN::Shell->install($mod);
}


say 'END';

1;

__END__

