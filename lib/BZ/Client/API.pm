#
# BZ::Client::API - Abstract base class for the clients of the Bugzilla API.
#

use strict;
use warnings "all";

package BZ::Client::API;

our $VERSION = 1.0;

sub api_call($$$$) {
    my($class, $client, $methodName, $params) = @_;
    return $client->api_call($methodName, $params);
}

sub error($$$;$$) {
    my($class, $client, $message, $http_code, $xmlrpc_code) = @_;
    return $client->error($message, $http_code, $xmlrpc_code);
}

1;

=pod

=head1 NAME

  BZ::Client::API - Abstract base class for the clients of the Bugzilla API.

This is an abstract base class for classes like L<BZ::Client::Product>, which
are subclassing this one, in order to inherit common functionality.


=head1 SEE ALSO

  L<BZ::Client>
 