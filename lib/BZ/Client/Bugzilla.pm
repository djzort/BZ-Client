#!/bin/false
# PODNAME: BZ::Client::Bugzilla
# ABSTRACT: Information about the Bugzilla server, i.e. the Bugzilla::Webservices::Bugzilla API

use strict;
use warnings 'all';

package BZ::Client::Bugzilla;

use parent qw( BZ::Client::API );

## functions

sub extensions {
    my($class, $client) = @_;
    return $class->api_call($client, 'Bugzilla.extensions');
}

sub time {
    my($class, $client) = @_;
    $client->log('debug', __PACKAGE__ . '::time: Asking');
    my $time = $class->api_call($client, 'Bugzilla.time');
    $client->log('debug', __PACKAGE__ . '::time: Got $time');
    return $time
}

sub timezone {
    my($class, $client) = @_;
    $client->log('debug', __PACKAGE__ . '::timezone: Asking');
    my $timezone = $class->api_call($client, 'Bugzilla.timezone');
    $client->log('debug', __PACKAGE__ . '::time: Got $timezone');
    return $timezone
}

sub version {
    my($class, $client) = @_;
    $client->log('debug', __PACKAGE__ . '::version: Asking');
    my $version = $class->api_call($client, 'Bugzilla.version');
    $client->log('debug', __PACKAGE__ . '::time: Got $version');
    return $version
}

1;

__END__

=pod

=encoding utf8

=head1 SYNOPSIS

This class provides methods for accessing information about the Bugzilla
servers installation.

  my $client = BZ::Client->new( url      => $url,
                                user     => $user,
                                password => $password );

  my $extensions = BZ::Client::Bugzilla->extensions( $client );
  my $time = BZ::Client::Bugzilla->time( $client );
  my $version = BZ::Client::Bugzilla->version( $client );

=head1 CLASS METHODS

This section lists the class methods, which are available in this module.

=head2 extensions

  my $extensions = BZ::Client::Bugzilla->extensions( $client );

Returns a hash ref with information about the Bugzilla servers extensions.

=head2 time

  my $time = BZ::Client::Bugzilla->time( $client );

Returns a hash ref with information about the Bugzilla servers local time.

Note: as of Bugzilla 3.6 this will always return UTC values.

=head2 timezone

  my $timezone = BZ::Client::Bugzilla->timezone( $client );

Returns the Bugzilla servers timezone as a numeric value. This method
is deprecated: Use L</time> instead.

Note: as of Bugzilla 3.6 the timezone is always +0000 (UTC)
Also, Bugzilla has depreceated but not yet removed this API call

=head2 version

  my $version = BZ::Client::Bugzilla->version( $client );

Returns the Bugzilla servers version.

=head1 TODO

=over 4

=item paramaters (added in 4.4)

=item last_audit_time (added in 4.4)

=back

=head1 SEE ALSO

L<BZ::Client>, L<BZ::Client::API>, L<Bugzilla API|https://www.bugzilla.org/docs/tip/en/html/api/Bugzilla/WebService/Bugzilla.html>

