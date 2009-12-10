#
# BZ::Client::XMLRPC::Struct - Event handler for parsing a single XML-RPC struct.
#
package BZ::Client::XMLRPC::Struct;

use strict;
use warnings "all";

use BZ::Client::XMLRPC::Handler();

our $VERSION = 1.0;
our @ISA = qw(BZ::Client::XMLRPC::Handler);

sub init($$) {
    my ($self, $parser) = @_;
    $self->SUPER::init($parser);
    $self->{'result'} = {};
}

sub start($$) {
    my($self,$name) = @_;
    my $l = $self->inc_level();
    if ($l == 0) {
        if ("struct" ne $name) {
            $self->error("Expected struct element, got $name");
        }
    } elsif ($l == 1) {
        if ("member" ne $name) {
            $self->error("Expected struct/member element, got $name");
        }
        $self->{'current_name'} = undef;
        $self->{'parsing_name'} = undef;
    } elsif ($l == 2) {
        if ("name" eq $name) {
            $self->error("Multiple name elements in struct/member") if defined($self->{'parsing_name'});
            $self->{'parsing_name'} = "";
        } elsif ("value" eq $name) {
            my $current_name = $self->{'current_name'};
            $self->error("Expected struct/member/name element, got value") unless defined($current_name);
            $self->error("Multiple value elements in struct/member, or multiple members with the same name.") if defined($self->{'result'}->{$current_name});
            my $handler = BZ::Client::XMLRPC::Value->new();
            $self->parser()->register($self, $handler, sub {
                $self->{'result'}->{$current_name} = $handler->result();
            });
            $handler->start($name);
        } else {
            $self->error("Expected name|value element in struct/member, got $name");
        }
    } else {
        $self->error("Unexpected level $l with element $name");
    }
}

sub end($$) {
    my($self,$name) = @_;
    my $l = $self->SUPER::end($name);
    if ($l == 2  &&  defined($self->{'parsing_name'})) {
        $self->{'current_name'} = $self->{'parsing_name'};
    }
    return $l;
}

sub characters($$) {
    my($self, $text) = @_;
    my $l = $self->level();
    if ($l == 3  &&  defined($self->{'parsing_name'})) {
        $self->{'parsing_name'} .= $text;
    } else {
        $self->SUPER::characters($text);
    }
}

sub result($) {
    my($self) = shift;
    return $self->{'result'};
}

1;
