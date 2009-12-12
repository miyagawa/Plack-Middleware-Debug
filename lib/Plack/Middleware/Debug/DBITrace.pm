package Plack::Middleware::Debug::DBITrace;
use 5.008;
use strict;
use warnings;
use Template;
use Plack::Util::Accessor qw(renderer);
use parent qw(Plack::Middleware::Debug::Base);

sub TEMPLATE {
    <<'EOTMPL' }
<table>
    <thead>
        <tr>
            <th>Trace</th>
        </tr>
    </thead>
    <tbody>
            <tr class="[% cycle('djDebugEven' 'djDebugOdd') %]">
                <td><pre>[% dump | html %]</pre></td>
            </tr>
    </tbody>
</table>
EOTMPL

sub init {
    my $self = shift;
    $self->renderer(Template->new);
}
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

    my $content;
    if (defined(my $trace = $env->{'plack.debug.dbi.trace'})) {
        DBI->trace($trace); # reset
        my $dump = $env->{'plack.debug.dbi.output'};
        my $template = $self->TEMPLATE;
        my $vars     = {
            $self->renderer_vars,
            dump => $$dump,
        };
        $self->renderer->process(\$template, $vars, \$content)
            || die $self->renderer->error;
    }
    $self->content($content);
}
1;
__END__

=head1 NAME

Plack::Middleware::Debug::DBITrace - DBI trace panel

=head1 SEE ALSO

L<Plack::Middleware::Debug>

=cut
