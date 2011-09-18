package Plack::Middleware::Debug::DBITrace;
use 5.008;
use strict;
use warnings;
use Plack::Util::Accessor qw(level);
use parent qw(Plack::Middleware::Debug::Base);
our $VERSION = '0.14';

sub prepare_app {
    my $self = shift;
    $self->level(1) unless defined $self->level;
}

sub run {
    my($self, $env, $panel) = @_;

    $panel->nav_subtitle("Level " . $self->level);

    my($old_trace, $output);
    if (defined &DBI::trace) {
        $old_trace = DBI->trace;
        open my $fh, ">", \$output;
        DBI->trace($self->level . ",SQL", $fh);
    } else {
        return $panel->disable;
    }

    return sub {
        my $res = shift;

        if (defined $old_trace) {
            DBI->trace($old_trace);
            $panel->content($self->render_lines($output));
        }
    };
}

1;
__END__

=head1 NAME

Plack::Middleware::Debug::DBITrace - DBI trace panel

=head1 SYNOPSIS

  enable "Debug";
  enable "Debug::DBITrace";

=head1 DESCRIPTION

This debug panel captures DBI trace log in a raw format. See also
L<Plack::Middleware::Debug::DBIProfile> to see the profile log, which
would be more useful.

=head1 SEE ALSO

L<Plack::Middleware::Debug::DBIProfile> L<Plack::Middleware::Debug>

=cut
