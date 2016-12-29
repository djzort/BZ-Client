#!/bin/false
# PODNAME: BZ::Client::BugUserLastVisit
# ABSTRACT: Find and Store the last time a user visited a Bugzilla Bug.

use strict;
use warnings 'all';

package BZ::Client::BugUserLastVisit;


use parent qw( BZ::Client::API );

# See https://www.bugzilla.org/docs/tip/en/html/api/Bugzilla/WebService/BugUserLastVisit.html

## functions

sub update {
    my($class, $client, $params) = @_;
    my $result = $class->api_call($client, 'BugUserLastVisit.update', $params);
    return wantarray ? @$result : $result
}

sub get {
    my($class, $client, $params) = @_;
    my $result = $class->api_call($client, 'BugUserLastVisit.get', $params);
    return wantarray ? @$result : $result
}

1;

__END__

=pod

=encoding utf8

=head1 SYNOPSIS

Find and Store the last time a user visited a Bug. in Bugzilla.

 my $client = BZ::Client->new( url       => $url,
                               user      => $user,
                               password  => $password );

 my @details = BZ::Client::BugUserLastVisit->update( $client, \%params );
 my @details = BZ::Client::BugUserLastVisit->get( $client, \%params );

=head1 CLASS METHODS

This section lists the class methods, which are available in this module.

=head2 update

 @details = BZ::Client::BugUserLastVisit->update( $client, \%params );
 $details = BZ::Client::BugUserLastVisit->update( $client, \%params );

Update the last visit time for the specified bug and current user.

=head3 History

Marked as experimental in Bugzill 5.0.

=head3 Parameters

=over 4

=item ids

I<ids> (array) - One or more bug ids to add

=back

=head3 Returns

An array of hashes containing the following;

=over 4

=item id

I<id> (int) The bug id.

=item last_visit_ts

I<last_visit_ts> (string) The timestamp the user last visited the bug.

=back

=head2 get

 @details = BZ::Client::BugUserLastVisit->get( $client, \%params );
 $details = BZ::Client::BugUserLastVisit->get( $client, \%params );

Get the last visited timestamp for one or more specified bug ids.

=head3 Parameters

=over 4

=item ids

I<ids> (array) - One or more bug ids to add

=back

=head3 Returns

An array of hashes containing the following;

=over 4

=item id

I<id> (int) The bug id.

=item last_visit_ts

I<last_visit_ts> (string) The timestamp the user last visited the bug.

=back

=head1 EXCEPTION HANDLING

See L<BZ::Client::Exception>

=head1 SEE ALSO

L<BZ::Client>, L<BZ::Client::API>, L<Bugzilla API|https://www.bugzilla.org/docs/tip/en/html/api/Bugzilla/WebService/BugUserLastVisit.html>
