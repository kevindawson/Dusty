#!/usr/bin/env perl

use v5.14;
use strict;
use warnings;

our $VERSION = '0.03';
use English qw( -no_match_vars ); # Avoids regex performance penalty
local $OUTPUT_AUTOFLUSH = 1;

use feature 'unicode_strings';
use Try::Tiny;

# use diagnostics;
use Data::Printer {
	caller_info => 1,
	colored     => 1,
};

use PPI;
use Module::CoreList;
use CPAN;

use Carp::Always::Color;

say 'START';

# check if there are versions in every module and if they are in the same
# allow updating version numbers to one specific version.

use File::Find qw(find);
use File::Slurp qw(read_file write_file);
my @requires      = ();
my %requires      = ();
my %test_requires = ();


my @posiable_directories_to_search = qw( lib scripts bin );
my @directories_to_search;# = qw( lib scripts bin );

for my $directory (@posiable_directories_to_search) {
	if ( -d $directory ) {
		push @directories_to_search, $directory;
	}
}

try {
	find( \&requires, @directories_to_search );
};

sub requires {
	return if $_ !~ /\.p[lm]$/;

	say 'input: ' . $_;
	my @items = ();

	# Load a Document from a file
	my $Document = PPI::Document->new($_);
	my $includes = $Document->find('PPI::Statement::Include');

	if ($includes) {
		foreach my $include ( @{$includes} ) {
			next if $include->type eq 'no';
			if ( not $include->pragma ) {
				my $module = $include->module;

				#deal with ''
				next if $module eq '';

				push @items, $module;

				try {
					my $mod = CPAN::Shell->expand( "Module", $module );

					if ($mod) { # next if not defined $mod;
						if ( $mod->cpan_version && $mod->cpan_version ne 'undef' ) {
							$requires{$module} = $mod->cpan_version;
						}
					}
				};
			}
		}
	}

	# p @items;
	push @requires, @items;

}
print "\n";

# p @requires;
# p %requires;
my $pm_length = 0;
foreach my $key ( sort keys %requires ) {
	if ( length $key > $pm_length ) {
		$pm_length = length $key;
	}
}

# $pm_length;
# say $pm_length;
foreach my $key ( sort keys %requires ) {
	printf "requires %-*s %s\n", $pm_length, $key, $requires{$key};
}



@directories_to_search = qw( t );
find( \&test_requires, @directories_to_search );

sub test_requires {
	return if $_ !~ /\.[t|pm]$/;
	# p $_;
	my @items = ();

	# Load a Document from a file
	my $Document = PPI::Document->new($_);
	my $includes = $Document->find('PPI::Statement::Include');
	if ($includes) {
		foreach my $include ( @{$includes} ) {
			next if $include->type eq 'no';
			if ( not $include->pragma ) {
				my $module = $include->module;
				# p $module;

				#deal with ''
				next if $module eq '';

				try {
					my $mod = CPAN::Shell->expand( "Module", $module );
					# p $mod;

					if ($mod) { # next if not defined $mod;
						if ( $mod->cpan_version ) {
							if ( !$requires{$module} ) {
								$test_requires{$module} = $mod->cpan_version;
							}
						}
					} else {
						$module =~ s/^(\S+)::\S+/$1/;
						# p $module;
						my $mod = CPAN::Shell->expand( "Module", $module );
						# p $mod;

						if ($mod) { # next if not defined $mod;
							if ( $mod->cpan_version ) {
								if ( !$requires{$module} ) {
									$test_requires{$module} = $mod->cpan_version;
								}
							}
						}
					}
				};
			}
		}
	}
}
print "\n";

# p %test_requires;
$pm_length = 0;
foreach my $key ( sort keys %test_requires ) {
	if ( length $key > $pm_length ) {
		$pm_length = length $key;
	}
}

# $pm_length;
# say $pm_length;
foreach my $key ( sort keys %test_requires ) {
	printf "test_requires %-*s %s\n", $pm_length, $key, $test_requires{$key};
}

print "\n";
say 'END';

exit(0);

__END__
