package Plack::Middleware::Debug::CatalystLog;
use 5.008;
use strict;
use warnings;
use parent qw(Plack::Middleware::Debug::Base);
use Catalyst::Log;
use Hook::LexWrap;
our $VERSION = '0.02';
our $wrap    = wrap 'Catalyst::Log::_log',
  pre => sub { our $self = $_[0] },
  post => sub { our $self; our $log = $self->_body };

sub TEMPLATE {
    <<'EOTMPL' }
<table>
    <tbody>
% my $i;
% for my $line (split "\n", $_[0]->{string}) {
            <tr class="<%= ++$i % 2 ? 'plDebugEven' : 'plDebugOdd' %>">
                <td><%= $line %></td>
            </tr>
% }
    </tbody>
</table>
EOTMPL
sub nav_title { 'Catalyst Log' }

sub process_response {
    my ($self, $res, $env) = @_;
    our $log;
    return unless $log;
    $self->content($self->render($self->TEMPLATE, { string => $log }));
}
1;
__END__

=head1 NAME

Plack::Middleware::Debug::Environment - Debug panel to inspect the environment

=head1 SYNOPSIS

    Plack::Middleware::Debug::Environment->new;

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

Tatsuhiko Miyagawa, C<< <miyagawa@bulknews.net> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Marcel GrE<uuml>nauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
