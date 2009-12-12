package Plack::Middleware::Debug::Base;
use 5.008;
use strict;
use warnings;
use Plack::Util::Accessor qw(content);
our $VERSION = '0.01';

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $self;
    if (@_ == 1 && ref $_[0] eq 'HASH') {
        $self = bless { %{ $_[0] } }, $class;
    } else {
        $self = bless {@_}, $class;
    }
    $self->init;
    $self;
}
sub init             { }
sub should_run       { 1 }
sub process_request  { }
sub process_response { }

sub dom_id {
    my $self = shift;
    (my $name = ref $self) =~ s/.*:://;
    "djDebug${name}Panel";
}
sub url { '#' }

sub title {
    my $self = shift;
    (my $name = ref $self) =~ s/.*:://;
    $name =~ s/(?<=[a-z])(?=[A-Z])/ /g;
    $name;
}
sub nav_subtitle { '' }

sub renderer_vars {
    my %vars = (
        cycle => sub {
            our @cycle;
            @cycle = @_ unless @cycle;
            our $pointer;
            $pointer ||= 0;
            my $result = $cycle[$pointer];
            $pointer = ($pointer + 1) % scalar(@cycle);
            $result;
        }
    );
    wantarray ? %vars : \%vars;
}
1;
__END__

=head1 NAME

Plack::Middleware::Debug::Base - Base class for Debug panels

=head1 SYNOPSIS

    Plack::Middleware::Debug::Base->new;

=head1 DESCRIPTION

=head1 METHODS

=over 4

=back

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you. Or see L<http://search.cpan.org/dist/Plack-Middleware-Debug/>.

The development version lives at L<http://github.com/hanekomu/plack-middleware-debug/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHORS

Marcel GrE<uuml>nauer, C<< <marcel@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Marcel GrE<uuml>nauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
