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


my @modules = qw( Padre Padre::Plugin::PerlTidy Padre::Plugin::PerlCritic
	Padre::Plugin::SpellCheck Padre::Plugin::YAML Padre::Plugin::Cookbook
	Padre::Plugin::Nopaste Padre::Plugin::Git Method::Signatures::Modifiers
	Class::XSAccessor Moo Class::Accessor Term::ANSIColor File::HomeDir
	Time::HiRes Regexp::Debugger Carp::Always::Color Contextual::Return
	Text::Hunspell Text::Aspell );

# install Padre on top of perlbrew and cpan_new.pl:
for my $mod (@modules) {
	CPAN::Shell->install($mod);
}


say 'END';

1;

__END__
