package Plack::Middleware::Debug::Timer;
use 5.008;
use strict;
use warnings;
use Time::HiRes;

use parent qw(Plack::Middleware::Debug::Base);
our $VERSION = '0.14';

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

sub format_time {
    my ($self, $time) = @_;
    my ($sec, $min, $hour, $mday, $mon, $year) = (localtime($time->[0]));
    sprintf "%04d.%02d.%02d %02d:%02d:%02d.%d", $year + 1900, $mon + 1, $mday,
      $hour, $min, $sec, $time->[1];
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
