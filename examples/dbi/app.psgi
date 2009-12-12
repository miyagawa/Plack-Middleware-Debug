# Do this: sqlite3 examples/dbi/foo.db < examples/dbi/dump.sql

use Plack::Builder;
use File::Basename;

my $db = File::Basename::dirname(__FILE__) . "/foo.db";

my $app = sub {
    use DBI;
    my $dbh = DBI->connect("dbi:SQLite:dbname=$db", "", "");
    my $sth = $dbh->prepare("SELECT * FROM foo");
    $sth->execute;
    1 while ($sth->fetchrow_arrayref);
    return [ 200, [ 'Content-Type' => 'text/html' ], [ '<body>Hello World</body>' ] ];
};

builder {
    enable 'Debug', panels => [ qw(Environment Response Timer Memory DBITrace) ];
    $app;
};
