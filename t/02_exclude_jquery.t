#!/usr/bin/env perl
use warnings;
use strict;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Test::More;
use lib "t/PlackX-Midldeware-Debug";

my $app = sub {
    return [
        200, [ 'Content-Type' => 'text/html' ],
        ['<body>Hello World</body>']
    ];
};

# Default has jQuery
test_psgi builder {
    enable 'Debug';
    $app;
}, \&has_jquery;

# jQuery excluded
test_psgi builder {
    enable 'Debug', exclude_jquery => 1;
    $app;
}, \&no_jquery;

# jQuery implicitly included
test_psgi builder {
    enable 'Debug', exclude_jquery => 0;
    $app;
}, \&has_jquery;

sub has_jquery {
    my $cb  = shift;
    my $res = $cb->(GET '/');
    is $res->code, 200, 'response status 200';
    like $res->content, qr/jquery\.js/, "HTML includes jQuery";
}

sub no_jquery {
    my $cb  = shift;
    my $res = $cb->(GET '/');
    is $res->code, 200, 'response status 200';
    unlike $res->content, qr/jquery\.js/, "HTML excludes jQuery";
}

done_testing;
