use strict;
use warnings FATAL => 'all';

use Test::Requires qw(Test::LeakTrace);
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common qw(GET);
use Test::More;

ok (
  my $app = sub {
    return [
      200, [ 'Content-Type' => 'text/html' ],
      ['<body>Hello World</body>']
    ];
  },
  'Created an application to test',
);

ok (
  $app = builder {
    enable 'Debug', panels => ['Parameters'];
    $app;
  },
  'Enabled the "Parameters" panel',
);

ok (
  my $cb = sub {
    shift->(GET '/');
  },
  'Created callback function for test_psgi',
);

no_leaks_ok (
  sub {
    for (1..5) {
      test_psgi $app, $cb;
    }
  }, 
  'No leaks in application',
);

done_testing;
