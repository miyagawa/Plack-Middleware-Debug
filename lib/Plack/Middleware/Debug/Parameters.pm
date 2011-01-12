package Plack::Middleware::Debug::Parameters;
use strict;
use warnings;
use Plack::Util::Accessor qw(elements);
use parent qw/Plack::Middleware::Debug::Base/;
use Plack::Request;

sub prepare_app {
    my $self = shift;
    $self->elements( [qw/headers cookies get post session/] )
        unless $self->elements;
}

sub run {
    my ( $self, $env, $panel ) = @_;
    return sub {
        my $parameters;
        my $request = Plack::Request->new($env);

        $parameters = {
            get     => $request->query_parameters,
            cookies => $request->cookies,
            post    => $request->body_parameters,
            session => $env->{'psgix.session'},
            headers => $request->headers,
        };
        $panel->title('Request Variables');
        $panel->nav_title('Request Variables');
        $panel->content($self->render_hash( $parameters, $self->elements ));
    }
}

1;
__END__

=head1 NAME

Plack::Middleware::Debug::Parameters - Parameters Panel

=head1 SYNOPSIS

    builder {
        enable 'Debug'; # load defaults
        enable 'Debug::Parameters', elements => [qw/headers cookies/];
        $app;
    };

=head1 DESCRIPTION

return info about:

=over 4

=item request headers

=item query parameters

=item body parameters

=item cookies

=item session

=back

=head1 SEE ALSO

L<Plack::Middleware::Debug>

=cut
