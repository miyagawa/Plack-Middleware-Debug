package Plack::Middleware::Debug::Session;
use 5.008;
use strict;
use warnings;
use parent qw(Plack::Middleware::Debug::Base);

sub run {
    my ($self, $env, $panel) = @_;

    return sub {
        my $res = shift;

        my $session = $env->{'psgix.session'}
            or return $panel->disable;

        $panel->content($self->render_hash($session));
    };
}

1;

__END__

=head1 NAME

=head1 AUTHOR

Masahiro Chiba

=head1 SEE ALSO

L<Plack::Middleware::Session>

=cut
