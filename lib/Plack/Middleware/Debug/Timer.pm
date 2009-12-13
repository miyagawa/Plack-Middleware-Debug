package Plack::Middleware::Debug::Timer;
use 5.008;
use strict;
use warnings;
use Time::HiRes qw(gettimeofday tv_interval);
use Plack::Util::Accessor qw(start_time elapsed);
use parent qw(Plack::Middleware::Debug::Base);
our $VERSION = '0.02';
sub nav_title { 'Timer' }

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
1;
__END__

=head1 NAME

Plack::Middleware::Debug::Timer - Debug panel to time the request

=head1 SYNOPSIS

    Plack::Middleware::Debug::Timer->new;

=head1 DESCRIPTION

=head1 METHODS

=over 4

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
