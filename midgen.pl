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
use autodie;
use Data::Printer {
	caller_info => 1,
	colored     => 1,
};

use PPI;
use Module::CoreList;
use CPAN;
CPAN::HandleConfig->load;
CPAN::Shell::setup_output;
CPAN::Index->reload;

# use Carp::Always::Color;


# check if there are versions in every module and if they are in the same
# allow updating version numbers to one specific version.

use File::Find qw(find);
use File::Slurp qw(read_file write_file);
my @requires      = ();
my %requires      = ();
my %test_requires = ();
my @package_names;
my $package_name;
my $format = 'mi'; # dsl | mi | build

# my $ignore_base = 1;    # 1 true ignore perl base functions

my @posiable_directories_to_search = ();
my @directories_to_search          = ();

# my $mod_version = 'current';
my $mod_version = 5.010000;

use Getopt::Long;
Getopt::Long::Configure("bundling");
use Pod::Usage;
my $help        = 0;
my $base_parent = 0; # 1 true ignore perl base functions
my $core        = 0; # show perl core modules as well
my $verbose     = 0; # option variable with default value (false)
my $mojo        = 0; # 1 true ignore Mojo detection
my $debug       = 0; # lots of good stuff here :)
GetOptions(
	'verbose|v'       => \$verbose,
	'core|c'          => \$core,
	'base|parent|b|p' => \$base_parent,
	'help|h|?'        => \$help,
	'mojo|m'          => \$mojo,
	'debug|d'         => sub { $core = 1; $verbose = 1, $base_parent = 0; $mojo = 0; $debug = 1; },
) or pod2usage(2);
pod2usage(1) if $help;



say 'START';

try {
	find( \&first_package_name, 'lib' );
};
p @package_names if $debug;
$package_name = $package_names[0];
say 'Package: ' . $package_names[0];



if ( defined -d "./lib" ) {
	if ( -d _ ) {

		# print "somefile is a directory\n";
	} else {

		# print "somefile is not a directory\n";
	}
} else {
	print "somefile doesn't exist\n";
}

# Find required modules
@posiable_directories_to_search = qw( lib scripts bin );
@directories_to_search          = ();                   # = qw( lib scripts bin );

# p @posiable_directories_to_search;
for my $directory (@posiable_directories_to_search) {

	# p $directory;
	if ( defined -d $directory ) {

		# say 'ok';
		push @directories_to_search, $directory;
	}
}

# p @directories_to_search;
try {
	# find( \&requires, 'lib' );
	find( \&requires, @directories_to_search );
};



output( 'requires', \%requires );
print "\n";

# remove_children( \%requires );


# Find test_required modules
@posiable_directories_to_search = qw( t );
@directories_to_search          = ();
for my $directory (@posiable_directories_to_search) {
	if ( defined -d $directory ) {
		push @directories_to_search, $directory;
	}
}

try {
	find( \&test_requires, @directories_to_search );
};

output( 'test_requires', \%test_requires );


print "\n";
say 'END';


sub first_package_name {
	my $self = shift;
	return if $_ !~ /\.pm$/;

	# say 'input: ' . $_;
	my @items = ();

	# Load a Document from a file
	my $document = PPI::Document->new($_);
	my $ppi_sp   = $document->find('PPI::Statement::Package');

	push @package_names, $ppi_sp->[0]->namespace;
}

sub requires {
	return if $_ !~ /\.p[lm]$/;

	if ($verbose) {
		say 'looking for requires in: ' . $_;
	}
	my @items = ();

	# Load a Document from a file
	my $Document = PPI::Document->new($_);
	my $includes = $Document->find('PPI::Statement::Include');

	if ($includes) {
		foreach my $include ( @{$includes} ) {
			next if $include->type eq 'no';

			# p $include->pragma;
			# p $include->module;
			# p $include->type;
			if ( $include->pragma !~ /(strict|warnings)/ ) {

				# my $module  = $include->module;
				my @modules = $include->module;
				if ( !$base_parent ) {

					my @base_parent_modules = base_parent( $include->module, $include->content, $include->pragma );
					if (@base_parent_modules) {
						@modules = @base_parent_modules;
					}

				}

				foreach my $module (@modules) {

					# p $module;
					if ( !$core ) {

						p $module if $debug;
						if ( $module ne 'File::Path' ) {
							next if Module::CoreList->first_release($module);
						}
					}

					# my $module = $include->module;

					#deal with ''
					next if $module eq '';
					if ( $module =~ /^$package_name/ ) {

						# don't include our own packages here
						next;
					}
					if ( $module =~ /Mojo/ && !$mojo ) {
						$module = 'Mojolicious';
					}
					if ( $module =~ /^Padre/ && $module !~ /^Padre::Plugin::/ ) {

						# mark all Padre core as just Padre, for plugins
						push @items, 'Padre';
						$module = 'Padre';
					} else {
						push @items, $module;
					}

					# if ( $mod_version eq 'current' ) {

					try {
						my $mod = CPAN::Shell->expand( "Module", $module );

						if ($mod) { # next if not defined $mod;
							        # say $module.' cpan mod version '.$mod->cpan_version;
							        # $requires{$module} = $mod->cpan_version;
							if ( $mod->cpan_version ne 'undef' ) {

								# say $module.' cpan mod version = undef';
								$requires{$module} = $mod->cpan_version;
							}
						}
					};
				}

			}
		}
	}
	push @requires, @items;
}

sub test_requires {

	return if $_ !~ /\.(t|pm)$/;

	if ($verbose) {
		say 'looking for test_requires in: ' . $_;
	}
	my @items = ();

	# Load a Document from a file
	my $Document = PPI::Document->new($_);
	my $includes = $Document->find('PPI::Statement::Include');

	# p $includes;
	if ($includes) {
		foreach my $include ( @{$includes} ) {
			next if $include->type eq 'no';

			# p $include->pragma;
			# p $include->module;
			# p $include->type;
			if ( $include->pragma eq '' && $include->type eq 'use' ) {

				# say 'module';
				# p $include->module;
			}
			if ( $include->pragma =~ /(base)|(parent)/ && $include->type eq 'use' ) {

				# say 'base|parent';
				# p $include->module;
			}

			# if ( not $include->pragma ) {
			if ( $include->pragma !~ /(strict|warnings)/ ) {

				my @modules = $include->module;
				if ( !$base_parent ) {
					my @base_parent_modules = base_parent( $include->module, $include->content, $include->pragma );
					if (@base_parent_modules) {
						@modules = @base_parent_modules;
					}

				}

				foreach my $module (@modules) {

					# p $module;
					if ( !$core ) {

						p $module if $debug;

						# don't ignore Test::More so as to get done_testing
						if ( $module ne 'Test::More' ) {
							next if Module::CoreList->first_release($module);
						}
					}

					#deal with ''
					next if $module eq '';
					if ( $module =~ /^$package_name/ ) {

						# don't include our own packages here
						next;
					}
					if ( $module =~ /Mojo/ && !$mojo ) {
						$module = 'Mojolicious';
					}
					if ( $module =~ /^Padre/ && $module !~ /^Padre::Plugin::/ ) {

						# mark all Padre core as just Padre, for plugins
						push @items, 'Padre';
						$module = 'Padre';
					} else {
						push @items, $module;
					}


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

							p $mod if $debug;

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
}

sub base_parent {
	my $module  = shift;
	my $content = shift;
	my $pragma  = shift;
	my @modules = ();
	if ( $module =~ /(base|parent)/ ) {

		if ($verbose) {
			say 'Info: check ' . $pragma . ' pragma: ';
			say $content;
		}

		$content =~ s/^use (base|parent) //;

		$content =~ s/^qw[\<|\(|\{|\[]\n?\t?\s*//;
		$content =~ s/\s*[\>|\)|\}|\]];\n?\t?$//;
		$content =~ s/(\n\t)/, /g;

		# my @modules = ();
		@modules = split /, /, $content;

		p @modules if $debug;
	}
	return @modules;
}



sub output {
	my $title        = shift || 'title missing';
	my $required_ref = shift || return;

	print "\n";

	my $pm_length = 0;
	foreach my $key ( sort keys %{$required_ref} ) {
		if ( length $key > $pm_length ) {
			$pm_length = length $key;
		}
	}

	say $title . ' => {' if $format eq 'build';

	foreach my $key ( sort keys %{$required_ref} ) {
		given ($format) {
			when ('mi') {
				my $sq_key = "'$key'";
				printf "%s %-*s => '%s';\n", $title, $pm_length + 2, $sq_key, $required_ref->{$key};
			}
			when ('dsl') {
				printf "%s %-*s %s\n", $title, $pm_length, $key, $required_ref->{$key};
			}
			when ('build') {
				my $sq_key = "'$key'";
				printf "\t %-*s => '%s',\n", $pm_length + 2, $sq_key, $required_ref->{$key};
			}
		}
	}
	say '},' if $format eq 'build';
}

sub remove_children {
	my $required_ref = shift || return;
	foreach my $key ( sort keys %{$required_ref} ) {
		say $required_ref->{$key};
		next;
		say $required_ref->{$key};
	}
}




exit(0);

__END__


=head1 NAME

sample - Using Getopt::Long and Pod::Usage

=head1 SYNOPSIS

sample [options]

 Options:
   -help	brief help message
   -core	show perl core modules
   -base	check base includes
   -verbose	
   -debug	lots of stuff

=head1 OPTIONS

=over 4

=item B<--help or -h>

Print a brief help message and exits.

=item B<-core or -c>

Shows modules that are in Perl core

=item B<--verbose or -v>

Show file that are being checked

also show contents of base|parent check

=item B<--parent or -p>

alternative  --base or -b

Turn Off - try to include the contents of base|parent modules as well

=item B<--mojo or -m>

Turn Off - the /Mojo/ to Mojolicious catch

=item B<--debug or -d>

equivalent of -cv and some :)

=back

=head1 DESCRIPTION

B<This program> will read the given input file(s) and do something
useful with the contents thereof.

=cut

