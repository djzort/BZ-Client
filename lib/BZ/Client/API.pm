#!/bin/false
# PODNAME: BZ::Client::API
# ABSTRACT: Abstract base class for the clients of the Bugzilla API.

use strict;
use warnings 'all';

package BZ::Client::API;


sub api_call {
    my(undef, $client, $methodName, $params) = @_;
    return $client->api_call($methodName, $params)
}

sub error {
    my(undef, $client, $message, $http_code, $xmlrpc_code) = @_;
    return $client->error($message, $http_code, $xmlrpc_code)
}

sub new {
    my $class = shift;
    my $self = { @_ };
    bless($self, ref($class) || $class);
    return $self
}

# Move stuff here so we dont do it over and over

sub _create {
    my(undef, $client, $methodName, $params, $key) = @_;
    $key ||= 'id';
    my $sub = ( caller(1) )[3];
    $client->log('debug', $sub . ': Running');
    my $result = __PACKAGE__->api_call($client, $methodName, $params);
    my $id = $result->{$key};
    if (!$id) {
        __PACKAGE__->error($client, "Invalid reply by server, expected $methodName $key.");
    }
    $client->log('debug', "$sub: Returned $id");
    return $id
}

sub _returns_array {
    my(undef, $client, $methodName, $params, $key) = @_;
    my $sub = ( caller(1) )[3];
    $client->log('debug',$sub . ': Running');
    my $result = __PACKAGE__->api_call($client, $methodName, $params);
    my $foo = $result->{$key};
    if (!$foo || 'ARRAY' ne ref($foo)) {
        __PACKAGE__->error($client, "Invalid reply by server, expected array of $methodName details");
    }
    $client->log('debug', "$sub: Recieved results");
    return wantarray ? @$foo : $foo
}



1;

__END__

=pod

=encoding utf8

=head1 SYNOPSIS

This is an abstract base class for classes like L<BZ::Client::Product>, which
are subclassing this one, in order to inherit common functionality.

None of these methods are useful to end users.

=head1 METHODS

=head2 api_call

Wraps C<BZ::Client::api_call>

=head2 error

Wraps C<BZ::Client::error>

=head2 new

Generic C<new()> function. Saving doing it over and over.

=head2 _create

Calls something on the Bugzilla Server, and returns and ID.

=head2 _returns_array

Calls something on the Bugzilla Server, and returns an array / arrayref.

=head1 SEE ALSO

L<BZ::Client>

