#!/bin/false
# PODNAME: BZ::Client::FlagType
# ABSTRACT: The API for creating, changing, and getting info on Flags

use strict;
use warnings 'all';

package BZ::Client::FlagType;

use parent qw( BZ::Client::API );

# See https://www.bugzilla.org/docs/tip/en/html/api/Bugzilla/WebService/FlagType.html

## functions

sub get {
    my($class, $client, $params) = @_;
    my $result = $class->api_call($client, 'FlagType.get', $params);
    return wantarray ? %$result : $result
}

sub create {
    my($class, $client, $params) = @_;
    return _create($client, 'FlagType.create', $params, 'flag_id');
}

sub update {
    my($class, $client, $params) = @_;
    return _returns_array($client, 'FlagType.update', $params, 'flagtypes');
}

1;

__END__

=pod

=encoding utf8

=head1 SYNOPSIS

This class provides methods for accessing and managing Flags in Bugzilla.

 my $client = BZ::Client->new( url       => $url,
                               user      => $user,
                               password  => $password );

 my $id = BZ::Client::FlagType->create( $client, \%params );

=head1 CLASS METHODS

This section lists the class methods, which are available in this module.

=head2 create

 $id = BZ::Client::FlagType->create( $client, \%params );

This allows you to create a new Flag Type in Bugzilla.

Marked as unstable as of Bugzilla 5.0.

Added in Bugzilla 5.0.

=head3 Parameters

Some params must be set, or an error will be thrown. These params are noted as Required.

=over 4

=item name

I<name> (string)  A short name identifying this type.

Required.

=item description

I<description> (string) A comprehensive description of this type.

Required.

=item inclusions

I<inclusions> (array) An array of strings or a hash containing product names,
and optionally component names. If you provide a string, the flag type will be shown on all
bugs in that product. If you provide a hash, the key represents the product name, and the
value is the components of the product to be included.

For example:

 [ 'FooProduct',
    {
      BarProduct => [ 'C1', 'C3' ],
      BazProduct => [ 'C7' ]
    }
 ]

This flag will be added to All components of FooProduct, components C1 and C3 of BarProduct,
and C7 of BazProduct.

=item exclusions

I<exclusions> (array) An array of strings or hashes containing product names. This uses the same format
as inclusions.

This will exclude the flag from all products and components specified.

=item sortkey

I<sortkey>  (int) A number between 1 and 32767 by which this type will be sorted when displayed
to users in a list; ignore if you don't care what order the types appear in or if you want them
to appear in alphabetical order.

=item is_active

I<is_active> (boolean) Flag of this type appear in the UI and can be set.

Default is true.

=item is_requestable

I<is_requestable> (boolean) Users can ask for flags of this type to be set.

Default is true.

=item cc_list

I<cc_list> (array) An array of strings. If the flag type is requestable, who should receive e-mail
notification of requests. This is an array of e-mail addresses which do not need to be Bugzilla logins.

=item is_specifically_requestable

I<is_specifically_requestable> (boolean) Users can ask specific other users to set flags of this
type as opposed to just asking the wind.

Default is true.

=item is_multiplicable

I<is_multiplicable> (boolean) Multiple flags of this type can be set on the same bug.

Default is true.

=item grant_group

I<grant_group> (string) The group allowed to grant/deny flags of this type (to allow all users to
grant/deny these flags, select no group).

Default is no group.


=item request_group

I<request_group> (string) If flags of this type are requestable, the group allowed to request them
(to allow all users to request these flags, select no group). Note that the request group alone has
no effect if the grant group is not defined!

Default is no group.

=back

=head3 Returns

The ID of the newly-created group.

=head3 Errors

=over 4


=item 51 - Group Does Not Exist

The group name you entered does not exist, or you do not have access to it.

=item 105 - Unknown component

The component does not exist for this product.

=item 106 - Product Access Denied

Either the product does not exist or you don't have editcomponents privileges to it.

=item 501 - Illegal Email Address

One of the e-mail address in the CC list is invalid. An e-mail in the CC list does NOT need to be a
valid Bugzilla user.

=item 1101 - Flag Type Name invalid

You must specify a non-blank name for this flag type. It must no contain spaces or commas, and must
be 50 characters or less.

=item 1102 - Flag type must have description

You must specify a description for this flag type.

=item 1103 - Flag type CC list is invalid

The CC list must be 200 characters or less.

=item 1104 - Flag Type Sort Key Not Valid

The sort key is not a valid number.

=item 1105 - Flag Type Not Editable

This flag type is not available for the products you can administer. Therefore you can not edit
attributes of the flag type, other than the inclusion and exclusion list.

=back

=head2 update

Implemented but documentation is TODO

=head2 get

Implemented but documentation is TODO

=head1 INSTANCE METHODS

Not yet implemented

=head1 SEE ALSO

L<BZ::Client>, L<BZ::Client::API>, L<Bugzilla API|https://www.bugzilla.org/docs/tip/en/html/api/Bugzilla/WebService/FlagType.html>
