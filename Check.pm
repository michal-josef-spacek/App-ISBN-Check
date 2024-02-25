package App::ISBN::Check;

use strict;
use warnings;

use Business::ISBN;
use Class::Utils qw(set_params);
use Error::Pure qw(err);
use Getopt::Std;
use Perl6::Slurp qw(slurp);

our $VERSION = 0.01;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Process parameters.
	set_params($self, @params);

	# Object.
	return $self;
}

# Run.
sub run {
	my $self = shift;

	# Process arguments.
	$self->{'_opts'} = {
		'h' => 0,
	};
	if (! getopts('h', $self->{'_opts'}) || @ARGV < 1
		|| $self->{'_opts'}->{'h'}) {

		print STDERR "Usage: $0 [-h] [--version] file_with_isbns\n";
		print STDERR "\t-h\t\tPrint help.\n";
		print STDERR "\t--version\tPrint version.\n";
		print STDERR "\tisbn_string\tISBN string.\n";
		return 1;
	}
	$self->{'_file'} = shift @ARGV;

	my @isbns = slurp($self->{'_file'}, { chomp => 1 });

	foreach my $isbn (@isbns) {
		my $isbn_obj = Business::ISBN->new($isbn);
		if (! $isbn_obj) {
			print $isbn.": Cannot parse.\n";
			next;
		}
		if (! $isbn_obj->is_valid) {
			$isbn_obj->fix_checksum;
		}
		if (! $isbn_obj->is_valid) {
			print $isbn.": Not valid.\n";
			next;
		}

		if ($isbn !~ m/^[\d\-xX]+$/ms) {
			print $isbn.": Some typo.\n";
			next;
		}

		my $isbn_concrete;
		my $isbn_without_dash = $isbn;
		$isbn_without_dash =~ s/-//msg;
		if (length $isbn_without_dash > 10) {
			$isbn_concrete = $isbn_obj->as_isbn13;
		} else {
			$isbn_concrete = $isbn_obj->as_isbn10;
		}
		if ($isbn ne $isbn_concrete->as_string) {
			print $isbn.": Different after format (".$isbn_concrete->as_string.").\n";
		}
	}

	return 0;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::ISBN::Check - Base class for isbn-check script.

=head1 SYNOPSIS

 use App::ISBN::Check;

 my $app = App::ISBN::Check->new;
 my $exit_code = $app->run;

=head1 METHODS

=head2 C<new>

 my $app = App::ISBN::Check->new;

Constructor.

=head2 C<run>

 my $exit_code = $app->run;

Run.

Returns 1 for error, 0 for success.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

 run():
         ISBN '%s' is bad.
         ISBN '%s' is not valid.

=head1 EXAMPLE

 use strict;
 use warnings;

 use App::ISBN::Format;

 # Arguments.
 @ARGV = (
         '9788025343364',
 );

 # Run.
 exit App::ISBN::Format->new->run;

 # Output:
 # 9788025343364 -> 978-80-253-4336-4

=head1 DEPENDENCIES

L<Business::ISBN>,
L<Class::Utils>,
L<Error::Pure>,
L<Getopt::Std>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/App-ISBN-Check>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
