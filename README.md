Dusty
=====

some of my ~/bin files for prosperity


cpan_new.pl
---- 

I use this script on a new perl builds by perlbrew, gets cpan up-to speed


cpan_padre.pl
----
install padre and my favourite plug-ins

cpan_bot.pl 
----
load requirements for #padre bot


update_version_number.pl
----

updates

	our $VERSION = '0.04';

also

	=head1 VERSION

	version 0.04


__END__

=head1 NAME

MyModule - My first module

=head1 SYNOPSIS

  use MyModule;
  my $o = MyModule->new;
  ...

=head2 HEAD2

bob C<code> B<bold> I<italic> E<lt> E<copy> L<name|link/section> 

 leading space C<code>

=head1 HEAD1

=head1 Heading 1 Text

=head2 Heading 2 Text

=head3 Heading 3 Text

=head4 Heading 4 Text

=over indentlevel

=item stuff

=back

=begin format

=end format

=for format text...

=encoding type


=cut