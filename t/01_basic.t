#!/usr/bin/env perl
use warnings;
use strict;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Test::More;
my @content_types = ('text/html', 'text/html; charset=utf8',);
for my $content_type (@content_types) {
    note "Content-Type: $content_type";
    my $app = sub {
        return [
            200, [ 'Content-Type' => $content_type ],
            ['<body>Hello World</body>']
        ];
    };
    $app = builder {
        enable 'Debug';
        $app;
    };
    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/');
        is $res->code, 200, 'response status 200';
        for my $panel (qw(Environment Response Timer Memory)) {
            like $res->content,
              qr/<a href="#" title="$panel" class="plDebug${panel}\d+Panel">/,
              "HTML contains $panel panel";
        }
    };
}
done_testing;
