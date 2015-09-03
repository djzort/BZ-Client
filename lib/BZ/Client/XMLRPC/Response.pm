#
# BZ::Client::XMLRPC::Response - Event handler for parsing an XML-RPC response.
#
use strict;
use warnings "all";

package BZ::Client::XMLRPC::Response;

use BZ::Client::XMLRPC::Handler();
use BZ::Client::XMLRPC::Value();

our @ISA = qw(BZ::Client::XMLRPC::Handler);

sub start {
    my($self,$name) = @_;
    my $l = $self->inc_level();
    if ($l == 0) {
        if ("methodResponse" ne $name) {
            $self->error("Expected methodResponse element, got $name");
        }
    } elsif ($l == 1) {
        if ("fault" eq $name) {
            $self->{'in_fault'} = 1;
        } elsif ("params" eq $name) {
            if (defined($self->{'result'})) {
                $self->error("Multiple elements methodResponse/params found.");
            }
            $self->{'in_fault'} = 0;
        } else {
            $self->error("Unexpected element methodResponse/$name, expected fault|params");
        }
    } elsif ($l == 2) {
        if ($self->{'in_fault'}) {
            if ("value" ne $name) {
                $self->error("Unexpected element methodResponse/fault/$name, expected value");
            }
            my $handler = BZ::Client::XMLRPC::Value->new();
            $self->parser()->register($self, $handler, sub {
                my $result = $handler->result();
                if ("HASH" ne ref($result)) {
                    $self->error("Failed to parse XML-RPC response document: Error reported, but no faultCode and faultString found.");
                }
                my $faultCode = $result->{"faultCode"};
                my $faultString = $result->{"faultString"};
                require BZ::Client::Exception;
                $self->{"exception"} = BZ::Client::Exception->new("message" => $faultString,
                                                                  "xmlrpc_code" => $faultCode);
            });
            $handler->start($name);
        } else {
            if ("param" ne $name) {
                $self->error("Unexpected element methodResponse/params/$name, expected param");
            }
            if (defined($self->{'result'})) {
                $self->error("Multiple elements methodResponse/params/param found.");
            }
        }
    } elsif ($l == 3) {
        if ($self->{'in_fault'}) {
            $self->error("Unexpected element $name found at level $l");
        } else {
            if ("value" ne $name) {
                $self->error("Unexpected element methodResponse/params/param/$name, expected value");
            }
            if (defined($self->{'result'})) {
                $self->error("Multiple elements methodResponse/params/param/value found.");
            }
            my $handler = BZ::Client::XMLRPC::Value->new();
            $self->parser()->register($self, $handler, sub {
                $self->{"result"} = $handler->result();
            });
            $handler->start($name);
        }
    }
}

sub end {
    my($self, $name) = @_;
    my $l = $self->SUPER::end($name);
    return $l;
}

sub exception {
    my $self = shift;
    return $self->{"exception"};
}

sub result {
    my $self = shift;
    return $self->{"result"};
}


1;
