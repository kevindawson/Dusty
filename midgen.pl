#!/usr/bin/env perl

use 5.010001;
use strict;
use warnings;

our $VERSION = '0.05';
use English qw( -no_match_vars ); # Avoids regex performance penalty
local $OUTPUT_AUTOFLUSH = 1;

use Try::Tiny;
use autodie;
use Data::Printer {
	caller_info => 1,
	colored     => 1,
};

use PPI;
use Module::CoreList;
use CPAN;

use constant {
	BLANK => qq{ },
	NONE  => q{},
};

# use Carp::Always::Color;

#######
# menu system

use File::Spec;
use File::Find qw(find);
use File::Slurp qw(read_file write_file);
my @requires      = ();
my %requires      = ();
my %test_requires = ();
my @package_names;
my $package_name;

my @posiable_directories_to_search = ();
my @directories_to_search          = ();


use Getopt::Long;
Getopt::Long::Configure('bundling');
use Pod::Usage;
my $help           = 0;
my $base_parent    = 0;    # 1 true ignore perl base functions
my $core           = 0;    # show perl core modules as well
my $verbose        = 0;    # option variable with default value (false)
my @output         = 'dsl';
my $mojo           = 0;    # 1 true ignore Mojo detection
my $noisy_children = 0;    # unwanted noisy children
my $debug          = 0;    # lots of good stuff here :)
GetOptions(
	'verbose|v'        => \$verbose,
	'core|c'           => \$core,
	'base|parent|b|p'  => \$base_parent,
	'help|h|?'         => \$help,
	'mojo|m'           => \$mojo,
	'output|o=s'       => \@output,
	'noisy_children|n' => \$noisy_children,
	'debug|d' => sub { $core = 1; $verbose = 1; $base_parent = 1; $mojo = 1; $noisy_children = 1; $debug = 1; },
) or pod2usage(2);
pod2usage(1) if $help;

p @output if $debug;

sub output_format {
	my $format = { dsl => 1, mi => 1, build => 1, };
	try {
		if ( $format->{ $output[-1] } ) {
			return $output[-1];
		} else {
			return 'dsl';
		}
	};
}

my $format = output_format();
p $format if $debug;

# set up cpan bit's as well as being upto date
CPAN::HandleConfig->load;
CPAN::Shell::setup_output;
CPAN::Index->reload;


# End of Menu
#######

say 'START';

use Cwd;
my $cwd = cwd();

# Find Package name,
try {
	find( \&first_package_name, File::Spec->catfile( $cwd, 'lib' ) );
};
p @package_names if $debug;
$package_name = $package_names[0];
say 'Package: ' . $package_names[0] if $verbose;
output_top($package_name);


# Find required modules
@posiable_directories_to_search = map { File::Spec->catfile( $cwd, $_ ) } qw( lib script );
@directories_to_search = ();

p @posiable_directories_to_search if $debug;
for my $directory (@posiable_directories_to_search) {
	if ( defined -d $directory ) {
		push @directories_to_search, $directory;
	}
}

try {
	find( \&requires, @directories_to_search );
};
p %requires if $debug;
remove_children( \%requires ) if ( !$verbose );

output_requires( 'requires', \%requires );

print "\n";


# Find test_required modules
@posiable_directories_to_search = File::Spec->catfile( $cwd, 't' );
@directories_to_search = ();
for my $directory (@posiable_directories_to_search) {
	if ( defined -d $directory ) {
		push @directories_to_search, $directory;
	}
}

try {
	find( \&test_requires, @directories_to_search );
};

output_requires( 'test_requires', \%test_requires );
output_bottom();

print "\n";
say 'END';

#
# Composed methods follow
##########################

sub first_package_name {
	my $self = shift;
	return if $_ !~ /[.]pm$/sxm;

	my @items = ();

	# Load a Document from a file
	my $document = PPI::Document->new($_);
	my $ppi_sp   = $document->find('PPI::Statement::Package');

	push @package_names, $ppi_sp->[0]->namespace;
	return;
}


sub requires {
	# return if $_ !~ /[.]p[lm]$/sxm;

	# if ($verbose) {
		# say 'looking for requires in: ' . $_;
	# }
	# my @items = ();

	# Load a Document from a file
	my $document = PPI::Document->new($_);
	return unless ( defined $document->find('PPI::Statement::Package') || $document->find('PPI::Token::Comment') =~ /perl/ );
	
	if ($verbose) {
		say 'looking for requires in: ' . $_;
	}
	my @items = ();	
	
	
	my $includes = $document->find('PPI::Statement::Include');

	# p $includes if $debug;

	if ($includes) {
		foreach my $include ( @{$includes} ) {
			p $include if $debug;
			next if $include->type eq 'no';

			my @modules = $include->module;
			p @modules if $debug;
			if ( !$base_parent ) {
				my @base_parent_modules = base_parent( $include->module, $include->content, $include->pragma );
				if (@base_parent_modules) {
					@modules = @base_parent_modules;
				}
			}

			foreach my $module (@modules) {
				p $module if $debug;

				if ( !$core ) {
					p $module if $debug;

					# hash with core modules to process regardless
					my $ignore_core = { 'File::Path' => 1, };
					if ( !$ignore_core->{$module} ) {
						next if Module::CoreList->first_release($module);
					}
				}

				#deal with ''
				next if $module eq NONE;
				if ( $module =~ /^$package_name/sxm ) {

					# don't include our own packages here
					next;
				}
				if ( $module =~ /Mojo/sxm && !$mojo ) {
					$module = 'Mojolicious';
				}
				if ( $module =~ /^Padre/sxm && $module !~ /^Padre::Plugin::/sxm ) {

					# mark all Padre core as just Padre, for plugins
					push @items, 'Padre';
					$module = 'Padre';
				} else {
					push @items, $module;
				}

				my $mod;
				my $mod_in_cpan = 0;
				try {
					$mod = CPAN::Shell->expand( 'Module', $module );

					if ( $mod->cpan_version ne 'undef' ) {

						# alociate current cpan version against module name
						# $requires{$module} = $mod->cpan_version;
						$mod_in_cpan = 1;
					}
				}
				catch {
					say 'caught ' . $module if $debug;
					$requires{$module} = 0;
				}
				finally {
					if ($mod_in_cpan) {

						# alociate current cpan version against module name
						$requires{$module} = $mod->cpan_version;
					}
				};
			}
		}
	}
	push @requires, @items;
	p @requires if $debug;
	return;
}


sub test_requires {

	return if $_ !~ /[.]t|pm$/sxm;

	if ($verbose) {
		say 'looking for test_requires in: ' . $_;
	}
	my @items = ();

	# Load a Document from a file
	my $document = PPI::Document->new($_);
	my $includes = $document->find('PPI::Statement::Include');

	if ($includes) {
		foreach my $include ( @{$includes} ) {
			next if $include->type eq 'no';

			my @modules = $include->module;
			if ( !$base_parent ) {
				my @base_parent_modules = base_parent( $include->module, $include->content, $include->pragma );
				if (@base_parent_modules) {
					@modules = @base_parent_modules;
				}
			}

			foreach my $module (@modules) {
				if ( !$core ) {

					p $module if $debug;

					# hash with core modules to process regardless
					# don't ignore Test::More so as to get done_testing mst++
					my $ignore_core = { 'Test::More' => 1, };
					if ( !$ignore_core->{$module} ) {
						next if Module::CoreList->first_release($module);
					}
				}

				#deal with ''
				next if $module eq NONE;
				if ( $module =~ /^$package_name/sxm ) {

					# don't include our own packages here
					next;
				}
				if ( $module =~ /Mojo/sxm && !$mojo ) {
					$module = 'Mojolicious';
				}
				if ( $module =~ /^Padre/sxm && $module !~ /^Padre::Plugin::/sxm ) {

					# mark all Padre core as just Padre, for plugins
					push @items, 'Padre';
					$module = 'Padre';
				} else {
					push @items, $module;
				}

				try {
					my $mod = CPAN::Shell->expand( 'Module', $module );
					if ($mod) {

						# next if not defined $mod;
						if ( $mod->cpan_version && !$requires{$module} ) {
							$test_requires{$module} = $mod->cpan_version;
						}
					} else {
						$module =~ s/^(\S+)::\S+/$1/;
						$mod = CPAN::Shell->expand( 'Module', $module );
						p $mod if $debug;

						if ( $mod->cpan_version && !$requires{$module} ) {
							$test_requires{$module} = $mod->cpan_version;

						}
					}
				};
			}
		}
	}
	return;
}


sub base_parent {
	my $module  = shift;
	my $content = shift;
	my $pragma  = shift;
	my @modules = ();
	if ( $module =~ /base|parent/sxm ) {

		if ($verbose) {
			say 'Info: check ' . $pragma . ' pragma: ';
			say $content;
		}

		$content =~ s/^use (base|parent) //;

		$content =~ s/^qw[\<|\(|\{|\[]\n?\t?\s*//;
		$content =~ s/\s*[\>|\)|\}|\]];\n?\t?$//;
		$content =~ s/(\n\t)/, /g;

		@modules = split /, /, $content;
		push @modules, $module;
		p @modules if $debug;
	}
	return @modules;
}


sub output_top {
	my $package = shift || return;

	# Let's get the Module::Install::DSL current version
	my $mod = CPAN::Shell->expand( 'Module', 'inc::Module::Install::DSL' );

	given ($format) {

		# when ('mi') {
		# }
		when ('dsl') {
			print "\n";
			say 'use inc::Module::Install::DSL ' . $mod->cpan_version . ';';
			print "\n";
			say 'all_from lib/' . $package . '.pm';
			say 'requires_from lib/' . $package . '.pm';
		}

		# when ('build') {
		# }
	}
	return;
}


sub output_requires {
	my $title        = shift || 'title missing';
	my $required_ref = shift || return;

	print "\n";

	my $pm_length = 0;
	foreach my $module_name ( sort keys %{$required_ref} ) {
		if ( length $module_name > $pm_length ) {
			$pm_length = length $module_name;
		}
	}

	say $title . ' => {' if $format eq 'build';

	foreach my $module_name ( sort keys %{$required_ref} ) {
		given ($format) {
			when ('mi') {
				if ( $module_name =~ /^Win32/sxm ) {
					my $sq_key = "'$module_name'";
					printf "%s %-*s => '%s' if win32;\n", $title, $pm_length + 2, $sq_key,
						$required_ref->{$module_name};
				} else {
					my $sq_key = "'$module_name'";
					printf "%s %-*s => '%s';\n", $title, $pm_length + 2, $sq_key, $required_ref->{$module_name};
				}
			}
			when ('dsl') {
				if ( $module_name =~ /^Win32/sxm ) {
					printf "%s %-*s %s if win32\n", $title, $pm_length, $module_name, $required_ref->{$module_name};
				} else {
					printf "%s %-*s %s\n", $title, $pm_length, $module_name, $required_ref->{$module_name};
				}
			}
			when ('build') {
				my $sq_key = "'$module_name'";
				printf "\t %-*s => '%s',\n", $pm_length + 2, $sq_key, $required_ref->{$module_name};
			}
		}
	}
	say '},' if $format eq 'build';
	return;
}


sub output_bottom {

	given ($format) {

		# when ('mi') {

		# }
		when ('dsl') {
			if ($verbose) {
				print "\n";
				say '#ToDo you should consider completing the following';
				say "homepage\t...";
				say "bugtracker\t...";
				say "repository\t...";
			}
			print "\n";
			if ( defined -d './share' ) {
				say 'install_share';
				print "\n";
			}
			say 'no_index directory  qw{ t xt eg share inc privinc }';
		}

		# when ('build') {

		# }
	}
	return;
}


sub remove_children {
	my $required_ref = shift || return;
	my @sorted_modules;
	foreach my $module_name ( sort keys %{$required_ref} ) {
		push @sorted_modules, $module_name;
	}

	p @sorted_modules if $debug;

	my $n = 0;
	while ( $sorted_modules[$n] ) {

		my $parent_name  = $sorted_modules[$n];
		my @p_score      = split /::/, $parent_name;
		my $parent_score = @p_score;

		my $child_score;
		if ( ( $n + 1 ) <= $#sorted_modules ) {
			$n++;

			# Use of implicit split to @_ is deprecated
			my $child_name = $sorted_modules[$n];
			$child_score = @{ [ split /::/, $child_name ] };
		}

		if ( $sorted_modules[$n] =~ /^$sorted_modules[$n-1]::/ ) {

			# Checking for one degree of seperation ie A::B -> A::B::C is ok but A::B::C::D is not
			if ( ( $parent_score + 1 ) == $child_score ) {

				# Test for same version number
				if ( $required_ref->{ $sorted_modules[ $n - 1 ] } eq $required_ref->{ $sorted_modules[$n] } ) {
					say 'delete miscreant noisy children '
						. $sorted_modules[$n] . ' ver '
						. $required_ref->{ $sorted_modules[$n] }
						if $noisy_children;
					try {
						delete $required_ref->{ $sorted_modules[$n] };
						splice( @sorted_modules, $n, 1 );
						$n--;
					};
					p @sorted_modules if $debug;
				}
			}
		}
		$n++ if ( $n == $#sorted_modules );
	}
	return;
}


exit(0);

__END__

=pod

=encoding utf8

=head1 NAME

midgen.pl - generate the requires and test requires for Makefile.PL using Module::Install::DSL

=head1 SYNOPSIS

midgen.pl [options]

 Options:
   -help	brief help message
   -output	change format
   -core	show perl core modules
   -verbose	take a little peek as to what is going on
   -base	Don't check for base includes
   -mojo	Don't be Mojo friendly	
   -debug	lots of stuff

=head1 OPTIONS

=over 4

=item B<--help or -h>

Print a brief help message and exits.

=item B<--output or -o>

By default we do 'dsl' -> Module::Include::DSL

 midgen.pl -o dsl	# Module::Include::DSL
 midgen.pl -o mi	# Module::Include
 midgen.pl -o build	# Build.PL


=item B<-core or -c>

 * Shows modules that are in Perl core
 * some modules have a version number eg; constant, Carp
 * some have a version of 0 eg; strict, English 

=item B<--verbose or -v>

Show file that are being checked

also show contents of base|parent check

=item B<--parent or -p>

alternative  --base or -b

Turn Off - try to include the contents of base|parent modules as well

=item B<--mojo or -m>

Turn Off - the /Mojo/ to Mojolicious catch

=item B<--noisy_children or -n>

 * Show a required modules noisy children, as we find them

=item B<--debug or -d>

equivalent of -cv and some :)

=back
 
=head1 DESCRIPTION

This started out as a way of generating the core for a Module::Install::DSL Makefile.PL, why DSL because it's nice and clean, so now I can generate the contents when I want, rather than as I add new use and require statments, and because adam kicked me :)

Change to root of package and run

 midgen.pl

Now with a GetOps --help or -?

 midgen.pl -?

=head1 AUTHORS

Kevin Dawson E<lt>bowtie@cpan.orgE<gt>

=head2 CONTRIBUTORS

none at present

=head1 COPYRIGHT

Copyright E<copy> 2012-2013 AUTHORS and CONTRIBUTORS as listed above.

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=head1 SEE ALSO

L<Perl::PrereqScanner>,

=cut

