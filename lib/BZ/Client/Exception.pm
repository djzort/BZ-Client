#!/bin/false
# PODNAME: BZ::Client::Exception
# ABSTRACT: Exception class thrown by BZ::Client in case of errors.

use strict;
use warnings 'all';

package BZ::Client::Exception;

sub throw {
    my $class = shift;
    die $class->new(@_)
}

sub new {
    my $class = shift;
    my $self = { @_ };
    bless($self, ref($class) || $class);
    return $self
}

sub message {
    my $self = shift;
    return $self->{'message'}
}

sub xmlrpc_code {
    my $self = shift;
    return $self->{'xmlrpc_code'}
}

sub http_code {
    my $self = shift;
    return $self->{'http_code'}
}

1;

__END__

=encoding utf-8

=head1 SYNOPSIS

BZ::Client does not return error codes or do similar stuff.
Instead, it throws instances of BZ::Client::Exception.

  my $exception = BZ::Client::Exception->new( message     => $message,
                                              http_code   => $httpCode,
                                              xmlrpc_code => $xmlrpcCode);

  BZ::Client::Exception->throw( message     => $message,
                                http_code   => $httpCode,
                                xmlrpc_code => $xmlrpcCode);

=head1 SEE ALSO

  L<BZ::Client>

