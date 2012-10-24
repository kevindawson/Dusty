#!/usr/bin/env perl

use 5.014;
use strict;
use warnings;

# Turn on $OUTPUT_AUTOFLUSH
$| = 1;

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


my @modules =
	qw( Padre Padre::Plugin::PerlTidy Padre::Plugin::PerlCritic Text::Aspell Text::Huspell Padre::Plugin::SpellCheck );

# install Padre on top of perlbrew and cpan_new.pl:
for my $mod (@modules) {
	CPAN::Shell->install($mod);
}


say 'END';

1;

__END__
