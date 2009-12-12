package Plack::Middleware::Debug::Response;
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
[% USE Dump %]
<table>
    <thead>
        <tr>
            <th>Key</th>
            <th>Value</th>
        </tr>
    </thead>
    <tbody>
        <tr class="djDebugOdd"">
            <td>Status code</td>
            <td>[% status | html %]</td>
        </tr>
        [% WHILE headers.size %]
            [% pair = headers.splice(0, 2) %]
            <tr class="[% cycle('djDebugEven' 'djDebugOdd') %]">
                <td>[% pair.0 | html %]</td>
                <td>[% Dump.dump_html(pair.1) %]</td>
            </tr>
        [% END %]
    </tbody>
</table>
EOTMPL

sub init {
    my $self = shift;
    $self->renderer(Template->new);
}
sub nav_title { 'Response' }

sub format_headers {
    my ($self, $res) = @_;
    my $headers = HTTP::Headers->new;
    my @headers = @{ $res->[1] };       # Make a copy so we can splice
    while (my ($key, $value) = splice @headers, 0, 2) {
        $headers->push_header($key, $value);
    }
    my @result =
      map { $_, scalar($headers->header($_)) } $headers->header_field_names;
    wantarray ? @result : \@result;
}

sub process_response {
    my ($self, $res) = @_;
    my $content;
    my $template = $self->TEMPLATE;
    my $vars     = {
        $self->renderer_vars,
        status  => $res->[0],
        headers => [ $self->format_headers($res) ],
    };
    $self->renderer->process(\$template, $vars, \$content)
      || die $self->renderer->error;
    $self->content($content);
}
1;
__END__

=head1 NAME

Plack::Middleware::Debug::Response - Debug panel to inspect the response

=head1 SYNOPSIS

    Plack::Middleware::Debug::Response->new;

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
