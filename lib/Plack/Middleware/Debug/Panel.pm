package Plack::Middleware::Debug::Panel;
use strict;
use warnings;
use Plack::Util::Accessor qw(dom_id url title nav_title nav_subtitle content disabled);

sub new { bless {}, shift }
sub disable { $_[0]->disabled(1); return }

1;
