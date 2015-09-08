#!/bin/false
# PODNAME: BZ::Client::User
# ABSTRACT: Creates and edits user accounts in Bugzilla

use strict;
use warnings 'all';

package BZ::Client::User;

use BZ::Client::API();

our @ISA = qw(BZ::Client::API);

# See https://www.bugzilla.org/docs/4.4/en/html/api/Bugzilla/WebService/User.html

sub offer_account_by_email {
    my($class, $client, $params) = @_;
    $client->log('debug', 'BZ::Client::User::offer_account_by_email: Inviting');
    return $class->api_call($client, 'User.offer_account_by_email', $params);
}

sub get;

sub new {
    my $class = shift;
    my $self = { @_ };
    bless($self, ref($class) || $class);
    return $self
}

sub create {
    my($class, $client, $params) = @_;
    $client->log('debug', 'BZ::Client::User::create: Creating');
    my $result = $class->api_call($client, 'User.create', $params);
    my $id = $result->{'id'};
    if (!$id) {
        $class->error($client, 'Invalid reply by server, expected user ID.');
    }
    return $id
}

sub update;

1;

__END__

=encoding utf-8

=head1 SYNOPSIS

This class provides methods for accessing information about the Bugzilla
servers installation.

  my $client = BZ::Client->new( url      => $url,
                                user     => $user,
                                password => $password );

  my $bugs = BZ::Client::User->get( $client, \%params );

=head1 CLASS METHODS

This section lists the class methods, which are available in this module.

=head2 offer_account_by_email

  my $extensions = BZ::Client::User->offer_account_by_email( $client, \%params );

Sends an email to the user, offering to create an account. The user will have to click on a URL in the email, and choose their password and real name.

This is the recommended way to create a Bugzilla account.

Params:

=over 4

=item email

I<email> (string) The email address to send the offer to.

=back

Returns: nothing if successfull

Errors:

=over 4

=item 500 - Account Already Exists

An account with that email address already exists in Bugzilla.

=item 501 - Illegal Email Address

This Bugzilla does not allow you to create accounts with the format of email address you specified. Account creation may be entirely disabled.

=back

=head2 get

  my $bugs = BZ::Client::User->get( $client, \%params );

Gets information about user accounts in Bugzilla. Added in Bugzilla 3.4

Params:

Note: At least one of I<ids>, I<names>, or I<match> must be specified.

Note: Users will not be returned more than once, so even if a user is matched by more than one argument, only one user will be returned.

In addition to the parameters below, this method also accepts the standard I<include_fields> and I<exclude_fields> arguments.

=over 4

=item ids (array)

An array of integers, representing user ids.

Logged-out users cannot pass this parameter to this function. If they try, they will get an error. Logged-in users will get an error if they specify the id of a user they cannot see.

=item names (array)

An array of login names (strings).

=item match (array)

An array of strings. This works just like "user matching" in Bugzilla itself. Users will be returned whose real name or login name contains any one of the specified strings. Users that you cannot see will not be included in the returned list.

Most installations have a limit on how many matches are returned for each string, which defaults to 1000 but can be changed by the Bugzilla administrator.

Logged-out users cannot use this argument, and an error will be thrown if they try. (This is to make it harder for spammers to harvest email addresses from Bugzilla, and also to enforce the user visibility restrictions that are implemented on some Bugzillas.)

=item limit (int)

Limit the number of users matched by the I<match> parameter. If value is greater than the system limit, the system limit will be used. This parameter is only used when user matching using the I<match> parameter is being performed.

=item group_ids (array)

I<group_ids> is an array of numeric ids for groups that a user can be in.
If this is specified, it limits the return value to users who are in any of the groups specified.

Added in Bugzilla 4.0

=item groups (array)

I<groups> is an array of names of groups that a user can be in.
If this is specified, it limits the return value to users who are in any of the groups specified.

Added in Bugzilla 4.0

=item include_disabled (boolean)

By default, when using the I<match> parameter, disabled users are excluded from the returned results unless their full username is identical to the match string. Setting I<include_disabled> to I<true> will include disabled users in the returned results even if their username doesn't fully match the input string.

Added in Bugzilla 4.0, default behaviour for I<match> was then changed to exclude disabled users.

=back

Returns:

A hash containing one item, I<users>, that is an array of hashes. Each hash describes a user, and has the following items:

=over 4

=item id

I<int> The unique integer ID that Bugzilla uses to represent this user. Even if the user's login name changes, this will not change.

=item real_name

I<string> The actual name of the user. May be blank.

=item email

I<string> The email address of the user.

=item name

I<string> The login name of the user. Note that in some situations this is different than their email.

=item can_login

I<boolean> A boolean value to indicate if the user can login into bugzilla.

=item email_enabled

I<boolean> A boolean value to indicate if bug-related mail will be sent to the user or not.

=item login_denied_text

I<string> A text field that holds the reason for disabling a user from logging into bugzilla, if empty then the user account is enabled. Otherwise it is disabled/closed.

=item groups

I<array> An array of group hashes the user is a member of. If the currently logged in user is querying his own account or is a member of the 'editusers' group, the array will contain all the groups that the user is a member of. Otherwise, the array will only contain groups that the logged in user can bless. Each hash describes the group and contains the following items:

Added in Bugzilla 4.4

=over 4

=item id

I<int> The group id

=item name

I<string> The name of the group

=item description

I<string> The description for the group

=back

=item saved_searches

I<array> An array of hashes, each of which represents a user's saved search and has the following keys:

Added in Bugzilla 4.4

=over 4

=item id

I<int> An integer id uniquely identifying the saved search.

=item name

I<string> The name of the saved search.

=item query

I<string> The CGI parameters for the saved search.

=back

=item saved_reports

I<array> An array of hashes, each of which represents a user's saved report and has the following keys:

Added in Bugzilla 4.4

=over 4

=item id

I<int> An integer id uniquely identifying the saved report.

=item name

I<string> The name of the saved report.

=item query

I<string> The CGI parameters for the saved report.

=back

Note: If you are not logged in to Bugzilla when you call this function, you will only be returned the id, name, and real_name items. If you are logged in and not in editusers group, you will only be returned the id, name, real_name, email, can_login, and groups items. The groups returned are filtered based on your permission to bless each group. The saved_searches and saved_reports items are only returned if you are querying your own account, even if you are in the editusers group.

=back

Errors:

=over 4

=item 51 - Bad Login Name or Group ID

You passed an invalid login name in the "names" array or a bad group ID in the group_ids argument.

=item 52 - Invalid Parameter

The value used must be an integer greater then zero.

=item 304 - Authorization Required

You are logged in, but you are not authorized to see one of the users you wanted to get information about by user id.

=item 505 - User Access By Id or User-Matching Denied

Logged-out users cannot use the "ids" or "match" arguments to this function.

=item 804 - Invalid Group Name

You passed a group name in the groups argument which either does not exist or you do not belong to it.

Added in Bugzilla 4.0.9 and 4.2.4, when it also became illegal to pass a group name you don't belong to.

=back

=head2 new

  my $user = BZ::Client::User->new( id => $id );

Creates a new instance with the given ID.

=head2 create

  my $id = BZ::Client::User->create( $client, \%params );

Creates a user account directly in Bugzilla, password and all. Instead of this, you should use L<offer_account_by_email> when possible, because that makes sure that the email address specified can actually receive an email. This function does not check that.

You must be logged in and have the I<editusers> privilege in order to call this function.

Params:

=over 4

=item email

I<email> (string) - The email address for the new user.

=item full_name

I<string> Optional - The user's full name. Will be set to empty if not specified.

=item password

I<string> Optional - The password for the new user account, in plain text. It will be stripped of leading and trailing whitespace. If blank or not specified, the newly created account will exist in Bugzilla, but will not be allowed to log in using DB authentication until a password is set either by the user (through resetting their password) or by the administrator.

=back

Returns, the numeric I<id> of the user that was created.

Errors:

The same as L<offer_account_by_email>. If a password is specified, the function may also throw:

=over 4

=item 502 - Password Too Short

The password specified is too short. (Usually, this means the password is under three characters.)

=item 503 - Password Too Long

Removed in Bugzilla 3.6


=head2 update

TODO

=head1 SEE ALSO

  L<BZ::Client>, L<BZ::Client::API>

