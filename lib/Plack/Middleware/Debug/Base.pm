package Plack::Middleware::Debug::Base;
use 5.008;
use strict;
use warnings;
use Plack::Util::Accessor qw(content renderer);
use Text::MicroTemplate;
use Data::Dump;
our $VERSION = '0.01';

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $self;
    if (@_ == 1 && ref $_[0] eq 'HASH') {
        $self = bless { %{ $_[0] } }, $class;
    } else {
        $self = bless {@_}, $class;
    }
    $self->init;
    $self;
}
sub init             { }
sub should_run       { 1 }
sub process_request  { }
sub process_response { }

sub dom_id {
    my $self = shift;
    (my $name = ref $self) =~ s/.*:://;
    "plDebug${name}Panel";
}
sub url { '#' }

sub title {
    my $self = shift;
    (my $name = ref $self) =~ s/.*:://;
    $name =~ s/(?<=[a-z])(?=[A-Z])/ /g;
    $name;
}
sub nav_subtitle { '' }

sub vardump {
    my $scalar = shift;
    return $scalar unless ref $scalar;
    Data::Dump::dump($scalar);
}

sub renderer_vars {
    my %vars = (
        cycle => sub {
            our @cycle;
            @cycle = @_ unless @cycle;
            our $pointer;
            $pointer ||= 0;
            my $result = $cycle[$pointer];
            $pointer = ($pointer + 1) % scalar(@cycle);
            $result;
        }
    );
    wantarray ? %vars : \%vars;
}

sub render {
    my ($self, $template, $vars) = @_;
    my $mt = Text::MicroTemplate->new(
        template => $template,
        tag_start => '<%',
        tag_end => '%>',
        line_start => '%',
    )->build;
    my $out = $mt->({ $self->renderer_vars, %$vars });
    $out;
}

sub template_for_list_pairs {
    <<'EOTMPL' }
<table>
    <thead>
        <tr>
            <th>Key</th>
            <th>Value</th>
        </tr>
    </thead>
    <tbody>
% my $i;
% while (@{$_[0]->{list}}) {
% my($key, $value) = splice(@{$_[0]->{list}}, 0, 2);
            <tr class="<%= ++$i % 2 ? 'plDebugOdd' : 'plDebugEven' %>">
                <td><%= $key %></td>
                <td><%= vardump($value) %></td>
            </tr>
% }
    </tbody>
</table>
EOTMPL

sub render_list_pairs {
    my ($self, $list) = @_;
    $self->render($self->template_for_list_pairs, { list => $list });
}

sub render_hash {
    my ($self, $hash) = @_;
    $self->render($self->template_for_list_pairs, { list => [ %$hash ] });
}

1;
__END__

=head1 NAME

Plack::Middleware::Debug::Base - Base class for Debug panels

=head1 SYNOPSIS

# None. You shouldn't need to use this class yourself.

=head1 DESCRIPTION

This is the base class for panels.

=head1 METHODS

=over 4

=item C<new>

Constructs a new object and calls C<init()>.

=item C<init>

Called by C<new()>, this method is empty in this class, but can be overridden
by subclasses.

=item C<should_run>

When a panel class is loaded by L<Plack::Middleware::Debug>, its
C<should_run()> class method is called to see whether that panel wants to be
included in every request and response. For example, the panel might decide
to be run if some prerequisite module cannot be loaded.

This method defaults to C<1> in this base class.

=item C<process_request>

The debug middleware calls all enabled panels when a request has arrived. The
first and only argument of this method is the environment hash. In this base
class it is an empty method. Not every panel will need to override it; some
might only need to override C<process_response()>.

=item C<process_response>

The debug middleware calls all enabled panels when a response has arrived. The
method is called with the response array first and the environment hash
second. In this base class it is an empty method. Not every panel will need to
override it; some might only need to override C<process_request()>.

=item C<dom_id>

This is the class name used for HTML tags related to that panel. It defaults
to C<plDebugXXXPanel> where C<XXX> is the base name of the panel package. For
example, for the C<Environment> panel, it will be C<plDebugEnvironmentPanel>.

=item C<url>

This is the URL that is invoked when clicking on the panel's entry in the
toolbar. It defaults to C<#>, which means that the panel is implemented on the
same HTML page.

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

Tatsuhiko Miyagawa, C<< <miyagawa@bulknews.net> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Marcel GrE<uuml>nauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
