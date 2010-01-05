package Plack::Middleware::Debug::Memory;
use 5.008;
use strict;
use warnings;
use parent qw(Plack::Middleware::Debug::Base);
our $VERSION = '0.04';

sub run {
    my($self, $env, $panel) = @_;

    my $before = $self->current_memory;

    return sub {
        my $res = shift;

        my $after = $self->current_memory;
        $panel->nav_subtitle($self->format_memory($after));

        $panel->content(
            $self->render_list_pairs(
                [   Before => $self->format_memory($before),
                    After  => $self->format_memory($after),
                    Diff   => $self->format_memory($after - $before) ],
            ),
        );
    };
}

sub format_memory {
    my ($self, $memory) = @_;
    1 while $memory =~ s/^([-+]?\d+)(\d{3})/$1,$2/;
    return "$memory KB";
}

sub current_memory {
    my $self = shift;
    my $out  = `ps -o rss= -p $$`;
    $out =~ s/^\s*|\s*$//gs;
    $out;
}

sub process_response {
    my ($self, $res) = @_;
    $self->after_memory($self->current_memory);
    $self->content(
        $self->render_list_pairs(
            [   Before => $self->format_memory($self->before_memory),
                After  => $self->format_memory($self->after_memory),
                Diff   => $self->format_memory(
                    $self->after_memory - $self->before_memory
                ),
            ],
        )
    );
}
1;
__END__

=head1 NAME

Plack::Middleware::Debug::Memory - Memory Panel

=head1 SEE ALSO

L<Plack::Middleware::Debug>

=cut
