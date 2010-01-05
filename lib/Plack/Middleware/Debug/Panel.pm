package Plack::Middleware::Debug::Panel;
use strict;
use warnings;
use Plack::Util::Accessor qw(dom_id url title nav_title nav_subtitle content);

sub new { bless {}, shift }

1;
