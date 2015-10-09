#!/bin/false
# PODNAME: BZ::Client::Group
# ABSTRACT: The API for creating, changing, and getting info on Groups

use strict;
use warnings 'all';

package BZ::Client::Group;

use parent qw( BZ::Client::API );

# See https://www.bugzilla.org/docs/tip/en/html/api/Bugzilla/WebService/Group.html

## functions

sub create {
    my($class, $client, $params) = @_;
    return _create($client, 'Group.create', $params);
}

sub update {
    my($class, $client, $params) = @_;
    return _returns_array($client, 'Group.update', $params, 'groups');
}

sub get {
    my($class, $client, $params) = @_;
    my $result = $class->api_call($client, 'Group.get', $params);
    return wantarray ? %$result : $result
}

1;

__END__

=pod

=encoding utf8

=head1 SYNOPSIS

This class provides methods for accessing and managing Groups in Bugzilla.

 my $client = BZ::Client->new( url       => $url,
                               user      => $user,
                               password  => $password );

 my $id = BZ::Client::Group->create( $client, \%params );

=head1 CLASS METHODS

This section lists the class methods, which are available in this module.

=head2 create

 $id = BZ::Client::Group->create( $client, \%params );

This allows you to create a new Group in Bugzilla.

Marked as unstable as of Bugzilla 5.0.

=head3 Parameters

Some params must be set, or an error will be thrown. These params are noted as Required.

=over 4

=item name

I<name> (string) A short name for this group. Must be unique.

This is infrequently displayed in the web user interface.

Required.

=item description

I<description> (string) A human-readable name for this group. Should be relatively short.

This is what will normally appear in the UI as the name of the group.

Required.

=item user_regexp

I<user_regexp> (string) A regular expression. Any user whose Bugzilla username matches this regular expression will automatically be granted membership in this group.

=item is_active

I<is_active> (boolean) True if new group can be used for bugs,

False if this is a group that will only contain users and no bugs will be restricted to it.

=item icon_url

I<icon_url> (boolean) A URL pointing to a small icon used to identify the group. This icon will show up next to users' names in various parts of Bugzilla if they are in this group.

=back

=head3 Returns

The ID of the newly-created group.

=head3 Errors

=over 4

=item 800 - Empty Group Name

You must specify a value for the L</name> field.

=item 801 - Group Exists

There is already another group with the same L</name>.

=item 802 - Group Missing Description

You must specify a value for the L</description> field.

=item 803 - Group Regexp Invalid

You specified an invalid regular expression in the L</user_regexp> field.

=back

=head2 update

 $id = BZ::Client::Group->update( $client, \%params );

This allows you to update a Group in Bugzilla.

As of Bugzilla 5.0. this is marked as unstable.

=head3 Parameters

Either L</ids> or L</names> is required to select the bugs you want to update.

All other values change or set something in the product.

=over 4

=item ids

I<ids> (array) Numeric ids of the groups you wish to update.

=item names

I<names> (array) Text names of the groups that you wish to update.

=item name

I<name> (string) A new name for group.

=item description

I<description> (string) A new description for groups. This is what will appear in the UI as the name of the groups.

=item user_regexp

I<user_regexp> (string) A new regular expression for email. Will automatically grant membership to these groups to anyone with an email address that matches this perl regular expression.

=item is_active

I<is_active> (boolean) Set if groups are active and eligible to be used for bugs. True if bugs can be restricted to this group, false otherwise.

=item icon_url

I<icon_url> (string) A URL pointing to an icon that will appear next to the name of users who are in this group.

=back

=head3 Returns

An array or arrayref of hashes containing the following:

=over 4

=item id

I<id> (int) The id of the Group that was updated.

=item changes

The changes that were actually done on this Group. The keys are the names of the
fields that were changed, and the values are a hash with two keys:

=over 4

=item added

I<added> (string)  The values that were added to this field, possibly a comma-and-space-separated list if multiple values were added.

=item removed

I<removed> (string) The values that were removed from this field, possibly a comma-and-space-separated list if multiple values were removed.

=back

Note that booleans will be represented with the strings '1' and '0'.

=back

=head3 Errors

=over 4

=item 800 - Empty Group Name

You must specify a value for the L</name> field.

=item 801 - Group Exists

There is already another group with the same L</name>.

=item 802 - Group Missing Description

You must specify a value for the L</description> field.

=item 803 - Group Regexp Invalid

You specified an invalid regular expression in the L</user_regexp> field.

=back

=head2 get

Implemented but documentation is TODO

=head1 INSTANCE METHODS

Not yet implemented

=head1 SEE ALSO

L<BZ::Client>, L<BZ::Client::API>, L<Bugzilla API|https://www.bugzilla.org/docs/tip/en/html/api/Bugzilla/WebService/Group.html>
