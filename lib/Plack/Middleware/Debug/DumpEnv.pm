package Plack::Middleware::Debug::DumpEnv;
use 5.008;
use strict;
use warnings;
use Plack::Response;
use Template;
use Plack::Util::Accessor qw(renderer);
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
        [% FOREACH pair IN env.pairs %]
            <tr class="[% cycle('djDebugOdd' 'djDebugEven') %]">
                <td>[% pair.key %]</td>
                <td>[% pair.value %]</td>
            </tr>
        [% END %]
    </tbody>
</table>
EOTMPL

sub init {
    my $self = shift;
    $self->renderer(Template->new);
}
sub nav_title    { 'Env' }
sub nav_subtitle { 'environment dumper' }

sub process_request {
    my ($self, $env) = @_;
    my $content;
    my $template = $self->TEMPLATE;
    $self->renderer->process(\$template, { env => $env }, \$content)
      || die $self->renderer->error;
    $self->content($content);
}
1;
__END__

=head1 NAME

Plack::Middleware::Debug::DumpEnv - Debug panel to dump the environment

=head1 SYNOPSIS

    Plack::Middleware::Debug::DumpEnv->new;

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
