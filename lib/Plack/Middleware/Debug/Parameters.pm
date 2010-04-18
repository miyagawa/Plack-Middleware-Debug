package Plack::Middleware::Debug::Parameters;
use strict;
use warnings;
use parent qw/Plack::Middleware::Debug::Base/;
use Plack::Request;

sub run {
    my ( $self, $env, $panel ) = @_;
    return sub {
        my @sections = (qw/cookies get post session/);
        my $parameters;
        my $request = Plack::Request->new($env);

        $parameters = {
            get     => $request->query_parameters,
            cookies => $request->cookies,
            post    => $request->body_parameters,
            session => $env->{'psgix.session'},
        };
        $panel->title('Request Vars');
        $panel->nav_title('Request Vars');
        $panel->content( sub { $self->render_hash( $parameters, \@sections ) } );
    }
}

1;
__END__

=head1 NAME

Plack::Middleware::Debug::Parameters - Parameters Panel

=head1 DESCRIPTION

return info about:

=over 4

=item query parameters

=item body parameters

=item cookies

=item session

=back

=head1 SEE ALSO

L<Plack::Middleware::Debug>

=cut
