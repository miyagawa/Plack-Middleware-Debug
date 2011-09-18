package Plack::Middleware::Debug::CatalystLog;
use 5.008;
use strict;
use warnings;
use parent qw(Plack::Middleware::Debug::Base);
use Catalyst::Log;
use Class::Method::Modifiers qw(install_modifier);
our $VERSION = '0.14';

# XXX Not thread/Coro/AE safe. Should use $c->env or something
my $psgi_env;
install_modifier 'Catalyst::Log', 'around', '_log' => sub {
    my $orig = shift;
    my $self = shift;
    $psgi_env->{'plack.middleware.catalyst_log'} .= "[$_[0]] $_[1]\n";
    $self->$orig(@_);
};

sub run {
    my($self, $env, $panel) = @_;
    $psgi_env = $env;

    return sub {
        my $res = shift;

        my $log = delete $env->{'plack.middleware.catalyst_log'} || 'No Log';
        $panel->content("<pre>$log</pre>");
        $psgi_env = undef;
    };
}

1;
__END__

=head1 NAME

Plack::Middleware::Debug::Environment - Debug panel to inspect the environment

=head1 SYNOPSIS

  builder {
      enable "Debug";
      enable "Debug::CatalystLog";
      sub { MyApp->run(@_) };
  };

=head1 DESCRIPTION

This debug panel captures the logging output from Catalyst applications.

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
