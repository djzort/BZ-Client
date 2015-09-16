#!/bin/false
# PODNAME: BZ::Client::Bug
# ABSTRACT: Client side representation of a bug in Bugzilla

use strict;
use warnings 'all';

package BZ::Client::Bug;

use BZ::Client::API();

our @ISA = qw(BZ::Client::API);

# See https://www.bugzilla.org/docs/4.4/en/html/api/Bugzilla/WebService/Bug.html

sub legal_values {
    my($class, $client, $field) = @_;
    $client->log('debug', "BZ::Client::Bug::legal_values: Asking for $field");
    my $params = { 'field' => $field };
    my $result = $class->api_call($client, 'Bug.legal_values', $params);
    my $values = $result->{'values'};
    if (!$values || 'ARRAY' ne ref($values)) {
        $class->error($client, 'Invalid reply by server, expected array of values.');
    }
    $client->log('debug', 'BZ::Client::Bug::legal_values: Got ' . join(',', @$values));
    return wantarray ? @$values : $values
}

sub get {
    my($class, $client, $ids, $permissive) = @_;
    $client->log('debug', 'BZ::Client::Bug::get: Asking for ' . (ref($ids) eq 'ARRAY' ? join(',', @$ids) : $ids));
    my $params = { ids => $ids };
    $params->{'permissive'} = BZ::Client::XMLRPC::boolean::TRUE() if $permissive;
    my $result = $class->api_call($client, 'Bug.get', $params);
    my $bugs = $result->{'bugs'};
    if (!$bugs  ||  'ARRAY' ne ref($bugs)) {
        $class->error($client, 'Invalid reply by server, expected array of bugs.');
    }
    my @result;
    for my $bug (@$bugs) {
        push(@result, BZ::Client::Bug->new(%$bug));
    }
    $client->log('debug', 'BZ::Client::Bug::get: Got ' . scalar(@result));
    return wantarray ? @result : \@result
}

sub search {
    my($class, $client, $params) = @_;
    $client->log('debug', 'BZ::Client::Bug::search: Searching');
    my $result = $class->api_call($client, 'Bug.search', $params);
    my $bugs = $result->{'bugs'};
    if (!$bugs || 'ARRAY' ne ref($bugs)) {
        $class->error($client, 'Invalid reply by server, expected array of bugs.');
    }
    my @result;
    for my $bug (@$bugs) {
        push(@result, BZ::Client::Bug->new(%$bug));
    }
    $client->log('debug', 'BZ::Client::Bug::search: Found ' . join(',',@result));
    return wantarray ? @result : \@result
}

sub create {
    my($class, $client, $params) = @_;
    $client->log('debug', 'BZ::Client::Bug::create: Creating');
    my $result = $class->api_call($client, 'Bug.create', $params);
    my $id = $result->{'id'};
    if (!$id) {
        $class->error($client, 'Invalid reply by server, expected bug ID.');
    }
    return $id
}

sub update {
    my($class, $client, $params) = @_;
    $client->log('debug', 'BZ::Client::Bug::update: Updating');
    my $result = $class->api_call($client, 'Bug.update', $params);
    my $bugs = $result->{'bugs'};
    if (!$bugs || 'ARRAY' ne ref($bugs)) {
        $class->error($client, 'Invalid reply by server, expected array of bug details.');
    }
    return wantarray ? @$bugs : $bugs
}

sub new {
    my $class = shift;
    my $self = { @_ };
    bless($self, ref($class) || $class);
    return $self
}

sub id {
    my $self = shift;
    if (@_) {
        $self->{'id'} = shift;
    } else {
        return $self->{'id'}
    }
}

sub alias {
    my $self = shift;
    if (@_) {
        $self->{'alias'} = shift;
    } else {
        return $self->{'alias'}
    }
}

sub assigned_to {
    my $self = shift;
    if (@_) {
        $self->{'assigned_to'} = shift;
    } else {
        return $self->{'assigned_to'}
    }
}

sub component {
    my $self = shift;
    if (@_) {
        $self->{'component'} = shift;
    } else {
        return $self->{'component'}
    }
}

sub creation_time {
    my $self = shift;
    if (@_) {
        $self->{'creation_time'} = shift;
    } else {
        return $self->{'creation_time'}
    }
}

sub dupe_of {
    my $self = shift;
    if (@_) {
        $self->{'dupe_of'} = shift;
    } else {
        return $self->{'dupe_of'}
    }
}

sub internals {
    my $self = shift;
    if (@_) {
        $self->{'internals'} = shift;
    } else {
        return $self->{'internals'}
    }
}

sub is_open {
    my $self = shift;
    if (@_) {
        $self->{'is_open'} = shift;
    } else {
        return $self->{'is_open'}
    }
}

sub last_change_time {
    my $self = shift;
    if (@_) {
        $self->{'last_change_time'} = shift;
    } else {
        return $self->{'last_change_time'}
    }
}

sub priority {
    my $self = shift;
    if (@_) {
        $self->{'priority'} = shift;
    } else {
        return $self->{'priority'}
    }
}

sub product {
    my $self = shift;
    if (@_) {
        $self->{'product'} = shift;
    } else {
        return $self->{'product'}
    }
}

sub resolution {
    my $self = shift;
    if (@_) {
        $self->{'resolution'} = shift;
    } else {
        return $self->{'resolution'}
    }
}

sub severity {
    my $self = shift;
    if (@_) {
        $self->{'severity'} = shift;
    } else {
        return $self->{'severity'}
    }
}

sub status {
    my $self = shift;
    if (@_) {
        $self->{'status'} = shift;
    } else {
        return $self->{'status'}
    }
}

sub summary {
    my $self = shift;
    if (@_) {
        $self->{'summary'} = shift;
    } else {
        return $self->{'summary'}
    }
}

1;

__END__

=encoding utf-8

=head1 SYNOPSIS

This class provides methods for accessing and managing bugs in Bugzilla.

  my $client = BZ::Client->new( url      => $url,
                                user     => $user,
                                password => $password );

  my $bugs = BZ::Client::Bug->get( $client, $ids );

=head1 UTILITY FUNCTIONS

This section lists the utility functions provided by this module.

These deal with bug-related information, but not bugs directly.

=head2 fields

FIXME

=head2 legal_values

  my $values = BZ::Client::Bug->legal_values( $client, $field )
  my @values = BZ::Client::Bug->legal_values( $client, $field )

Tells you what values are allowed for a particular field.

Note: This is deprecated in Bugzilla, use L<fields> instead.

Params:

=over 4

=item $field

The name of the field you want information about. This should be the same as the name you would use in L<create>, below.

=back

Returns:

=over 4

=item $values or @values

An array or arrayref of strings: the legal values for this field. The values will be sorted as they normally would be in Bugzilla.

=back

Errors:

=over 4

=item 106 - Invalid Product

You were required to specify a product, and either you didn't, or you specified an invalid product (or a product that you can't access).

=item 108 - Invalid Field Name

You specified a field that doesn't exist or isn't a drop-down field.

=back

=head1 FUNCTIONS FOR FINDING AND RETRIEVING BUGS

This section lists the class methods pertaining to finding and retrieving bugs from your server.

Listed here in order of what you most likely want to do... maybe?

=head2 get

  $ids = 101; or $ids = [ 69, 101 ]; or $ids = '69,101';

  my $bugs = BZ::Client::Bug->get( $client, $ids );
  my @bugs = BZ::Client::Bug->get( $client, $ids );

I<$ids> is an arrayref of ID's, or a scalar containing comma delimiteed ID's.

Returns an array or arrayref of bug instance objects with the given ID's.

See L<INSTANCE METHODS> for how to use them.

=head2 search

  my $bugs = BZ::Client::Bug->search( $client, $params );
  my @bugs = BZ::Client::Bug->search( $client, $params );

Searches for bugs matching the given parameters.

Returns an array or arrayref of bug instance objects with the given ID's.

See L<INSTANCE METHODS> for how to use them.

=head2 possible_duplicates

TODO

=head1 FUNCTIONS FOR CREATING AND MODIFYING BUGS

This section lists the class methods pertaining to the creation and modification of bugs.

Listed here in order of what you most likely want to do... maybe?

=head2 create

  my $id = BZ::Client::Bug->create( $client, $params );

Creates a new bug in your Bugzilla server and returns the bug ID.

=head2 update

  my $id = BZ::Client::Bug->update( $client, $params );

Allows you to update the fields of a bug.

(Your Bugzilla server may automatically sends emails out about the changes)

FIXME more details needed

=head2 update_see_also

TODO

=head2 update_tags

TODO

=head2 new

  my $bug = BZ::Client::Bug->new( id => $id );

Creates a new bug object instance with the given ID.

Note: Doesn't actually touch your bugzilla server.

See L<INSTANCE METHODS> for how to use it.

=head1 INSTANCE METHODS

This section lists the modules instance methods.

Once you have a bug object, you can use these methods to inspect and manipulate the bug.

=head2 id

  my $id = $bug->id();
  $bug->id( $id );

Gets or sets the bugs ID.

=head2 alias

  my $alias = $bug->alias();
  $bug->alias( $alias );

Gets or sets the bugs alias. If there is no alias or aliases are disabled in Bugzilla,
this will be an empty string.

=head2 assigned_to

  my $assigned_to = $bug->assigned_to();
  $bug->assigned_to( $assigned_to );

Gets or sets the login name of the user to whom the bug is assigned.

=head2 component

  my $component = $bug->component();
  $bug->component( $component );

Gets or sets the name of the current component of this bug.

=head2 creation_time

  my $dateTime = $bug->creation_time();
  $bug->creation_time( $dateTime );

Gets or sets the date and time, when the bug was created.

=head2 dupe_of

  my $dupeOf = $bug->dupe_of();
  $bug->dupe_of( $dupeOf );

Gets or sets the bug ID of the bug that this bug is a duplicate of. If this
bug isn't a duplicate of any bug, this will be an empty int.

=head2 is_open

  my $isOpen = $bug->is_open();
  $bug->is_open( $isOpen );

Gets or sets, whether this bug is closed. The return value, or parameter value
is true (1) if this bug is open, false (0) if it is closed.

=head2 last_change_time

  my $lastChangeTime = $bug->last_change_time();
  $bug->last_change_time( $lastChangeTime );

Gets or sets the date and time, when the bug was last changed.

=head2 priority

  my $priority = $bug->priority();
  $bug->priority( $priority );

Gets or sets the priority of the bug.

=head2 product

  my $product = $bug->product();
  $bug->product( $product );

Gets or sets the name of the product this bug is in.

=head2 resolution

  my $resolution = $bug->resolution();
  $bug->resolution( $resolution );

Gets or sets the current resolution of the bug, or an empty string if the bug is open.

=head2 severity

  my $severity = $bug->severity();
  $bug->severity( $severity );

Gets or sets the current severity of the bug.

=head2 status

  my $status = $bug->status();
  $bug->status( $status );

Gets or sets the current status of the bug.

=head2 summary

  my $summary = $bug->summary();
  $bug->summary( $summary );

Gets or sets the summary of this bug.

=head1 SEE ALSO

  L<BZ::Client>, L<BZ::Client::API>, L<https://www.bugzilla.org/docs/4.4/en/html/api/Bugzilla/WebService/Bug.html>
