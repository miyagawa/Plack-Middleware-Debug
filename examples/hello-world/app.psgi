use Plack::Builder;

my $app = sub {
    return [ 200, [ 'Content-Type' => 'text/html' ], [ '<body>Hello World</body>' ] ];
};

builder {
    enable 'Debug', panels => [ qw(Environment Response Timer) ];
    enable "Plack::Middleware::Static", path => qr{^/debug_toolbar/}, root => './htdocs/';
    $app;
};
