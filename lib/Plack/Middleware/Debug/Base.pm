package Plack::Middleware::Debug::Base;
use 5.008;
use strict;
use warnings;
use parent qw(Plack::Middleware);
use Plack::Util::Accessor qw(renderer);
use Text::MicroTemplate;
use Data::Dump;
use Scalar::Util;

our $VERSION = '0.14';

sub call {
    my($self, $env) = @_;

    my $panel = $self->default_panel;
    my $after = $self->run($env, $panel);

    $self->response_cb($self->app->($env), sub {
        my $res = shift;
        $after->($res) if $after && ref $after eq 'CODE';
        push @{$env->{'plack.debug.panels'}}, $panel;
    });
}

sub run { }

sub panel_id {
    my $self = shift;
    (my $name = ref $self) =~ s/.*:://;
    $name . Scalar::Util::refaddr($self);
}

sub panel_name {
    my $self = shift;
    (my $name = ref $self) =~ s/.*:://;
    $name =~ s/(?<=[a-z])(?=[A-Z])/ /g;
    $name;
}

sub default_panel {
    my($self, $env) = @_;

    my $id   = $self->panel_id;
    my $name = $self->panel_name;

    my $panel = Plack::Middleware::Debug::Panel->new;
    $panel->dom_id("plDebug${id}Panel");
    $panel->url('#');
    $panel->title($name);
    $panel->nav_title($name);
    $panel->nav_subtitle('');
    $panel->content('');

    $panel;
}

sub vardump {
    my $scalar = shift;
    return '(undef)' unless defined $scalar;
    return "$scalar" unless ref $scalar;
    scalar Data::Dump::dump($scalar);
}

sub build_template {
    my $class = shift;
    Text::MicroTemplate->new(
        template => $_[0],
        tag_start => '<%',
        tag_end => '%>',
        line_start => '%',
    )->build;
}

sub render {
    my ($self, $template, $vars) = @_;
    $template->($vars);
}

my $list_section_template = __PACKAGE__->build_template(<<'EOTMPL');
% foreach my $s (@{$_[0]->{sections}}) {
<h3><%= ucfirst $s %></h3>
%   if (scalar @{$_[0]->{list}->{$s}}) {
<table>
    <thead>
        <tr>
            <th>Key</th>
            <th>Value</th>
        </tr>
    </thead>
    <tbody>
% my $i;
% while (@{$_[0]->{list}->{$s}}) {
% my($key, $value) = splice(@{$_[0]->{list}->{$s}}, 0, 2);
            <tr class="<%= ++$i % 2 ? 'plDebugOdd' : 'plDebugEven' %>">
                <td><%= $key %></td>
                <td><%= vardump($value) %></td>
            </tr>
% }
    </tbody>
</table>
%   }
% }
EOTMPL

my $list_template = __PACKAGE__->build_template(<<'EOTMPL');
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

my $line_template = __PACKAGE__->build_template(<<'EOTMPL');
<table>
    <tbody>
% my $i;
% if (defined $_[0]->{lines}) {
%   my @lines = ref $_[0]->{lines} eq 'ARRAY' ? @{$_[0]->{lines}} : split /\r?\n/, $_[0]->{lines};
%   for my $line (@lines) {
            <tr class="<%= ++$i % 2 ? 'plDebugEven' : 'plDebugOdd' %>">
                <td><%= $line %></td>
            </tr>
%   }
% }
    </tbody>
</table>
EOTMPL

sub render_lines {
    my ($self, $lines) = @_;
    $self->render($line_template, { lines => $lines });
}

sub render_list_pairs {
    my ($self, $list, $sections) = @_;
    if ($sections) {
        $self->render($list_section_template, { list => $list, sections => $sections });
    }else{
        $self->render($list_template, { list => $list });
    }
}

sub render_hash {
    my ( $self, $hash, $sections ) = @_;
    if ($sections) {
        my %hash;
        foreach my $section ( keys %$hash ) {
            push @{ $hash{$section} },
                map { $_ => $hash->{$section}->{$_} }
                sort keys %{ $hash->{$section} };
        }
        $self->render( $list_section_template,
            { sections => $sections, list => \%hash } );
    }
    else {
        my @hash = map { $_ => $hash->{$_} } sort keys %$hash;
        $self->render( $list_template, { list => \@hash } );
    }
}

1;
__END__

=head1 NAME

Plack::Middleware::Debug::Base - Base class for Debug panels

=head1 SYNOPSIS

  package Plack::Middleware::Debug::YourPanel;
  use parent qw(Plack::Middleware::Debug::Base);

  sub run {
      my($self, $env, $panel) = @_;

      # Do something before the application runs

      return sub {
          my $res = shift;

          # Do something after the application returns

      };
  }

=head1 DESCRIPTION

This is the base class for panels.

=head1 METHODS

=over 4

=item C<run>

This method is called when a request has arrived, before the main
application runs. The parameters are C<$env>, the PSGI environment
hash reference and C<$panel>, a Plack::Middleware::Debug::Panel
object.

If your panel needs to do some response munging, you should return a
callback that takes C<$res> the response object. Because you can
return a closure, the response filter can also use C<$env> and
C<$panel> easily.

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

The development version lives at L<http://github.com/miyagawa/plack-middleware-debug/>.
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
