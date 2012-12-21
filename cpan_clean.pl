#!/usr/bin/env perl

use 5.012;
use strict;
use warnings;

use English qw( -no_match_vars ); # Avoids regex performance penalty
$OUTPUT_AUTOFLUSH = 1;
use autodie qw(:all);             # Recommended more: defaults and system/exec.


our $VERSION = '0.101';

use Data::Printer {
	caller_info => 1,
	colored     => 1,
};

use Cwd;
use File::Path;
my $pwd = cwd();
chdir "$ENV{HOME}/.cpan/build";

# keep only the latest dir
opendir my $dir_handle, '.';
# p $dir_handle;
while ( my $dir = readdir $dir_handle ) {
	
	# if not a directory next
	if ( !-d $dir ) { next; }
	
	#if child or parent next 
	if ( $dir =~ /^[.]/ ) { next; }
	
	# 9 mtime    last modify time in seconds since the epoch
	my $time_stamp = ( stat $dir )[9];

	# strip -unique
	my $cpan_module = $dir;
	$cpan_module =~ s/-\S{6}$//;

	for my $another_dir ( grep !/[.]yml/, <$cpan_module*> ) {
		if ( $another_dir eq $dir ) { next; }
		
		# 9 mtime    last modify time in seconds since the epoch
		my $another_time_stamp = ( stat $another_dir)[9];
		if ( -d $another_dir and $another_time_stamp < $time_stamp ) {
			say "rm -rf \"$another_dir*\"";
			rmtree( $another_dir );
			unlink("$another_dir.yml");
		} elsif ( -d $another_dir) {
			$time_stamp = $another_time_stamp;
		}
	}
}
closedir $dir_handle;
chdir $pwd;

