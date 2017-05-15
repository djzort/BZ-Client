#!/bin/false
# PODNAME: BZ::Client::XMLRPC::Handler
# ABSTRACT: Abstract event handler for parsing an XML-RPC response.
use strict;
use warnings 'all';

package BZ::Client::XMLRPC::Handler;

sub new {
    my $class = shift;
    my $self = { @_ };
    $self->{'level'} = 0;
    bless($self, ref($class) || $class);
    return $self
}

sub init {
    my($self,$parser) = @_;
    $self->parser($parser);
}

sub parser {
    my $self = shift;
    if (@_) {
        $self->{'parser'} = shift;
    }
    else {
        return $self->{'parser'};
    }
}

sub level {
    my $self = shift;
    if (@_) {
        $self->{'level'} = shift;
    }
    else {
        return $self->{'level'};
    }
}

sub inc_level {
    my $self = shift;
    my $res = $self->{'level'}++;
    return $res
}

sub dec_level {
    my $self = shift;
    my $res = --$self->{'level'};
    return $res
}

sub error {
    my($self, $msg) = @_;
    $self->parser()->error($msg);
}

sub characters {
    my($self, $text) = @_;
    if ($text !~ m/^\s*$/s) {
        $self->error("Unexpected non-whitespace: $text");
    }
}

sub end {
    # my($self,$name) = @_;
    my $self = shift;
    my $l = $self->dec_level();
    if ($l == 0) {
        $self->parser()->remove($self);
    }
    return $l
}

1;
