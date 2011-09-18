package Plack::Middleware::Debug;
use 5.008_001;
use strict;
use warnings;
use parent qw(Plack::Middleware);
our $VERSION = '0.14';

use Encode;
use File::ShareDir;
use Plack::App::File;
use Plack::Builder;
use Plack::Util::Accessor qw(panels renderer files);
use Plack::Util;
use Plack::Middleware::Debug::Panel;
use Text::MicroTemplate;
use Try::Tiny;

sub TEMPLATE {
    <<'EOTMPL' }
% my $stash = $_[0];
<script type="text/javascript" charset="utf-8">
    // When jQuery is sourced, it's going to overwrite whatever might be in the
    // '$' variable, so store a reference of it in a temporary variable...
    var _$ = window.$;
    if (typeof jQuery == 'undefined') {
        var jquery_url = '<%= $stash->{BASE_URL} %>/debug_toolbar/jquery.js';
        document.write(unescape('%3Cscript src="' + jquery_url + '" type="text/javascript"%3E%3C/script%3E'));
    }
</script>
<script type="text/javascript" src="<%= $stash->{BASE_URL} %>/debug_toolbar/toolbar.min.js"></script>
<script type="text/javascript" charset="utf-8">
    // Now that jQuery is done loading, put the '$' variable back to what it was...
    var $ = _$;
</script>
<style type="text/css">
    @import url(<%= $stash->{BASE_URL} %>/debug_toolbar/toolbar.min.css);
</style>
<div id="plDebug">
    <div style="display:none;" id="plDebugToolbar">
        <ul id="plDebugPanelList">
% if ($stash->{panels}) {
            <li><a id="plHideToolBarButton" href="#" title="Hide Toolbar">Hide &raquo;</a></li>
% } else {
            <li id="plDebugButton">DEBUG</li>
% }
% for my $panel (reverse @{$stash->{panels}}) {
                <li>
% if ($panel->content) {
                        <a href="<%= $panel->url %>" title="<%= $panel->title %>" class="<%= $panel->dom_id %>">
% } else {
                        <div class="contentless">
% }
                    <%= $panel->nav_title %>
% if ($panel->nav_subtitle) {
                    <br><small><%= $panel->nav_subtitle %></small>
% }
% if ($panel->content) {
                    </a>
% } else {
                    </div>
% }
                </li>
% } # end for
        </ul>
    </div>
    <div style="display:none;" id="plDebugToolbarHandle">
        <a title="Show Toolbar" id="plShowToolBarButton" href="#">&laquo;</a>
    </div>
% for my $panel (reverse @{$stash->{panels}}) {
% if ($panel->content) {
            <div id="<%= $panel->dom_id %>" class="panelContent">
                <div class="plDebugPanelTitle">
                    <a href="" class="plDebugClose">Close</a>
                    <h3><%= $panel->title %></h3>
                </div>
                <div class="plDebugPanelContent">
                    <div class="scroll">
% my $content = ref $panel->content eq 'CODE' ? $panel->content->() : $panel->content;
% $content = Encode::encode('latin1', $content, Encode::FB_XMLCREF);
                        <%= Text::MicroTemplate::encoded_string($content) %>
                    </div>
                </div>
            </div>
% }
% } # end for
    <div id="plDebugWindow" class="panelContent"></div>
</div>
EOTMPL

sub default_panels {
    [qw(Environment Response Timer Memory Session DBITrace)];
}

sub prepare_app {
    my $self = shift;
    my $root = try { File::ShareDir::dist_dir('Plack-Middleware-Debug') } || 'share';

    my $builder = Plack::Builder->new;

    for my $spec (@{ $self->panels || $self->default_panels }) {
        my ($package, %args);
        if (ref $spec eq 'ARRAY') {
            # For the backward compatiblity
            # [ 'PanelName', key1 => $value1, ... ]
            $package = shift @$spec;
            $builder->add_middleware("Debug::$package", @$spec);
        } else {
            # $spec could be a code ref (middleware) or a string
            # copy so that we do not change default_panels
            my $spec_copy = $spec;
            $spec_copy = "Debug::$spec_copy" unless ref $spec_copy;
            $builder->add_middleware($spec_copy);
        }
    }

    $self->app( $builder->to_app($self->app) );

    $self->renderer(
        Text::MicroTemplate->new(
            template   => $self->TEMPLATE,
            tag_start  => '<%',
            tag_end    => '%>',
            line_start => '%',
          )->build
    );

    $self->files(Plack::App::File->new(root => $root));
}

sub call {
    my ($self, $env) = @_;
    if ($env->{PATH_INFO} =~ m!^/debug_toolbar!) {
        return $self->files->call($env);
    }

    $env->{'plack.debug.panels'} = [];

    my $res = $self->app->($env);
    $self->response_cb($res, sub {
        my $res     = shift;
        my $headers = Plack::Util::headers($res->[1]);
        my $panels = delete $env->{'plack.debug.panels'};
        if (   ! Plack::Util::status_with_no_entity_body($res->[0])
            && ($headers->get('Content-Type') || '') =~ m!^(?:text/html|application/xhtml\+xml)!) {

            my $vars = {
                panels   => [ grep !$_->disabled, @$panels ],
                BASE_URL => $env->{SCRIPT_NAME},
            };

            my $content = $self->renderer->($vars);
            return sub {
                my $chunk = shift;
                return unless defined $chunk;
                $chunk =~ s!(?=</body>)!$content!i;
                return $chunk;
            };
        }
    });
}

1;
__END__

=head1 NAME

Plack::Middleware::Debug - display information about the current request/response

=head1 SYNOPSIS

  enable "Debug";

=head1 DESCRIPTION

The debug middleware offers a configurable set of panels that displays
information about the current request and response. The information is
generated only for responses with a status of 200 (C<OK>) and a
C<Content-Type> that contains C<text/html> or C<application/xhtml+xml>
and is embedded in the HTML that is sent back to the browser. Also the
code is injected directly before the C<< </body> >> tag so if there is
no such tag, the information will not be injected.

To enable the middleware, just use L<Plack::Builder> as usual in your C<.psgi>
file:

    use Plack::Builder;

    builder {
        enable 'Debug', panels => [ qw(DBITrace Memory Timer) ];
        $app;
    };

The C<Debug> middleware takes an optional C<panels> argument whose value is
expected to be a reference to an array of panel specifications.  If given,
only those panels will be enabled. If you don't pass a C<panels>
argument, the default list of panels - C<Environment>, C<Response>,
C<Timer>, C<Memory>, C<Session> and C<DBITrace> - will be enabled, each with
their default settings, and automatically disabled if their targer modules or
middleware components are not loaded.

Each panel specification can take one of three forms:

=over 4

=item A string

This is interpreted as the base name of a panel in the
C<Plack::Middeware::Debug::> namespace. The panel class is loaded and a panel
object is created with its default settings.

=item An array reference

If you need to pass arguments to the panel object as it is created,
you may use this form (But see below).

The first element of the array reference has to be the panel base
name.  The remaining elements are key/value pairs to be passed to the
panel.

For example:

    builder {
        enable 'Debug', panels =>
          [ qw(Environment Response Timer Memory),
            [ 'DBITrace', level => 2 ]
          ];
        $app;
    };

Because each panel is a middleware component, you can write this way
as well:

    builder {
        enable 'Debug'; # load defaults
        enable 'Debug::DBITrace', level => 2;
        $app;
    };

Note that the C<<enable 'Debug'>> line should come before other Debug
panels because of the order middleware components are executed.

=item Custom middleware

You can also pass a Panel middleware component. This might be useful
if you have custom debug panels in your framework or web application.

=back

=head1 HOW TO WRITE YOUR OWN DEBUG PANEL

The C<Debug> middleware is designed to be easily extensible. You might
want to write a custom debug panel for your framework or for your web
application. Each debug panel is also a Plack middleware copmonent and
is easy to write one.

Let's look at the anatomy of the C<Timer> debug panel. Here is the code from
that panel:

  package Plack::Middleware::Debug::Timer;
  use Time::HiRes;

  use parent qw(Plack::Middleware::Debug::Base);

  sub run {
      my($self, $env, $panel) = @_;

      my $start = [ Time::HiRes::gettimeofday ];

      return sub {
          my $res = shift;

          my $end = [ Time::HiRes::gettimeofday ];
          my $elapsed = sprintf '%.6f s', Time::HiRes::tv_interval $start, $end;

          $panel->nav_subtitle($elapsed);
          $panel->content(
              $self->render_list_pairs(
                  [ Start  => $self->format_time($start),
                    End    => $self->format_time($end),
                    Elapsed => $elapsed ],
              ),
          );
      };
  }

  sub format_time { ... }

To write a new debug panel, place it in the C<Plack::Middleware::Debug::>
namespace. In our example, the C<Timer> panel lives in the
C<Plack::Middleware::Debug::Timer> package.

The only thing your panel should do is to subclass
L<Plack::Middleware::Debug::Base>. This does most of the things a
middleware component should do as a Plack middleware, so you only need
to override C<run> method to profile and create the panel content.

  sub run {
      my($self, $env, $panel) = @_;

      # Do something before the application runs

      return sub {
          my $res = shift;

          # Do something after the application returns

      };
  }

You can create as many lexical variables as you need and reference
that in the returned callback as a closure, and update the content of
of the C<$panel> which is Plack::Middleware::Debug::Panel object.

In our C<Timer> example we want to list three key/value pairs: the
start time, the end time and the elapsed time. We use the
C<render_list_pairs()> method to place the pairs in the order we
want. There is also a C<render_hash()> and C<render_lines()> method,
to render a hash keys and values, as well as just text lines (e.g. log
messages).

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN site
near you. Or see L<http://search.cpan.org/dist/Plack-Middleware-Debug/>.

The development version lives at
L<http://github.com/miyagawa/plack-middleware-debug/>. Instead of sending
patches, please fork this project using the standard git and github
infrastructure.

=head1 AUTHORS

Marcel GrE<uuml>nauer, C<< <marcel@cpan.org> >>

Tatsuhiko Miyagawa, C<< <miyagawa@bulknews.net> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Marcel GrE<uuml>nauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

The debug middleware is heavily influenced (that is, adapted from) the Django
Debug Toolbar - see L<http://github.com/robhudson/django-debug-toolbar>.

=cut
