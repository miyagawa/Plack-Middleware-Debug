package Plack::Middleware::Debug::Timer;
use 5.008;
use strict;
use warnings;
use Plack::Response;
use Template;
use Time::HiRes qw(gettimeofday tv_interval);
use Plack::Util::Accessor qw(renderer start_time elapsed);
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
        [% WHILE headers.size %]
            [% pair = headers.splice(0, 2) %]
            <tr class="[% cycle('djDebugEven' 'djDebugOdd') %]">
                <td>[% pair.0 | html %]</td>
                <td>[% pair.1 | html %]</td>
            </tr>
        [% END %]
    </tbody>
</table>
EOTMPL

sub init {
    my $self = shift;
    $self->renderer(Template->new);
}
sub nav_title { 'Timer' }

sub nav_subtitle {
    my $self = shift;
    $self->elapsed;
}

sub format_time {
    my ($self, $time) = @_;
    sprintf '%s.%s', @$time;
}

sub process_request {
    my ($self, $env) = @_;
    $self->start_time([gettimeofday]);
}

sub process_response {
    my ($self, $res) = @_;
    my $end_time = [gettimeofday];
    $self->elapsed(tv_interval $self->start_time, $end_time);
    my $content;
    my $template = $self->TEMPLATE;
    my $vars     = {
        $self->renderer_vars,
        headers => [
            Start   => $self->format_time($self->start_time),
            End     => $self->format_time($end_time),
            Elapsed => $self->elapsed
        ],
    };
    $self->renderer->process(\$template, $vars, \$content)
      || die $self->renderer->error;
    $self->content($content);
}
1;
__END__

=head1 NAME

Plack::Middleware::Debug::Timer - Debug panel to time the request

=head1 SYNOPSIS

    Plack::Middleware::Debug::Timer->new;

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
