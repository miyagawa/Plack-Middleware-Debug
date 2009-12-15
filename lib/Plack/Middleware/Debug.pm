package Plack::Middleware::Debug;
use 5.008;
use strict;
use warnings;
use File::ShareDir;
use Plack::App::File;
use Plack::Util::Accessor qw(panels renderer files);
use Plack::Util;
use Text::MicroTemplate;
use Try::Tiny;
use parent qw(Plack::Middleware);
our $VERSION = '0.03';

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
% for my $panel (@{$stash->{panels}}) {
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
% for my $panel (@{$stash->{panels}}) {
% if ($panel->content) {
            <div id="<%= $panel->dom_id %>" class="panelContent">
                <div class="plDebugPanelTitle">
                    <a href="" class="plDebugClose">Close</a>
                    <h3><%= $panel->title %></h3>
                </div>
                <div class="plDebugPanelContent">
                    <div class="scroll">
                        <%= Text::MicroTemplate::encoded_string($panel->content) %>
                    </div>
                </div>
            </div>
% }
% } # end for
    <div id="plDebugWindow" class="panelContent"></div>
</div>
EOTMPL

sub prepare_app {
    my $self = shift;
    my $root =
      try { File::ShareDir::dist_dir('Plack-Middleware-Debug') } || 'share';
    my @panels;
    for my $spec (@{ $self->panels || [qw(Environment Response Timer Memory)] })
    {
        my ($package, %args);
        if (ref $spec eq 'ARRAY') {

            # [ 'PanelName', key1 => $value1, ... ]
            $package = shift @$spec;
            %args    = @$spec;
            my $panel_class = Plack::Util::load_class($package, __PACKAGE__);
            next unless $panel_class->should_run;
            push @panels, $panel_class->new(%args);
        } elsif (ref $spec) {

            # accept a panel object
            push @panels, $spec;
        } else {

            # not a ref, just a panel basename string
            my $panel_class = Plack::Util::load_class($spec, __PACKAGE__);
            next unless $panel_class->should_run;
            push @panels, $panel_class->new;
        }
    }
    $self->panels(\@panels);
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
    for my $panel (@{ $self->panels }) {
        $panel->process_request($env);
    }
    my $res = $self->app->($env);
    $self->response_cb(
        $res,
        sub {
            my $res     = shift;
            my $headers = Plack::Util::headers($res->[1]);
            if (   $res->[0] == 200
                && $headers->get('Content-Type') =~ m!^text/html!) {
                for my $panel (reverse @{ $self->panels }) {
                    $panel->process_response($res, $env);
                }
                my $vars = {
                    panels   => $self->panels,
                    BASE_URL => $env->{SCRIPT_NAME},
                };
                my $content = $self->renderer->($vars);
                if (my $cl = $headers->get('Content-Length')) {
                    $headers->set('Content-Length' => $cl + length $content);
                }
                return sub {
                    my $chunk = shift;
                    return unless defined $chunk;
                    $chunk =~ s!(?=</body>)!$content!i;
                    return $chunk;
                };
            }
            $res;
        }
    );
}
1;
__END__

=head1 NAME

Plack::Middleware::Debug - display information about the current request/response

=head1 SYNOPSIS

    # app.psgi

    use Plack::Builder;

    my $app = sub {
        return [ 200, [ 'Content-Type' => 'text/html' ],
               [ '<body>Hello World</body>' ] ];
    };

    builder {
        enable 'Debug';
        $app;
    };


=head1 DESCRIPTION

The debug middleware offers a configurable set of panels that displays
information about the current request and response. The information is
generated only for responses with a status of 200 (C<OK>) and a
C<Content-Type> that contains C<text/html> and is embedded in the HTML that is
sent back to the browser. Also the code is injected directly before the C<<
</body> >> tag so if there is no such tag, the information will not be
injected.

To enable the middleware, just use L<Plack::Builder> as usual in your C<.psgi>
file:

    use Plack::Builder;

    builder {
        enable 'Debug', panels => [ qw(DBITrace PerlConfig) ];
        $app;
    };

The C<Debug> middleware takes an optional C<panels> argument whose value is
expected to be a reference to an array of panel specifications.  If given,
only those panels will be enabled. If you don't pass a C<panels>
argument, the default list of panels - C<Environment>, C<Response>,
C<Timer> and C<Memory> - will be enabled, each with their default settings.

Each panel specification can take one of three forms:

=over 4

=item A string

This is interpreted as the base name of a panel in the
C<Plack::Middeware::Debug::> namespace. The panel class is loaded and a panel
object is created with its default settings.

=item An array reference

If you need to pass arguments to the panel object as it is created, use this
form. The first element of the array reference has to be the panel base name.
The remaining elements are key/value pairs to be passed to the panel.

Not all panels take extra arguments. But the C<DBITrace> panel, for example,
takes an optional C<level> argument to specify the desired trace level.

For example:

    builder {
        enable 'Debug', panels =>
          [ qw(Environment Response Timer Memory),
            [ 'DBITrace', level => 2 ]
          ];
        $app;
    };

=item An object

You can also pass panel objects directly to the C<Debug> middleware. This
might be useful if you have custom debug panels in your framework or web
application.

=back

=head1 PANELS

=over 4

=item C<DBITrace>

Display DBI trace information. See L<Plack::Middleware::Debug::DBITrace>.

=item C<Environment>

Displays the PSGI environment from the request. See
L<Plack::Middleware::Debug::Environment>.

=item C<Memory>

Displays memory usage before the request and after the response. See
L<Plack::Middleware::Debug::Memory>.

=item C<ModuleVersions>

Displays the loaded modules and their versions. See
L<Plack::Middleware::Debug::ModuleVersions>.

=item C<PerlConfig>

Displays the configuration information of the Perl interpreter itself. See
L<Plack::Middleware::Debug::PerlConfig>

=item C<Response>

Displays the status code and response headers. See
L<Plack::Middleware::Debug::Response>.

=item C<Timer>

Displays how long the request took. See L<Plack::Middleware::Debug::Timer>.

=item C<CatalystLog>

In a Catalyst application, this panel displays the Catalyst log output. See
L<Plack::Middleware::Debug::CatalystLog>.

=back

=head1 HOW TO WRITE YOUR OWN DEBUG PANEL

The C<Debug> middleware is designed to be easily extensible. You might want to
write a custom debug panel for your framework or for your web application.
Let's look at the anatomy of the C<Timer> debug panel. Here is the code from
that panel:

    package Plack::Middleware::Debug::Timer;
    use 5.008;
    use strict;
    use warnings;
    use Time::HiRes qw(gettimeofday tv_interval);
    use Plack::Util::Accessor qw(start_time elapsed);
    use parent qw(Plack::Middleware::Debug::Base);
    our $VERSION = '0.03';

    sub nav_subtitle {
        my $self = shift;
        $self->format_elapsed;
    }

    sub format_elapsed {
        my $self = shift;
        sprintf '%s s', $self->elapsed;
    }

    sub format_time {
        my ($self, $time) = @_;
        my ($sec, $min, $hour, $mday, $mon, $year) = (localtime($time->[0]));
        sprintf "%04d.%02d.%02d %02d:%02d:%02d.%d", $year + 1900, $mon + 1, $mday,
          $hour, $min, $sec, $time->[1];
    }

    sub process_request {
        my ($self, $env) = @_;
        $self->start_time([gettimeofday]);
    }

    sub process_response {
        my ($self, $res, $env) = @_;
        my $end_time = [gettimeofday];
        $self->elapsed(tv_interval $self->start_time, $end_time);
        $self->content(
            $self->render_list_pairs(
                [   Start   => $self->format_time($self->start_time),
                    End     => $self->format_time($end_time),
                    Elapsed => $self->format_elapsed,
                ]
            )
        );
    }

To write a new debug panel, place it in the C<Plack::Middleware::Debug::>
namespace. In our example, the C<Timer> panel lives in the
C<Plack::Middleware::Debug::Timer> package.

A panel should subclass L<Plack::Middleware::Debug::Base>. It provides a lot
of methods that the C<Debug> middleware expects a panel to have and provides
some sensible defaults for others, so you only need to override what is
specific to your custom panel.

The panels' title - which appears at the top left when the panel is active -
and its navigation title - which appears in the navigation bar on the right
side - are set automatically from the panel's base name - C<Timer> in our
case. This is a useful for default for us, so we don't need to override these
methods.

The panels' navigation subtitle, which appears in the navigation bar
underneath the panel title in smaller letters, is empty by default. For the
C<Timer> panel, we would like to show the total time elapsed so the user can
get the quick overview without having to activate the panel. So we override
the C<nav_subtitle()> method.

How do we know how much time elapsed for the request? We have to take the time
when the request comes in, and again when the response goes out. So we
override the C<process_request()> and C<process_response()> methods. In
C<process_request()> we just store the current time. To generate the accessors
for any attributes our panel might need we use L<Plack::Util::Accessor>.

In C<process_response()> we take the time again, determine how much time has
elapsed, store that information in an accessor so C<sub_navtitle()> can return
it when asked by the template, then we actually render the template with our
data and store it in C<content()>.

When the HTML, CSS and JavaScript are generated and injected by the C<Debug>
middleware, it will ask all panels whether they have any content. If so, the
actual panel is generated. If not, then just an inactive navigation bar entry
is generated.  Having data in the panel's C<content> attribute is the sign
that the C<Debug> middleware looks for.

In our C<Timer> example we want to list three key/value pairs: the start time,
the end time and the elapsed time. We use the C<render_list_pairs()> method
to place the pairs in the order we want. There is also a C<render_hash()>
method, but it would sort the hash keys, and this is not what we want.

With this our C<Timer> debug panel is finished. Now we can use it in the
C<enable 'Debug'> call like any other debug panel.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN site
near you. Or see L<http://search.cpan.org/dist/Plack-Middleware-Debug/>.

The development version lives at
L<http://github.com/hanekomu/plack-middleware-debug/>. Instead of sending
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
