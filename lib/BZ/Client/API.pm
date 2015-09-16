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

1;

__END__

=encoding utf8

=head1 SYNOPSIS

This is an abstract base class for classes like L<BZ::Client::Product>, which
are subclassing this one, in order to inherit common functionality.

=head1 SEE ALSO

  L<BZ::Client>

