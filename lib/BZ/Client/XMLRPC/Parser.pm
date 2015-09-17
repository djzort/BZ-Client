#!/bin/false
# PODNAME: BZ::Client::XMLRPC::Parser
# ABSTRACT: A parser for an XML-RPC response.

use strict;
use warnings 'all';

package BZ::Client::XMLRPC::Parser;

use BZ::Client::XMLRPC::Response;
use BZ::Client::Exception;
use XML::Parser ();

sub new {
    my $class = shift;
    my $self = { @_ };
    bless($self, ref($class) || $class);
    return $self
}

sub parse {
    my($self, $content) = @_;
    $self->{'stack'} = [];
    my $handler = BZ::Client::XMLRPC::Response->new();
    $self->register($self, $handler, sub {
        my($self, $handler) = @_;
        $self->{'exception'} = $handler->exception();
        $self->{'result'} = $handler->result();
    });
    my $start = sub {
        my($expat, $name, @args) = @_;
        my $current = $self->{'current'};
        $self->error('Illegal state, no more handlers available on stack.') unless $current;
        $current->start($name);
    };
    my $end = sub {
        my($expat, $name) = @_;
        my $current = $self->{'current'};
        $self->error('Illegal state, no more handlers available on stack.') unless $current;
        $current->end($name);
    };
    my $chars = sub {
        my($expat, $text) = @_;
        my $current = $self->{'current'};
        $self->error('Illegal state, no more handlers available on stack.') unless $current;
        $current->characters($text);
    };
    my $parser = XML::Parser->new(Handlers => {Start => $start,
                                               End   => $end,
                                               Char  => $chars});
    $parser->parse($content);
    die $self->{'exception'} if ($self->{'exception'});
    return $self->{'result'}
}

sub register {
    my($self, $parent, $handler, $code) = @_;
    my $current = [$parent, $handler, $code];
    if ($parent->can('dec_level')) {
        $parent->dec_level();
    }
    $self->{'current'} = $handler;
    push(@{$self->{'stack'}}, $current);
    $handler->init($self)
}

sub remove {
    my($self, $handler) = @_;
    my $stack = $self->{'stack'};
    my $top = pop @$stack;
    $self->{'current'} = @$stack ? $stack->[@$stack-1]->[1] : undef;
    $self->error('Illegal state, no more handlers available on stack.') unless $top;
    my($parent, $h, $code) = @$top;
    $self->error('Illegal state, the current handler is not the topmost.') unless $h eq $handler;
    &$code($parent, $h)
}

sub error {
    my($self, $message) = @_;
    BZ::Client::Exception->throw('message' => $message)
}

sub result {
    my $self = shift;
    my $res = $self->{'result'};
    return $res
}

sub exception {
    my $self = shift;
    return $self->{'exception'}
}

1;
