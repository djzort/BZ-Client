#!/bin/false
# PODNAME: BZ::Client::Bugzilla
# ABSTRACT: Information about the Bugzilla server, i.e. the Bugzilla::Webservices::Bugzilla API

use strict;
use warnings 'all';

package BZ::Client::Bugzilla;

use BZ::Client::API();

our @ISA = qw(BZ::Client::API);

sub extensions {
    my($class, $client) = @_;
    return $class->api_call($client, 'Bugzilla.extensions');
}

sub time {
    my($class, $client) = @_;
    $client->log('debug', 'BZ::Client::Bugzilla::time: Asking');
    my $time = $class->api_call($client, 'Bugzilla.time');
    $client->log('debug', 'BZ::Client::Bugzilla::time: Got $time');
    return $time
}

sub timezone {
    my($class, $client) = @_;
    $client->log('debug', 'BZ::Client::Bugzilla::timezone: Asking');
    my $timezone = $class->api_call($client, 'Bugzilla.timezone');
    $client->log('debug', 'BZ::Client::Bugzilla::time: Got $timezone');
    return $timezone
}

sub version {
    my($class, $client) = @_;
    $client->log('debug', 'BZ::Client::Bugzilla::version: Asking');
    my $version = $class->api_call($client, 'Bugzilla.version');
    $client->log('debug', 'BZ::Client::Bugzilla::time: Got $version');
    return $version
}

1;

__END__

=encoding utf-8

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

=head2 timezone

  my $timezone = BZ::Client::Bugzilla->timezone( $client );

Returns the Bugzilla servers timezone as a numeric value. This method
is deprecated: Use L</time> instead.

=head2 version

  my $version = BZ::Client::Bugzilla->version( $client );

Returns the Bugzilla servers version.


=head1 SEE ALSO

  L<BZ::Client>, L<BZ::Client::API>

