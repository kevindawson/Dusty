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

use Carp::Always::Color;

say 'START';

# check if there are versions in every module and if they are in the same
# allow updating version numbers to one specific version.

use File::Find qw(find);
use File::Slurp qw(read_file write_file);
my @requires      = ();
my %requires      = ();
my %test_requires = ();

my $format      = 'mi'; # dsl | mi | build
my $ignore_base = 1;    # 1 true ignore perl base functions

# my $mod_version = 'current';
my $mod_version = 5.010000;

try {
	find( \&first_package_name, 'lib' );
};
my @package_names;

sub first_package_name {
	return if $_ !~ /\.pm$/;

	# say 'input: ' . $_;
	my @items = ();

	# Load a Document from a file
	my $document = PPI::Document->new($_);
	my $ppi_sp = $document->find('PPI::Statement::Package');

	push @package_names, $ppi_sp->[0]->namespace;
}
my $package_name = $package_names[0];
say 'Package: ' . $package_names[0];



    if (defined -d "./lib") {
        if (-d _) {
            print "somefile is a directory\n";
        } else {
            print "somefile is not a directory\n";
        }
    } else {
        print "somefile doesn't exist\n";
    }
    
my @posiable_directories_to_search = qw( lib scripts bin );
my @directories_to_search = (); # = qw( lib scripts bin );
# p @posiable_directories_to_search;
for my $directory (@posiable_directories_to_search) {
	# p $directory;
	if ( defined -d $directory ) {
		say 'ok';
		push @directories_to_search, $directory;
	}
}
p @directories_to_search;
try {
	# find( \&requires, 'lib' );
	find( \&requires, @directories_to_search );
};

sub requires {
	return if $_ !~ /\.p[lm]$/;

	# say 'input: ' . $_;
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
				if ($ignore_base) {

					# undef(@modules);
					if ( $include->module =~ /(base|parent)/ ) {
						say 'Info: check ' . $include->pragma . ' pragma: ';
						say $include->content;

						my $content = $include->content;
						$content =~ s/^use (base|parent) //;

						$content =~ s/^qw[\<|\(|\{|\[]\n?\t?\s*//;
						$content =~ s/\s*[\>|\)|\}|\]];\n?\t?$//;
						$content =~ s/(\n\t)/, /g;

						# chomp $content;
						@modules = ();
						undef(@modules);
						@modules = split /, /, $content;

						# p @modules;
					}
				}

				foreach my $module (@modules) {

					# p $module;
					if ($ignore_base) {

						# p $module;
						next if Module::CoreList->first_release($module);
					}

					# my $module = $include->module;

					#deal with ''
					next if $module eq '';
					if ( $module =~ /^$package_name/ ) {

						# don't include our own packages here
						next;
					}
					if ( $module =~ /Mojo/ ) {
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

							# if ( $mod->cpan_version && $mod->cpan_version ne 'undef' ) {
							# say $module.' cpan mod version = undef';
							# $requires{$module} = $mod->cpan_version;
							# }
						}
					};
				}

			}
		}
	}
	push @requires, @items;
}

output( 'requires', \%requires );

# remove_children( \%requires );

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

sub test_requires {

	return if $_ !~ /\.(t|pm)$/;

	# return if $_ !~ /\.pm$/;

	# p $_;
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
				if ($ignore_base) {

					# undef(@modules);
					if ( $include->module =~ /(base|parent)/ ) {
						say 'Info: check ' . $include->pragma . ' pragma: ';
						say $include->content;

						my $content = $include->content;
						$content =~ s/^use (base|parent) //;

						$content =~ s/^qw[\<|\(|\{|\[]\n?\t?\s*//;
						$content =~ s/\s*[\>|\)|\}|\]];\n?\t?$//;
						$content =~ s/(\n\t)/, /g;

						# chomp $content;
						@modules = ();
						undef(@modules);
						@modules = split /, /, $content;

						# p @modules;
					}

				}

				foreach my $module (@modules) {

					# p $module;
					if ($ignore_base) {

						# p $module;
						next if Module::CoreList->first_release($module);
					}

					#deal with ''
					next if $module eq '';
					if ( $module =~ /^$package_name/ ) {

						# don't include our own packages here
						next;
					}
					if ( $module =~ /Mojo/ ) {
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
}

output( 'test_requires', \%test_requires );

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


print "\n";
say 'END';

exit(0);

__END__
