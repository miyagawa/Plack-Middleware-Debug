package Plack::Middleware::Debug::TrackObjects;
use strict;
use parent qw(Plack::Middleware::Debug::Base);

sub run {
    my($self, $env, $panel) = @_;

    unless ($INC{"Devel/TrackObjects.pm"}) {
        return $panel->disable;
    }

    return sub {
        my $res = shift;

        my $track = Devel::TrackObjects->show_tracked_detailed;
        my @content;

        foreach (@$track){
            if (length($_->[0]) > 100){
                $_->[0] = substr($_->[0],0,100);
            }
            push @content, $_->[0], $_->[1].' - '.$_->[2];
        }

        $panel->nav_subtitle('Number:'.scalar(@content)/2);

        $panel->content(
            $self->render_list_pairs([@content])
        );
    };

}

1;

__END__

=head1 NAME

Plack::Middleware::Debug::TrackObjects - Track Objects panel

=head1 SYNOPSIS

  enable "Debug";
  enable "Debug::TrackObjects";

And when you load the application with plackup or other launcher:

  # track everything
  plackup -MDevel::TrackObjects=/^/ myapp.psgi

You can specify the namespace with a regular expression. See
L<Devel::TrackObjects> for details.

=head1 DESCRIPTION

This debug panel captures objects created in a request cycle by using
L<Devel::TrackObjects>. You can run your applications multiple times
(i.e. refreshing the page) to see if the count of tracked objects
increases, in which case there are leaked objects.

=head1 SEE ALSO

L<Plack::Middleware::Debug> L<Devel::TrackObjects>

=cut
