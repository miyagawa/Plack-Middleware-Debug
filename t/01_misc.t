#!/usr/bin/env perl
use warnings;
use strict;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Test::More tests => 1;
my $app = sub {
    return [
        200, [ 'Content-Type' => 'text/html' ],
        ['<body>Hello World</body>']
    ];
};

$app = builder {
    enable 'Debug';
    $app;
};

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET '/');
    is $res->code, 200, 'response status 200';
};

done_testing;
