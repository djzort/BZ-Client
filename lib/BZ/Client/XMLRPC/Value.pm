#!/bin/false
# PODNAME: BZ::Client::XMLRPC::Value
# ABSTRACT: Event handler for parsing a single XML-RPC value.

use strict;
use warnings 'all';

package BZ::Client::XMLRPC::Value;

use parent qw( BZ::Client::XMLRPC::Handler );
use BZ::Client::XMLRPC::Struct;
use BZ::Client::XMLRPC::Array;
use DateTime::Format::ISO8601 ();

sub start {
    my ( $self, $name ) = @_;
    my $l = $self->inc_level();
    if ( $l == 0 ) {
        if ( 'value' ne $name ) {
            $self->error("Expected value element, got $name");
        }
        $self->{'level0_content'} = q();
    }
    elsif ( $l == 1 ) {
        if ( 'struct' eq $name ) {
            my $handler = BZ::Client::XMLRPC::Struct->new();
            $self->parser()->register(
                $self, $handler,
                sub {
                    $self->{'result'} = $handler->result();
                }
            );
            $handler->start($name);
        }
        elsif ( 'array' eq $name ) {
            my $handler = BZ::Client::XMLRPC::Array->new();
            $self->parser()->register(
                $self, $handler,
                sub {
                    $self->{'result'} = $handler->result();
                }
            );
            $handler->start($name);
        }
        elsif ('i4'               eq $name
            || 'int'              eq $name
            || 'string'           eq $name
            || 'double'           eq $name
            || 'dateTime.iso8601' eq $name
            || 'base64'           eq $name
            || 'boolean'          eq $name )
        {
            $self->{'level1_elem'}    = $name;
            $self->{'level1_content'} = q();
        }
        else {
            $self->error(
"Expected struct|array|i4|int|boolean|string|double|dateTime.iso8601|base64 element, got $name"
            );
        }
    }
    else {
        $self->error("Unexpected element $name at level $l");
    }
}

sub end {
    my ( $self, $name ) = @_;
    my $l = $self->level();
    if ( $l == 1 ) {
        my $content = $self->{'level0_content'};
        if ( defined( $self->{'result'} ) ) {
            if ( $content !~ m/^\s*$/s ) {
                $self->error('Unexpected non-whitespace content');
            }
        }
        else {
            $self->{'result'} = $content;
        }
    }
    elsif ( $l == 2 ) {
        my $name = $name;
        if ( defined($name) ) {
            $self->{'result'}         = $self->{'level1_content'};
            $self->{'level1_content'} = undef;
            $self->{'level1_elem'}    = undef;
            if ( 'dateTime.iso8601' eq $name ) {
                my $val = $self->{'result'};
                if ( $val =~ m/(\d\d\d\d)(\d\d)(\d\d)(T\d\d:\d\d:\d\d)/ )
                {    # See https://rt.cpan.org/Public/Bug/Display.html?id=78467
                    $val = "$1-$2-$3$4";
                }
                $self->{'result'} =
                  DateTime::Format::ISO8601->parse_datetime($val)->set_time_zone('UTC');
            }
        }
    }
    return $self->SUPER::end($name)
}

sub characters {
    my ( $self, $text ) = @_;
    my $l = $self->level();
    if ( $l == 1 ) {
        $self->{'level0_content'} .= $text;
        return
    }
    elsif ( $l == 2 ) {
        my $l1_elem = $self->{'level1_elem'};
        if ( defined($l1_elem) ) {
            $self->{'level1_content'} .= $text;
            return
        }
    }
    $self->SUPER::characters($text);
}

sub result {
    my $self = shift;
    my $res = $self->{'result'};
    $res = defined($res) ? $res : q();
    return $res
}

1;
