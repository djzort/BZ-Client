#!/bin/false
# PODNAME: BZ::Client::API
# ABSTRACT: Abstract base class for the clients of the Bugzilla API.

use strict;
use warnings 'all';

package BZ::Client::API;

sub api_call {
    my($class, $client, $methodName, $params) = @_;
    return $client->api_call($methodName, $params)
}

sub error {
    my($class, $client, $message, $http_code, $xmlrpc_code) = @_;
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
    my($class, $client, $methodName, $params, $key) = @_;
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
    my($class, $client, $methodName, $params, $key) = @_;
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

=head1 SEE ALSO

L<BZ::Client>

