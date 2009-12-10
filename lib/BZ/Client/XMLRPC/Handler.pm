#
# BZ::Client::XMLRPC::Handler - Abstract event handler for parsing an XML-RPC response.
#
package BZ::Client::XMLRPC::Handler;

use strict;
use warnings "all";

our $VERSION = 1.0;

sub new ($%) {
    my $class = shift;
    my $self = { @_ };
    $self->{'level'} = 0;
    bless($self, ref($class) || $class);
    return $self;
}

sub init($$) {
    my($self,$parser) = @_;
    $self->parser($parser);
}

sub parser($;$) {
    my $self = shift;
    if (@_) {
        $self->{'parser'} = shift;
    } else {
        return $self->{'parser'};
    }
}

sub level($;$) {
    my $self = shift;
    if (@_) {
        $self->{'level'} = shift;
    } else {
        return $self->{'level'};
    }
}

sub inc_level($) {
    my $self = shift;
    my $res = $self->{'level'}++;
    return $res;
}

sub dec_level($) {
    my $self = shift;
    my $res = --$self->{'level'};
    return $res;
}

sub error($$) {
    my($self, $msg) = @_;
    $self->parser()->error($msg);
}

sub characters($$) {
    my($self, $text) = @_;
    if ($text !~ /^\s*$/s) {
        $self->error("Unexpected non-whitespace: $text");
    }
}

sub end($$) {
    my($self,$name) = @_;
    my $l = $self->dec_level();
    if ($l == 0) {
        $self->parser()->remove($self);
    }
    return $l;
}

1;
