package Plack::Middleware::Debug::DBITrace;
use 5.008;
use strict;
use warnings;
use Plack::Util::Accessor qw(level);
use parent qw(Plack::Middleware::Debug::Base);
our $VERSION = '0.03';

my $template = __PACKAGE__->build_template(<<'EOTMPL');
<table>
    <tbody>
% my $i;
% for my $line (split "\n", $_[0]->{dump}) {
            <tr class="<%= ++$i % 2 ? 'plDebugEven' : 'plDebugOdd' %>">
                <td><%= $line %></td>
            </tr>
% }
    </tbody>
</table>
EOTMPL

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    $self->level(1) unless defined $self->level;
}

sub title     { 'DBI Trace' }
sub nav_subtitle {
    my $self = shift;
    sprintf 'Level %s', $self->level;
}

sub process_request {
    my ($self, $env) = @_;
    if (defined &DBI::trace) {
        $env->{'plack.debug.dbi.trace'} = DBI->trace;
        open my $fh, ">", \my $output;
        my $level = $self->level;
        DBI->trace("$level,SQL", $fh);
        $env->{'plack.debug.dbi.output'} = \$output;
    }
}

sub process_response {
    my ($self, $res, $env) = @_;
    if (defined(my $trace = $env->{'plack.debug.dbi.trace'})) {
        DBI->trace($trace);    # reset
        my $dump = $env->{'plack.debug.dbi.output'};
        $self->content( $self->render($template, { dump => $$dump }) );
    }
}
1;
__END__

=head1 NAME

Plack::Middleware::Debug::DBITrace - DBI trace panel

=head1 SEE ALSO

L<Plack::Middleware::Debug>

=cut
