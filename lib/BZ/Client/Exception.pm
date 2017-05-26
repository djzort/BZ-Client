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

=pod

=encoding utf8

=head1 SYNOPSIS

BZ::Client does not return error codes or do similar stuff.
Instead, it throws instances of BZ::Client::Exception.

  my $exception = BZ::Client::Exception->new( message     => $message,
                                              http_code   => $httpCode,
                                              xmlrpc_code => $xmlrpcCode );

  BZ::Client::Exception->throw( message     => $message,
                                http_code   => $httpCode,
                                xmlrpc_code => $xmlrpcCode );

=head1 METHODS

=head2 new

Creates the exception object

=head2 throw

Creates the exception object then dies, so make sure you catch it!

=head2 message

Returns the error message text

=head2 xmlrpc_code

Returns the error code from XMLRPC

=head2 http_code

Returns the http code (200, 404, etc)

=head1 EXAMPLE

Here are two examples. The first uses Perl's inbuilt eval() function, the
second uses the Try::Tiny module. Further alternatives exist and may be
perfectly good options if they suit you.

=head2 eval

 use BZ::Client;
 use BZ::Client::Bug::Attachment;
 use v5.10;

 my $client = BZ::Client->new( %etc );

 eval {
     my $att = BZ::Client::Bug::Attachment->get($client, { ids => 30505 });
 };

 if ($@) {
     say 'An Error Occured';
     say 'Message: ', $@->message();
     say 'HTTP Code: ', $@->http_code() if $@->http_code();
     say 'XMLrpc Code: ', $@->xmlrpc_code() if $@->xmlrpc_code();
 };

=head2 Try::Tiny

 use BZ::Client;
 use BZ::Client::Bug::Attachment;
 use Try::Tiny;
 use v5.10;

 my $client = BZ::Client->new( %etc );

 try {
     my $att = BZ::Client::Bug::Attachment->get($client, { ids => 30505 });
 }

 catch {
     say 'An Error Occured';
     say 'Message: ', $_->message();
     say 'HTTP Code: ', $_->http_code() if $_->http_code();
     say 'XMLrpc Code: ', $_->xmlrpc_code() if $_->xmlrpc_code();
 };

=head1 SEE ALSO

L<BZ::Client>
