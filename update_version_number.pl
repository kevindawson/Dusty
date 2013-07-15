#!/usr/bin/env perl

use v5.14;
use strict;
use warnings;
# turn of experimental warnings
no if $] > 5.017010, warnings => 'experimental';

our $VERSION = '0.03';
use English qw( -no_match_vars );    # Avoids regex performance penalty
local $OUTPUT_AUTOFLUSH = 1;

use feature 'unicode_strings';

BEGIN {
  $PPI::XS_DISABLE = 1;              # noise control - Prevent warning
}

use diagnostics;
use Data::Printer {caller_info => 1, colored => 1,};
use PPI;
use Try::Tiny;
say 'START';

# check if there are versions in every module and if they are in the same
# allow updating version numbers to one specific version.

use File::Find qw(find);
use File::Slurp qw(read_file write_file);

my $version = shift;
die "Usage: $0 VERSION not provided\n"
  if not $version
  or $version !~ /^\d{1,2}.\d{0,3}.*\d{0,3}$/;
print "Setting VERSION $version\n";

my @directories_to_search = qw( script lib );
find(\&xversion, @directories_to_search);

sub xversion {
  my $filename = $_;
  #say '$filename - ' . $filename;

  return if $filename eq '.';
  return if -d $filename;

  given ($filename) {
    when (m/[.]pm$/) { say 'looking for requires in (.pm)-> ' . $filename; }
    when (m/[.]\w{2,4}$/) { say 'rejecting ' . $filename; return; }
    default { return if not _is_perlfile($filename); }
  }

  my @data = read_file($_);

  if (grep { $_ =~ /^our \$VERSION\s*=\s*'\d{1,2}.\d{0,3}.*\d{0,3}';/ } @data)
  {
    my @new = map {
      $_
        =~ s/^(our \$VERSION\s*=\s*)'\d{1,2}.\d{0,3}.*\d{0,3}';/$1'$version';/;
      $_
    } @data;

    if (grep { $_ =~ /^=head1 VERSION/ } @data) {
      @new = map {
        $_
          =~ s/(?<pre>.*)(?<![->|_])(?<ver>version:)(?!\s*=>).*/$+{pre}$+{ver} $version/;
        $_
      } @data;
      say 'Just processed POD ' . $File::Find::name;
    }

    # p @new;
    write_file($_, @new);
    say 'Just processed VERSION ' . $File::Find::name;
  }
  else {
    warn "No VERSION in $File::Find::name\n";
  }

}

########
# is this a perl file
#######
sub _is_perlfile {
  my $filename = shift;

  my $ppi_tc;
  my $ppi_document;
  try {
    $ppi_document = PPI::Document->new($filename);
    $ppi_tc       = $ppi_document->find('PPI::Token::Comment');
  };

  my $not_a_pl_file = 0;

  if ($ppi_tc) {

    # check first token-comment for a she-bang
    $not_a_pl_file = 1 if $ppi_tc->[0]->content =~ m/^#!.+perl.*$/;
  }

  if ($ppi_document->find('PPI::Statement::Package') || $not_a_pl_file) {
    print "looking for requires in (package) -> "
      if $ppi_document->find('PPI::Statement::Package');
    print "looking for requires in (shebang) -> "
      if $ppi_tc->[0]->content =~ /perl/;
    say $filename ;
    return 1;
  }
  else {
    return 0;
  }

}


say 'END';

1;

__END__
