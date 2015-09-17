#!/bin/false
# PODNAME: BZ::Client::XMLRPC::Array
# ABSTRACT: Event handler for parsing a single XML-RPC array.

use strict;
use warnings 'all';

package BZ::Client::XMLRPC::Array;

use parent qw(BZ::Client::XMLRPC::Handler);

sub init {
    my($self,$parser) = @_;
    $self->SUPER::init($parser);
    $self->{'result'} = []
}

sub start {
    my($self,$name) = @_;
    my $l = $self->inc_level();
    if ($l == 0) {
        if ('array' ne $name) {
            $self->error("Expected array element, got $name");
        }
    } elsif ($l == 1) {
        if ('data' ne $name) {
            $self->error("Expected array/data element, got $name");
        }
    } elsif ($l == 2) {
        if ('value' eq $name) {
            my $handler = BZ::Client::XMLRPC::Value->new();
            $self->parser()->register($self, $handler, sub {
                my $array = $self->{'result'};
                push(@$array, $handler->result());
                $array;
            });
            $handler->start($name);
        } else {
            $self->error("Expected array/data/value, got $name");
        }
    } else {
        $self->error("Unexpected level $l with element $name");
    }
    return $l
}

sub result {
    my $self = shift;
    return $self->{'result'}
}

1;
