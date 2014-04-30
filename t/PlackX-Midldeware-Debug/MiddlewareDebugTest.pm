package MiddlewareDebugTest;
use 5.008;
use strict;
use warnings;
use parent qw(Plack::Middleware::Debug::Base);

sub run {
    my ($self, $env, $panel) = @_;

    return sub {
        my $res = shift;

        $panel->content( "Hello, world!" );
    };
}

1;
