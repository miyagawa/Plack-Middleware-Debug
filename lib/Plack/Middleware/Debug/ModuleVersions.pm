package Plack::Middleware::Debug::ModuleVersions;
use 5.008;
use strict;
use warnings;
use Plack::Response;
use Module::Versions;
use parent qw(Plack::Middleware::Debug::Base);
our $VERSION = '0.01';

sub TEMPLATE {
    <<'EOTMPL' }
<table>
    <thead>
        <tr>
            <th>Key</th>
            <th>Value</th>
        </tr>
    </thead>
    <tbody>
        [% FOREACH pair IN modules.pairs %]
            <tr class="[% cycle('djDebugOdd' 'djDebugEven') %]">
                <td>[% pair.key | html %]</td>
                <td>[% pair.value | html %]</td>
            </tr>
        [% END %]
    </tbody>
</table>
EOTMPL

sub nav_title    { 'Module Versions' }

sub process_request {
    my ($self, $env) = @_;
    my $content;
    my $template = $self->TEMPLATE;
    my $modules = Module::Versions->HASH;
    $_ = $_->{VERSION} for values %$modules;
    my $vars     = {
        $self->renderer_vars,
        modules   => $modules,
    };
    $self->renderer->process(\$template, $vars, \$content)
      || die $self->renderer->error;
    $self->content($content);
}
1;
__END__

=head1 NAME

Plack::Middleware::Debug::ModuleVersions - Debug panel to inspect the environment

=head1 SYNOPSIS

    Plack::Middleware::Debug::ModuleVersions->new;

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
