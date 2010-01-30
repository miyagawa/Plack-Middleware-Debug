use warnings;
use strict;
use Encode;
use Plack::Test;
use Plack::Middleware::Debug;
use HTTP::Request::Common;
use Test::More;

my $app = sub {
    my $env = shift;
    $env->{'test.string'} = "\x{30c6}";
    return [
        200, [ 'Content-Type' => 'text/html' ],
        [ encode_utf8("<body><h1>\x{30c6}\x{30b9}\x{30c8}</h1></body>") ]
    ];
};

$app = Plack::Middleware::Debug->wrap($app);

test_psgi $app, sub {
    my $cb  = shift;
    my $res = $cb->(GET '/');
    is $res->code, 200, 'response status 200';
    like $res->content, qr!<h1>テスト</h1>!;
    like $res->content, qr!<td>test.string</td>\s*<td>&#x30c6;</td>!s;
};

done_testing;
