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
our $VERSION = '0.02';

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
    for my $package (
        @{ $self->panels || [qw(Environment Response Timer Memory)] }) {
        my $panel_class = Plack::Util::load_class($package, __PACKAGE__);
        next unless $panel_class->should_run;
        push @panels, $panel_class->new;
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
            my %headers = @{ $res->[1] };
            if ($res->[0] == 200
                && index($headers{'Content-Type'}, 'text/html') != -1) {
                for my $panel (reverse @{ $self->panels }) {
                    $panel->process_response($res, $env);
                }
                my $vars = {
                    panels   => $self->panels,
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
sent back to the browser.

To enable the middleware, just use L<Plack::Builder> as usual in your C<.psgi>
file:

    use Plack::Builder;

    builder {
        enable 'Debug' panels => [ qw(DBITrace PerlConfig) ];
        $app;
    };

If you pass a list of panel base names to the C<enable()> call, only those
panels will be enabled. If you don't pass an argument, the default list of
panels - C<Environment>, C<Response>, C<Timer> and C<Memory> - will be
enabled.

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

=back

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
