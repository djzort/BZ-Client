#!/bin/false
# PODNAME: BZ::Client::Bug::Attachment
# ABSTRACT: Client side representation of an Attachment to a Bug in Bugzilla

use strict;
use warnings 'all';

package BZ::Client::Bug::Attachment;

use parent qw( BZ::Client::API );

# See https://www.bugzilla.org/docs/tip/en/html/api/Bugzilla/WebService/Bug.html
# These are in order as per the above

## functions

sub get {
    my($class, $client, $params) = @_;
    $client->log('debug', __PACKAGE__ . "::get: Asking for $params");
    my $result = $class->api_call($client, 'Bug.attachments', $params);

    if (my $attachments = $result->{attachments}) {
        if (!$attachments || 'HASH' ne ref($attachments)) {
            $class->error($client,
                'Invalid reply by server, expected hash of attachments.');
        }
        for my $id (keys %$attachments) {
            $attachments->{$id} = __PACKAGE__
                                    ->new( %{$attachments->{$id}} );
        }
    }

    if (my $bugs = $result->{bugs}) {
        if (!$bugs || 'HASH' ne ref($bugs)) {
            $class->error($client,
                'Invalid reply by server, expected array of bugs.');
        }
        for my $id (keys %$bugs) {
            $bugs->{$id} = [
                map { __PACKAGE__->new( %$_  ) } @{$bugs->{$id}} ];
        }
    }

    $client->log('debug', __PACKAGE__ . '::get: Got ' . %$result);

    return wantarray ? %$result : $result
}

sub add {
    my($class, $client, $params) = @_;
    $client->log('debug', 'BZ::Client::Bug::add: Creating');
    my $result = $class->api_call($client, 'Bug.add_attachment', $params);
    my $id = $result->{'id'};
    if (!$id) {
        $class->error($client, 'Invalid reply by server, expected attachment ID.');
    }
    return $id
}

sub update {
    my($class, $client, $params) = @_;
    $client->log('debug', 'BZ::Client::Bug::add: Creating');
    my $result = $class->api_call($client, 'Bug.update_attachment', $params);
    my $attachments = $result->{'attachments'};
    if (!$attachments || 'ARRAY' ne ref($attachments)) {
        $class->error($client, 'Invalid reply by server, expected arayy of attachment changes.');
    }
    return $attachments
}

## rw methods

sub id {
    my $self = shift;
    if (@_) {
        $self->{'id'} = shift;
    }
    else {
        return $self->{'id'}
    }
}

sub data {
    my $self = shift;
    if (@_) {
        $self->{'data'} = shift;
    }
    else {
        return $self->{'data'}
    }
}

sub file_name {
    my $self = shift;
    if (@_) {
        $self->{'file_name'} = shift;
    }
    else {
        return $self->{'file_name'}
    }
}

sub description { goto &summary }

sub summary {
    my $self = shift;
    if (@_) {
        $self->{'summary'} = shift;
    }
    else {
        return $self->{'summary'} || $self->{'description'}
    }
}

sub content_type {
    my $self = shift;
    if (@_) {
        $self->{'content_type'} = shift;
    }
    else {
        return $self->{'content_type'}
    }
}

sub comment {
    my $self = shift;
    if (@_) {
        $self->{'comment'} = shift;
    }
    else {
        return $self->{'comment'}
    }
}

sub is_patch {
    my $self = shift;
    if (@_) {
        $self->{'is_patch'} = shift;
    }
    else {
        return $self->{'is_patch'}
    }
}

sub is_private {
    my $self = shift;
    if (@_) {
        $self->{'is_private'} = shift;
    }
    else {
        return $self->{'is_private'}
    }
}

sub is_url {
    my $self = shift;
    if (@_) {
        $self->{'is_url'} = shift;
    }
    else {
        return $self->{'is_url'}
    }
}

## ro methods

sub size { my $self = shift; return $self->{'size'} }

sub creation_time { my $self = shift; return $self->{'creation_time'} }

sub last_change_time { my $self = shift; return $self->{'last_change_time'} }

sub bug_id { my $self = shift; return $self->{'bug_id'} }

sub creator { my $self = shift; return $self->{'creator'} || $self->{'attacher'} }

sub attacher { goto &creator }

sub flags { my $self = shift; return $self->{'flags'} }

1;

__END__

=pod

=encoding utf8

=head1 SYNOPSIS

This class provides methods for accessing and managing attachments in Bugzilla. Instances
of this class are returned by L<BZ::Client::Bug::Attachment::get>.

  my $client = BZ::Client->new( url       => $url,
                                user      => $user,
                                password  => $password );

  my $comments = BZ::Client::Bug::Attachment->get( $client, $ids );

=head1 CLASS METHODS

This section lists the class methods, which are available in this module.

=head2 get

It allows you to get data about attachments, given a list of bugs and/or attachment ids.

Note: Private attachments will only be returned if you are in the insidergroup or if you are the submitter of the attachment.

Actual Bugzilla API method is "attachments".

Added in Bugzilla 3.6.

=head3 Parameters

Note: At least one of I<ids> or I<attachment_ids> is required.

In addition to the parameters below, this method also accepts the standard include_fields and exclude_fields arguments.

=over 4

=item ids

I<ids> (array) - An array that can contain both bug IDs and bug aliases. All of the attachments (that are visible to you) will be returned for the specified bugs.

=item attachment_ids

I<attachment_ids> (array) - An array of integer attachment_ids.

=back

=head3 Returns

A hash containing two items is returned:

=over 4

=item bugs

This is used for bugs specified in I<ids>. This is a hash, where the keys are the numeric ids of the bugs and the value is an array of attachment obects.

Note that any individual bug will only be returned once, so if you specify an id multiple times in ids, it will still only be returned once.

=item attachments

Each individual attachment requested in attachment_ids is returned here, in a hash where the numeric attachment_id is the key, and the value is the attachment object.

=back

The return value looks like this:

 {
     bugs => {
         1345 => [
             { (attachment) },
             { (attachment) }
         ],
         9874 => [
             { (attachment) },
             { (attachment) }
         ],
     },

     attachments => {
         234 => { (attachment) },
         123 => { (attachment) },
     }
 }

A "attachment" as shown above is an object instance of this package.

=head3 Errors

=over 4

=item 100 - Invalid Bug Alias

If you specified an alias and there is no bug with that alias.

=item 101 - Invalid Bug ID

The bug_id you specified doesn't exist in the database.

=item 102 - Access Denied

You do not have access to the I<bug_id> you specified.

=item 304 - Auth Failure, Attachment is Private

You specified the id of a private attachment in the L<attachment_ids> argument, and you are not in the "insider group" that can see private attachments.

=back

=head2 add

This allows you to add an attachment to a bug in Bugzilla.

Actual Bugzilla API method is "add_attachment".

Added in Bugzilla 4.0.

The return value has changed in Bugzilla 4.4.

=head3 Parameters

An instance of this package or a hash containing:

=over 4

=item ids

I<ids> (array) Required - An array of ints and/or strings--the ids or aliases of bugs that you want to add this attachment to. The same attachment and comment will be added to all these bugs.

=item data

I<data> (string or base64) Required - The content of the attachment. If the content of the attachment is not ASCII text, you must encode it in base64 and declare it as the C<base64> type.

=item file_name

I<file_name> (string) Required - The "file name" that will be displayed in the UI for this attachment.

=item summary

I<summary> (string) Required - A short string describing the attachment.

=item comment

I<comment> (string) - A comment to add along with this attachment.

=item is_patch

I<is_patch> (boolean) - True if Bugzilla should treat this attachment as a patch. If you specify this, you do not need to specify a L<content_type>. The L<content_type> of the attachment will be forced to C<text/plain>.

Defaults to False if not specified.

=item is_private

I<is_private> (boolean) - True if the attachment should be private (restricted to the "insidergroup"), False if the attachment should be public.

Defaults to False if not specified.

=item flags

An array of hashes with flags to add to the attachment. to create a flag, at least the status and the type_id or name must be provided. An optional requestee can be passed if the flag type is requestable to a specific user.

=over 4

=item name

I<name> (string) - The name of the flag type.

=item type_id

I<type_id> (int) - THe internal flag type id.

=item status

I<status> (string) - The flags new status  (i.e. "?", "+", "-" or "X" to clear a flag).

=item requestee

I<requestee> (string) - The login of the requestee if the flag type is requestable to a specific user.

=back

=back

=head3 Returns

An array of the attachment id's created.

=head3 Errors

=over

=item 100 - Invalid Bug Alias

If you specified an alias and there is no bug with that alias.

=item 101 - Invalid Bug ID

The bug_id you specified doesn't exist in the database.

=item 102 - Access Denied

You do not have access to the I<bug_id> you specified.

=item 129 - Flag Status Invalid

The flag status is invalid.

=item 130 - Flag Modification Denied

You tried to request, grant, or deny a flag but only a user with the required permissions may make the change.

=item 131 - Flag not Requestable from Specific Person

You can't ask a specific person for the flag.

=item 133 - Flag Type not Unique

The flag type specified matches several flag types. You must specify the type id value to update or add a flag.

=item 134 - Inactive Flag Type

The flag type is inactive and cannot be used to create new flags.

=item 600 - Attachment Too Large

You tried to attach a file that was larger than Bugzilla will accept.

=item 601 - Invalid MIME Type

You specified a L<content_type> argument that was blank, not a valid MIME type, or not a MIME type that Bugzilla accepts for attachments.

=item 603 - File Name Not Specified

You did not specify a valid for the L<file_name> argument.

=item 604 - Summary Required

You did not specify a value for the L<summary> argument.

=item 606 - Empty Data

You set the "data" field to an empty string.

=back

=head2 render

Returns the HTML rendering of the provided comment text.

Actual Bugzilla API method is "render_comment".

Note: this all takes place on your Bugzilla server.

Added in Bugzilla 5.0.

=head3 Parameters

=over 4

=item text

I<text> (string) Required - Text comment text to render

=item id

I<id> The ID of the bug to render the comment against.

=back

=head3 Returns

The HTML rendering

=head3 Errors

=over 4

=item 100 - Invalid Bug Alias

If you specified an alias and there is no bug with that alias.

=item 101 - Invalid Bug ID

The bug_id you specified doesn't exist in the database.

=item 102 - Access Denied

You do not have access to the I<bug_id> you specified.

=back

=cut

=head2 update

This allows you to update attachment metadata in Bugzilla.

Actual Bugzilla API method is "update_attachments".

Added in Bugzilla 5.0.

=head3 Parameters

=over 4

=item ids

I<ids> (array) - An array that can contain both bug IDs and bug aliases. All of the attachments (that are visible to you) will be returned for the specified bugs.

=item file_name

I<file_name> (string) Required - The "file name" that will be displayed in the UI for this attachment.

=item summary

I<summary> (string) Required - A short string describing the attachment.

=item comment

I<comment> (string) - A comment to add along with this attachment.

=item content_type

I<content_type> (string) -  The MIME type of the attachment, like text/plain or image/png.

=item is_patch

I<is_patch> (boolean) - True if Bugzilla should treat this attachment as a patch. If you specify this, you do not need to specify a L<content_type>. The L<content_type> of the attachment will be forced to C<text/plain>.

=item is_private

I<is_private> (boolean) - True if the attachment should be private (restricted to the "insidergroup"), False if the attachment should be public.

=item is_obsolete

I<is_obsolete> (boolean) - True if the attachment is obsolete, False otherwise.

=item flags

An array of hashes with flags to add to the attachment. to create a flag, at least the status and the type_id or name must be provided. An optional requestee can be passed if the flag type is requestable to a specific user.

=over 4

=item name

I<name> (string) - The name of the flag type.

=item type_id

I<type_id> (int) - THe internal flag type id.

=item status

I<status> (string) - The flags new status  (i.e. "?", "+", "-" or "X" to clear a flag).

=item requestee

I<requestee> (string) - The login of the requestee if the flag type is requestable to a specific user.

=item id

I<id> (int) - Use C<id> to specify the flag to be updated. You will need to specify the C<id> if more than one flag is set of the same name.

=item new

I<new> (boolean) - Set to true if you specifically want a new flag to be created.

=back

=back

=head3 Returns

An array of hashes with the following fields:

=over 4

=item id

I<id> (int) The id of the attachment that was updated.

=item last_change_time

I<last_change_time> (dateTime) - The exact time that this update was done at, for this attachment. If no update was done (that is, no fields had their values changed and no comment was added) then this will instead be the last time the attachment was updated.

=item changes

I<changes> (hash) - The changes that were actually done on this bug. The keys are the names of the fields that were changed, and the values are a hash with two keys:

=over 4

=item added

I<added> (string) - The values that were added to this field. possibly a comma-and-space-separated list if multiple values were added.

=item removed

I<removed> (string) - The values that were removed from this field.

=back

=back

Here is an example of what a return value might look like:

  [
    {
      id    => 123,
      last_change_time => '2010-01-01T12:34:56',
      changes => {
        summary => {
          removed => 'Sample ptach',
          added   => 'Sample patch'
        },
        is_obsolete => {
          removed => '0',
          added   => '1',
        }
      },
    }
  ]

=head3 Errors

=item 100 - Invalid Bug Alias

If you specified an alias and there is no bug with that alias.

=item 101 - Invalid Bug ID

The bug_id you specified doesn't exist in the database.

=item 102 - Access Denied

You do not have access to the I<bug_id> you specified.

=item 129 - Flag Status Invalid

The flag status is invalid.

=item 130 - Flag Modification Denied

You tried to request, grant, or deny a flag but only a user with the required permissions may make the change.

=item 131 - Flag not Requestable from Specific Person

You can't ask a specific person for the flag.

=item 133 - Flag Type not Unique

The flag type specified matches several flag types. You must specify the type id value to update or add a flag.

=item 134 - Inactive Flag Type

The flag type is inactive and cannot be used to create new flags.

=item 601 - Invalid MIME Type

You specified a L<content_type> argument that was blank, not a valid MIME type, or not a MIME type that Bugzilla accepts for attachments.

=item 603 - File Name Not Specified

You did not specify a valid for the L<file_name> argument.

=item 604 - Summary Required

You did not specify a value for the L<summary> argument.

=back


=head2 new

  my $comment = BZ::Client::Bug::Comment->new(
                                          id         => $bug_id,
                                          comment    => $comment,
                                          is_private => 1 || 0,
                                          work_time  => 3.5
                                        );

Creates a new instance with the given details. Doesn't actually touch
your Bugzilla Server - see L<add> for that.

=head1 INSTANCE METHODS

=cut
