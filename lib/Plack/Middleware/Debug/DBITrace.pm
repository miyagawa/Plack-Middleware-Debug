package Plack::Middleware::Debug::DBITrace;
use 5.008;
use strict;
use warnings;
use parent qw(Plack::Middleware::Debug::Base);
our $VERSION = '0.01';

sub TEMPLATE {
    <<'EOTMPL' }
<table>
    <tbody>
% my $i;
% for my $line (@{$_[0]->{dump}}) {
            <tr class="<%= ++$i % 2 ? 'plDebugEven' : 'plDebugOdd' %>">
                <td><%= $line %></td>
            </tr>
% }
    </tbody>
</table>
EOTMPL
sub nav_title { 'DBI Trace' }

sub process_request {
    my ($self, $env) = @_;
    if (defined &DBI::trace) {
        $env->{'plack.debug.dbi.trace'} = DBI->trace;
        open my $fh, ">", \my $output;
        DBI->trace("1,SQL", $fh);
        $env->{'plack.debug.dbi.output'} = \$output;
    }
}

sub process_response {
    my ($self, $res, $env) = @_;
    if (defined(my $trace = $env->{'plack.debug.dbi.trace'})) {
        DBI->trace($trace);    # reset
        my $dump = $env->{'plack.debug.dbi.output'};
        $self->content(
            $self->render(
                $self->TEMPLATE, { dump => [ split /\n/ => $$dump ] }
            )
        );
    }
}
1;
__END__

=head1 NAME

Plack::Middleware::Debug::DBITrace - DBI trace panel

=head1 SEE ALSO

L<Plack::Middleware::Debug>

=cut
