package Plack::Middleware::Debug;
use 5.008;
use strict;
use warnings;
use File::ShareDir;
use Plack::App::File;
use Plack::Util::Accessor qw(panels renderer files);
use Plack::Util;
use Template;
use Try::Tiny;
use parent qw(Plack::Middleware);
our $VERSION = '0.01';

sub TEMPLATE {
    <<'EOTMPL' }
<script type="text/javascript" charset="utf-8">
	// When jQuery is sourced, it's going to overwrite whatever might be in the
	// '$' variable, so store a reference of it in a temporary variable...
	var _$ = window.$;
	if (typeof jQuery == 'undefined') {
		var jquery_url = '[% BASE_URL %]/debug_toolbar/jquery.js';
		document.write(unescape('%3Cscript src="' + jquery_url + '" type="text/javascript"%3E%3C/script%3E'));
	}
</script>
<script type="text/javascript" src="[% BASE_URL %]/debug_toolbar/toolbar.min.js"></script>
<script type="text/javascript" charset="utf-8">
	// Now that jQuery is done loading, put the '$' variable back to what it was...
	var $ = _$;
</script>
<style type="text/css">
	@import url([% BASE_URL %]/debug_toolbar/toolbar.min.css);
</style>
<div id="djDebug">
	<div style="display:none;" id="djDebugToolbar">
		<ul id="djDebugPanelList">
			[% IF panels %]
			<li><a id="djHideToolBarButton" href="#" title="Hide Toolbar">Hide &raquo;</a></li>
			[% ELSE %]
			<li id="djDebugButton">DEBUG</li>
			[% END %]
			[% FOR panel IN panels %]
				<li>
					[% IF panel.content %]
						<a href="[% panel.url %]" title="[% panel.title %]" class="[% panel.dom_id %]">
					[% ELSE %]
					    <div class="contentless">
					[% END %]
					[% panel.nav_title %]
                    [% IF panel.nav_subtitle %]<br><small>[% panel.nav_subtitle %]</small>[% END %]
					[% IF panel.content %]
						</a>
					[% ELSE %]
					    </div>
					[% END %]
				</li>
			[% END %]
		</ul>
	</div>
	<div style="display:none;" id="djDebugToolbarHandle">
		<a title="Show Toolbar" id="djShowToolBarButton" href="#">&laquo;</a>
	</div>
	[% FOR panel IN panels %]
		[% IF panel.content %]
			<div id="[% panel.dom_id %]" class="panelContent">
				<div class="djDebugPanelTitle">
					<a href="" class="djDebugClose">Close</a>
					<h3>[% panel.title %]</h3>
				</div>
				<div class="djDebugPanelContent">
				    <div class="scroll">
				        [% panel.content %]
				    </div>
				</div>
			</div>
		[% END %]
	[% END %]
	<div id="djDebugWindow" class="panelContent"></div>
</div>
EOTMPL

sub prepare_app {
    my $self = shift;
    my $root =
      try { File::ShareDir::dist_dir('Plack-Middleware-Debug') } || 'share';
    my @panels;
    for my $package (
        @{  $self->panels
              || [qw(Environment Response Timer Memory)]
        }
      ) {
        my $panel_class = Plack::Util::load_class($package, __PACKAGE__);
        next unless $panel_class->should_run;
        push @panels, $panel_class->new;
    }
    $self->panels(\@panels);
    $self->renderer(Template->new);
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
            if ($res->[0] == 200 && $headers{'Content-Type'} eq 'text/html') {
                for my $panel (@{ $self->panels }) {
                    $panel->process_response($res, $env);
                }
                my $vars = {
                    panels   => $self->panels,
                    BASE_URL => $env->{SCRIPT_NAME},
                };
                my $content;
                my $template = $self->TEMPLATE;
                $self->renderer->process(\$template, $vars, \$content)
                  || die $self->renderer->error;
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

Plack::Middleware::Debug - display stats about the current request/response

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
C<Content-Type> of C<text/html> and is embedded in the HTML that is sent back
to the browser.

=head1 PANELS

=over 4

=item DBITrace

Display DBI trace information. See L<Plack::Middleware::Debug::DBITrace>.

=item Environment

Displays the PSGI environment from the request. See
L<Plack::Middleware::Debug::Environment>.

=item Memory

Displays memory usage before the request and after the response. See
L<Plack::Middleware::Debug::Memory>.

=item ModuleVersions

Displays the loaded modules and their versions. See
L<Plack::Middleware::Debug::ModuleVersions>.

=item PerlConfig

Displays the configuration information of the Perl interpreter itself. See
L<Plack::Middleware::Debug::PerlConfig>

=item Response

Displays the status code and response headers. See
L<Plack::Middleware::Debug::Response>.

=item Timer

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
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you. Or see L<http://search.cpan.org/dist/Plack-Middleware-Debug/>.

The development version lives at L<http://github.com/hanekomu/plack-middleware-debug/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHORS

Marcel GrE<uuml>nauer, C<< <marcel@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Marcel GrE<uuml>nauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

The debug middleware is heavily influenced (that is, adapted from) the Django
Debug Toolbar - see L<http://github.com/robhudson/django-debug-toolbar>.

=cut
