#!/usr/bin/env perl

use v5.14;
use strict;
use warnings;
our $VERSION = '0.03';
use English qw( -no_match_vars ); # Avoids regex performance penalty
local $OUTPUT_AUTOFLUSH = 1;

use feature 'unicode_strings';

use diagnostics;
use Data::Printer {
	caller_info => 1,
	colored     => 1,
};

say 'START';

# check if there are versions in every module and if they are in the same
# allow updating version numbers to one specific version.

use File::Find qw(find);
use File::Slurp qw(read_file write_file);

my $version = shift;
die "Usage: $0 VERSION not provided\n" if not $version or $version !~ /^\d{1,2}.\d{0,3}.*\d{0,3}$/;
print "Setting VERSION $version\n";

my @directories_to_search = qw( lib scripts );
find( \&xversion, @directories_to_search );


sub xversion {
	return if $File::Find::name =~ /\.svn/;
	return if $_ !~ /\.[p[lm]|pod]/;
	my @data = read_file($_);


	if ( grep { $_ =~ /^our \$VERSION\s*=\s*'\d{1,2}.\d{0,3}.*\d{0,3}';/ } @data ) {
		my @new = map { $_ =~ s/^(our \$VERSION\s*=\s*)'\d{1,2}.\d{0,3}.*\d{0,3}';/$1'$version';/; $_ } @data;

		if ( grep { $_ =~ /^=head1 VERSION/ } @data ) {
			@new = map { $_ =~ s/(version).*/$1 $version/; $_ } @data;

			say 'Just processed POD ' . $File::Find::name;
		}

		# p @new;
		write_file( $_, @new );
		say 'Just processed VERSION ' . $File::Find::name;
	} else {
		warn "No VERSION in $File::Find::name\n";
	}
}

say 'END';

1;

__END__
