#!/bin/false
# PODNAME: BZ::Client::Bug
# ABSTRACT: Client side representation of a bug in Bugzilla

use strict;
use warnings 'all';

package BZ::Client::Bug;

use parent qw( BZ::Client::API );

# See https://www.bugzilla.org/docs/tip/en/html/api/Bugzilla/WebService/Bug.html
# These are in order as per the above

## functions

sub fields {
    my($class, $client, $params) = @_;
    $client->log('debug', 'BZ::Client::Bug::fields: Retrieving');
    my $result = $class->api_call($client, 'Bug.fields', $params);
    my $fields = $result->{'fields'};
    if (!$fields || 'ARRAY' ne ref($fields)) {
        $class->error($client, 'Invalid reply by server, expected array of fields.');
    }
    $client->log('debug', 'BZ::Client::Bug::fields: Got ' . scalar @$fields);
    return wantarray ? @$fields : $fields
}

sub legal_values {
    my($class, $client, $field) = @_;
    $client->log('debug', __PACKAGE__ . "::legal_values: Asking for $field");
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
    my($class, $client, $params) = @_;
    $client->log('debug', 'BZ::Client::Bug::get: Asking');
    $params->{'permissive'} = BZ::Client::XMLRPC::boolean::TRUE()
        if $params->{'permissive'};
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

sub history {
    my($class, $client, $params) = @_;
    $client->log('debug', 'BZ::Client::Bug::history: Retrieving');
    my $result = $class->api_call($client, 'Bug.history', $params);
    my $bugs = $result->{'bugs'};
    if (!$bugs || 'ARRAY' ne ref($bugs)) {
        $class->error($client, 'Invalid reply by server, expected array of bug changes.');
    }
    $client->log('debug', 'BZ::Client::Bug::history: Got ' . scalar @$bugs);
    return wantarray ? @$bugs : $bugs
}

sub possible_duplicates {
    my($class, $client, $params) = @_;
    $client->log('debug', __PACKAGE__ . '::possible_duplicates: Asking');
    my $result = $class->api_call($client, 'Bug.possible_duplicates', $params);
    my $bugs = $result->{'bugs'};
    if (!$bugs  ||  'ARRAY' ne ref($bugs)) {
        $class->error($client, 'Invalid reply by server, expected array of bugs.');
    }
    my @result;
    for my $bug (@$bugs) {
        push(@result, __PACKAGE__->new(%$bug));
    }
    $client->log('debug', __PACKAGE__ . '::possible_duplicates: Got ' . scalar(@result));
    return wantarray ? @result : \@result
}

sub search {
    my($class, $client, $params) = @_;
    $client->log('debug', __PACKAGE__ . '::search: Searching');
    my $result = $class->api_call($client, 'Bug.search', $params);
    my $bugs = $result->{'bugs'};
    if (!$bugs || 'ARRAY' ne ref($bugs)) {
        $class->error($client, 'Invalid reply by server, expected array of bugs.');
    }
    my @result;
    for my $bug (@$bugs) {
        push(@result, __PACKAGE__->new(%$bug));
    }
    $client->log('debug', __PACKAGE__ . '::search: Found ' . join(',',@result));
    return wantarray ? @result : \@result
}

sub create {
    my($class, $client, $params) = @_;
    $client->log('debug', __PACKAGE__ . '::create: Creating');
    my $result = $class->api_call($client, 'Bug.create', $params);
    my $id = $result->{'id'};
    if (!$id) {
        $class->error($client, 'Invalid reply by server, expected bug ID.');
    }
    return $id
}

sub update {
    my($class, $client, $params) = @_;
    $client->log('debug', __PACKAGE__ . '::update: Updating');
    my $result = $class->api_call($client, 'Bug.update', $params);
    my $bugs = $result->{'bugs'};
    if (!$bugs || 'ARRAY' ne ref($bugs)) {
        $class->error($client, 'Invalid reply by server, expected array of bug details.');
    }
    return wantarray ? @$bugs : $bugs
}

sub update_see_also {
    my($class, $client, $params) = @_;
    $client->log('debug', __PACKAGE__ . '::update_see_also: Updating See-Also');
    my $result = $class->api_call($client, 'Bug.update_see_also', $params);
    my $changes = $result->{'changes'};
    if (!$changes || 'HASH' ne ref($changes)) {
        $class->error($client, 'Invalid reply by server, expected hash of changed bug details.');
    }
    return wantarray ? %$changes : $changes
}

sub update_tags {
    my($class, $client, $params) = @_;
    $client->log('debug', __PACKAGE__ . '::update_tags: Updating Tags');
    my $result = $class->api_call($client, 'Bug.update_tags', $params);
    my $changes = $result->{'changes'};
    if (!$changes || 'HASH' ne ref($changes)) {
        $class->error($client, 'Invalid reply by server, expected hash of changed bug details.');
    }
    return wantarray ? %$changes : $changes
}

## methods

sub id {
    my $self = shift;
    if (@_) {
        $self->{'id'} = shift;
    }
    else {
        return $self->{'id'}
    }
}

sub alias {
    my $self = shift;
    if (@_) {
        my $alias = shift;
        if (ref $alias eq 'ARRAY' && @$a) {
            $self->{'alias'} = $alias->[0];
        }
        if (not ref $alias) {
            $self->{'alias'} = $alias;
        }
        # silently ignore anything else
    }
    else {

        return '' unless defined $self->{'alias'};

        # long form so its clear what is going on.
        if (ref $self->{'alias'}) {
            if (ref $self->{'alias'} eq 'ARRAY'
                and @{$self->{'alias'}}) {
                return $self->{'alias'}->[0];
            }
            return ''
        }

        # fall back
        return $self->{'alias'}
    }
}

sub assigned_to {
    my $self = shift;
    if (@_) {
        $self->{'assigned_to'} = shift;
    }
    else {
        return $self->{'assigned_to'}
    }
}

sub component {
    my $self = shift;
    if (@_) {
        $self->{'component'} = shift;
    } e
    lse {
        return $self->{'component'}
    }
}

sub creation_time {
    my $self = shift;
    if (@_) {
        $self->{'creation_time'} = shift;
    }
    else {
        return $self->{'creation_time'}
    }
}

sub dupe_of {
    my $self = shift;
    if (@_) {
        $self->{'dupe_of'} = shift;
    }
    else {
        return $self->{'dupe_of'}
    }
}

sub internals {
    my $self = shift;
    if (@_) {
        $self->{'internals'} = shift;
    }
    else {
        return $self->{'internals'}
    }
}

sub is_open {
    my $self = shift;
    if (@_) {
        $self->{'is_open'} = shift;
    }
    else {
        return $self->{'is_open'}
    }
}

sub last_change_time {
    my $self = shift;
    if (@_) {
        $self->{'last_change_time'} = shift;
    }
    else {
        return $self->{'last_change_time'}
    }
}

sub priority {
    my $self = shift;
    if (@_) {
        $self->{'priority'} = shift;
    }
    else {
        return $self->{'priority'}
    }
}

sub product {
    my $self = shift;
    if (@_) {
        $self->{'product'} = shift;
    }
    else {
        return $self->{'product'}
    }
}

sub resolution {
    my $self = shift;
    if (@_) {
        $self->{'resolution'} = shift;
    }
    else {
        return $self->{'resolution'}
    }
}

sub severity {
    my $self = shift;
    if (@_) {
        $self->{'severity'} = shift;
    }
    else {
        return $self->{'severity'}
    }
}

sub status {
    my $self = shift;
    if (@_) {
        $self->{'status'} = shift;
    }
    else {
        return $self->{'status'}
    }
}

sub summary {
    my $self = shift;
    if (@_) {
        $self->{'summary'} = shift;
    }
    else {
        return $self->{'summary'}
    }
}

1;

__END__

=pod

=encoding utf8

=head1 SYNOPSIS

This class provides methods for accessing and managing bugs in Bugzilla.

  my $client = BZ::Client->new( url      => $url,
                                user     => $user,
                                password => $password );

  my $bugs = BZ::Client::Bug->get( $client, $ids );

=head1 COMMON PARAMETERS

Many Webservice methods take similar arguments. Instead of re-writing the documentation for each method, we document the parameters here, once, and then refer back to this documentation from the individual methods where these parameters are used.

=head2 Limiting What Fields Are Returned

Many methods return an array of structs with various fields in the structs.
(For example, L<get> in L<BZ::Client::Bug> returns a list of bugs that have fields like
L<id>, L<summary>, L<creation_time>, etc.)

These parameters allow you to limit what fields are present in the structs, to possibly improve performance or save some bandwidth.

=head3 include_fields

I<include_fields> (array) - An array of strings, representing the (case-sensitive) names of fields in the return value. Only the fields specified in this hash will be returned, the rest will not be included.

If you specify an empty array, then this function will return empty hashes.

Invalid field names are ignored.

Example:

 BZ::Client::User->get( $client,
    { ids => [1], include_fields => ['id', 'name'] })

would return something like:

 [{ id => 1, name => 'user@domain.com' }]

=head3 exclude_fields

I<exclude_fields> (array) - An array of strings, representing the (case-sensitive) names of fields in the return value. The fields specified will not be included in the returned hashes.

If you specify all the fields, then this function will return empty hashes.

Some RPC calls support specifying sub fields. If an RPC call states that it support sub field restrictions, you can restrict what information is returned within the first field. For example, if you call Product.get with an include_fields of components.name, then only the component name would be returned (and nothing else). You can include the main field, and exclude a sub field.

Invalid field names are ignored.

Specifying fields here overrides L<include_fields>, so if you specify a field in both, it will be excluded, not included.

Example:

 BZ::Client::User->get( $client,
    { ids => [1], exclude_fields => ['name'] })

would return something like:

 [{ id => 1, real_name => 'John Smith' }]

=head3 shortcuts

There are several shortcut identifiers to ask for only certain groups of fields to be returned or excluded.

=over 4

=item _all

All possible fields are returned if _all is specified in include_fields.

=item _default

These fields are returned if include_fields is empty or _default is specified. All fields described in the documentation are returned by default unless specified otherwise.

=item _extra

These fields are not returned by default and need to be manually specified in include_fields either by field name, or using _extra.

=item _custom

Only custom fields are returned if _custom is specified in include_fields. This is normally specific to bug objects and not relevant for other returned objects.

=back

Example:

 BZ::Client::User->get( $client,
    { ids => [1], include_fields => ['_all'] })

=head1 UTILITY FUNCTIONS

This section lists the utility functions provided by this module.

These deal with bug-related information, but not bugs directly.

=head2 fields

  $fields = BZ::Client::Bug->fields( $client, $params )
  @fields = BZ::Client::Bug->fields( $client, $params )

Get information about valid bug fields, including the lists of legal values for each field.

Added in Bugzilla 3.6

=head3 Parameters

You can pass either field ids or field names.

Note: If neither ids nor names is specified, then all non-obsolete fields will be returned.

=over 4

=item ids

I<ids> (array) - An array of integer field ids

=item names

I<names> (array) - An array of strings representing field names.

=back

In addition to the parameters above, this method also accepts the standard I<include_fields> and I<exclude_fields> arguments.

=head3 Returns

Returns an array or an arrayref of hashes, containing the following keys:

=over 4

=item id

I<id> (int) - An integer id uniquely identifying this field in this installation only.

=item type

I<type> (int) The number of the fieldtype. The following values are defined:

=over 4

=item 0 Unknown

=item 1 Free Text

=item 2 Drop Down

=item 3 Multiple-Selection Box

=item 4 Large Text Box

=item 5 Date/Time

=item 6 Bug ID

=item 7 Bug URLs ("See Also")

=back

=item is_custom

I<is_custom> (boolean) True when this is a custom field, false otherwise.

=item name

I<name> (string) The internal name of this field. This is a unique identifier for this field. If this is not a custom field, then this name will be the same across all Bugzilla installations.

=item display_name

I<display_name>  (string) The name of the field, as it is shown in the user interface.

=item is_mandatory

I<is_mandatory> (boolean) True if the field must have a value when filing new bugs. Also, mandatory fields cannot have their value cleared when updating bugs.

This return value was added in Bugzilla 4.0.

=item is_on_bug_entry

I<is_on_bug_entry> (boolean) For custom fields, this is true if the field is shown when you enter a new bug. For standard fields, this is currently always false, even if the field shows up when entering a bug. (To know whether or not a standard field is valid on bug entry, see L</create>.)

=item visibility_field

I<visibility_field> (string) The name of a field that controls the visibility of this field in the user interface. This field only appears in the user interface when the named field is equal to one of the values in visibility_values. Can be null.

=item visibility_values

I<visibility_values> (array) of strings This field is only shown when visibility_field matches one of these values. When visibility_field is null, then this is an empty array.

=item value_field

I<value_field> (string) The name of the field that controls whether or not particular values of the field are shown in the user interface. Can be null.

=item values

This is an array of hashes, representing the legal values for select-type (drop-down and multiple-selection) fields. This is also populated for the component, version, target_milestone, and keywords fields, but not for the product field (you must use L<BZ::Client::Product/get_accessible_products> for that).

For fields that aren't select-type fields, this will simply be an empty array.

Each hash has the following keys:

=over 4

=item name

I<name> (string) The actual value--this is what you would specify for this field in "create", etc.

=item sort_key

I<sort_key> (int) Values, when displayed in a list, are sorted first by this integer and then secondly by their name.

=item sortkey

DEPRECATED - Use I<sort_key> instead.

Renamed to sort_key in Bugzilla 4.2.

=item visibility_values

If L</value_field> is defined for this field, then this value is only shown if the L</value_field> is set to one of the values listed in this array.

Note that for per-product fields, L</value_field> is set to 'product' and L</visibility_values> will reflect which product(s) this value appears in.

=item is_active

I<is_active> (boolean) This value is defined only for certain product specific fields such as version, target_milestone or component.

When true, the value is active, otherwise the value is not active.

Added in Bugzilla 4.4.

=item description

I<description> (string) The description of the value. This item is only included for the keywords field.

=item is_open

I<is_open> (boolean) For L</bug_status> values, determines whether this status specifies that the bug is "open" (true) or "closed" (false). This item is only included for the L</bug_status> field.

=item can_change_to

For L</bug_status> values, this is an array of hashes that determines which statuses you can transition to from this status. (This item is only included for the L</bug_status> field.)

Each hash contains the following items:

=over 4

=item name

The name of the new status

=item comment_required

I<comment_required> (boolean) True if a comment is required when you change a bug into this status using this transition.

=back

=back

=back

Errors:

=over 4

=item 51 - Invalid Field Name or ID

You specified an invalid field name or id.

=back

=head2 legal_values

  $values = BZ::Client::Bug->legal_values( $client, $field )
  @values = BZ::Client::Bug->legal_values( $client, $field )

Tells you what values are allowed for a particular field.

Note: This is deprecated in Bugzilla, use L</fields> instead.

=head3 Parameters

=over 4

=item field

The name of the field you want information about. This should be the same as the name you would use in L</create>, below.

=item product_id

If you're picking a product-specific field, you have to specify the id of the product you want the values for.

=back

=head3 Returns

=over 4

=item values

An array or arrayref of strings: the legal values for this field. The values will be sorted as they normally would be in Bugzilla.

=back

=head3 Errors

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

  $bugs = BZ::Client::Bug->get( $client, \%params );
  @bugs = BZ::Client::Bug->get( $client, \%params );

Gets information about particular bugs in the database.

=head3 Parameters

=over 4

=item ids

An array of numbers and strings.

If an element in the array is entirely numeric, it represents a bug_id from the Bugzilla database to fetch. If it contains any non-numeric characters, it is considered to be a bug alias instead, and the bug with that alias will be loaded.

=item permissive

I<permissive> (boolean) Normally, if you request any inaccessible or invalid bug ids, will throw an error.

If this parameter is True, instead of throwing an error we return an array of hashes with a I<id>, I<faultString> and I<faultCode> for each bug that fails, and return normal information for the other bugs that were accessible.

Note: marked as B<EXPERIMENTAL> in Bugzilla 4.4

Added in Bugzilla 3.4.

=back

=head3 Returns

An array or arrayref of bug instance objects with the given ID's.

See L</INSTANCE METHODS> for how to use them.

FIXME missing the I<faults> return values (added in 3.4)

=head3 Errors

=over 4

=item 100 - Invalid Bug Alias

If you specified an alias and there is no bug with that alias.

=item 101 - Invalid Bug ID

The bug_id you specified doesn't exist in the database.

=item 102 - Access Denied

You do not have access to the bug_id you specified.

=back

=head2 search

  my $bugs = BZ::Client::Bug->search( $client, \%params );
  my @bugs = BZ::Client::Bug->search( $client, \%params );

Searches for bugs matching the given parameters.

Returns an array or arrayref of bug instance objects with the given ID's.

See L<INSTANCE METHODS> for how to use them.

=head2 history

  $history = BZ::Client::Bug->history( $client, \%params );
  @history = BZ::Client::Bug->history( $client, \%params );

Gets the history of changes for particular bugs in the database.

Added in Bugzilla 3.4.

=head3 Parameters

=over 4

=item ids

An array of numbers and strings.

If an element in the array is entirely numeric, it represents a bug_id from the Bugzilla database to fetch. If it contains any non-numeric characters, it is considered to be a bug alias instead, and the data bug with that alias will be loaded.

=back

=head3 Returns

An array or arrayref of hashes, containing the following keys:

=over 4

=item id

I<id> (int) The numeric id of the bug

=item alias

I<alias> (array) The alias of this bug. If there is no alias, this will be undef.

=item history

An array of hashes, each hash having the following keys:

=over 4

=item when

I<when> (dateTime) The date the bug activity/change happened.

=item who

I<who> (string) The login name of the user who performed the bug change.

=item changes

An array of hashes which contain all the changes that happened to the bug at this time (as specified by when). Each hash contains the following items:

=over 4

=item field_name

I<field_name> (string) The name of the bug field that has changed.

=item removed

I<removed> (string) The previous value of the bug field which has been deleted by the change.

=item added

I<added> (string) The new value of the bug field which has been added by the change.

=item attachment_id

I<attachment_id> (int) The id of the attachment that was changed. This only appears if the change was to an attachment, otherwise attachment_id will not be present in this hash.

=back

=back

=back

=head3 Errors

The same as L</get>.

=head2 possible_duplicates

  $bugs = BZ::Client::Bug->possible_duplicates( $client, \%params );
  @bugs = BZ::Client::Bug->possible_duplicates( $client, \%params );

Allows a user to find possible duplicate bugs based on a set of keywords such as a user may use as a bug summary. Optionally the search can be narrowed down to specific products.

Added in Bugzilla 4.0.

=head3 Parameters

=over 4

=item summary

I<summary> (string) A string of keywords defining the type of bug you are trying to report. B<Required>.

=item product

I<product> (array) One or more product names to narrow the duplicate search to. If omitted, all bugs are searched.

=back

=head3 Returns

The same as L</get>.

Note that you will only be returned information about bugs that you can see. Bugs that you can't see will be entirely excluded from the results. So, if you want to see private bugs, you will have to first log in and then call this method.

=head3 Errors

=over 4

=item 50 - Param Required

You must specify a value for I<summary> containing a string of keywords to search for duplicates.

=back

=head1 FUNCTIONS FOR CREATING AND MODIFYING BUGS

This section lists the class methods pertaining to the creation and modification of bugs.

Listed here in order of what you most likely want to do... maybe?

=head2 create

  my $id = BZ::Client::Bug->create( $client, \%params );

Creates a new bug in your Bugzilla server and returns the bug ID.

=head2 update

  my $id = BZ::Client::Bug->update( $client, \%params );

Allows you to update the fields of a bug.

(Your Bugzilla server may automatically sends emails out about the changes)

FIXME more details needed

=head2 update_see_also

  $changes = BZ::Client::Bug->update_see_also( $client, \%params );
  @changes = BZ::Client::Bug->update_see_also( $client, \%params );

Adds or removes URLs for the I<See Also> field on bugs. These URLs must point to some valid bug in some Bugzilla installation or in Launchpad.

This is marked as B<EXPERIMENTAL> in Bugzilla 4.4

Added in Bugzilla 3.4.

=head3 Parameters

=over 4

=item ids

An array of integers or strings. The IDs or aliases of bugs that you want to modify.

=item add

Array of strings. URLs to Bugzilla bugs. These URLs will be added to the I<See Also> field.

If the URLs don't start with C<http://> or C<https://>, it will be assumed that C<http://> should be added to the beginning of the string.

It is safe to specify URLs that are already in the I<See Also> field on a bug as they will just be silently ignored.

=item remove

An array of strings. These URLs will be removed from the I<See Also> field. You must specify the full URL that you want removed. However, matching is done case-insensitively, so you don't have to specify the URL in exact case, if you don't want to.

If you specify a URL that is not in the I<See Also> field of a particular bug, it will just be silently ignored. Invaild URLs are currently silently ignored, though this may change in some future version of Bugzilla.

=back

NOTE: If you specify the same URL in both I<add> and I<remove>, it will be added. (That is, I<add> overrides I<remove>.)

=head3 Returns

A hash or hashref where the keys are numeric bug ids and the contents are a hash with one key, I<see_also>.

I<see_also> points to a hash, which contains two keys, I<added> and I<removed>.

These are arrays of strings, representing the actual changes that were made to the bug.

Here's a diagram of what the return value looks like for updating bug ids 1 and 2:

    {
        1 => {
            see_also => {
                added   => [(an array of bug URLs)],
                removed => [(an array of bug URLs)],
            }
        },
        2 => {
            see_also => {
                added   => [(an array of bug URLs)],
                removed => [(an array of bug URLs)],
            }
        }
    }

This return value allows you to tell what this method actually did.

It is in this format to be compatible with the return value of a future L<\update> method.

=head3 Errors

This method can throw all of the errors that L</get> throws, plus:

=over 4

=item 109 - Bug Edit Denied

You did not have the necessary rights to edit the bug.

=item 112 - Invalid Bug URL

One of the URLs you provided did not look like a valid bug URL.

=item 115 - See Also Edit Denied

You did not have the necessary rights to edit the See Also field for this bug.

Before Bugzilla 3.6, error 115 had a generic error code of 32000.

=back

=head2 update_tags

  $changes = BZ::Client::Bug->update_tags( $client, \%params );
  @changes = BZ::Client::Bug->update_tags( $client, \%params );

Adds or removes tags on bugs.

This is marked as B<UNSTABLE> in Bugzilla 4.4

Added in Bugzilla 4.4.

=head3 Parameters

=over 4

=item ids

An array of ints and/or strings--the ids or aliases of bugs that you want to add or remove tags to. All the tags will be added or removed to all these bugs.

=item tags

A hash representing tags to be added and/or removed. The hash has the following fields:

=over 4

=item add

An array of strings representing tag names to be added to the bugs.

It is safe to specify tags that are already associated with the bugs as they will just be silently ignored.

=item remove

An array of strings representing tag names to be removed from the bugs.

It is safe to specify tags that are not associated with any bugs as they will just be silently ignored.

=back

=back

=head3 Returns

A hash or hashref where the keys are numeric bug ids and the contents are a hash with one key, I<tags>.

I<tags> points to a hash, which contains two keys, I<added> and I<removed>.

These are arrays of strings, representing the actual changes that were made to the bug.

Here's a diagram of what the return value looks like for updating bug ids 1 and 2:

    {
        1 => {
            tags => {
                added   => [(an array of tags)],
                removed => [(an array of tags)],
            }
        },
        2 => {
            tags => {
                added   => [(an array of tags)],
                removed => [(an array of tags)],
            }
        }
    }

This return value allows you to tell what this method actually did.

=head3 Errors

This method can throw all of the errors that L</get> throws.

=head2 new

  my $bug = BZ::Client::Bug->new( id => $id );

Creates a new bug object instance with the given ID.

B<Note:> Doesn't actually touch your bugzilla server.

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

=head1 ATTACHMENTS & COMMENTS

These are implemented by other modules.

See L<BZ::Client::Bug::Attachment> and L<BZ::Client::Bug::Comment>

=head1 TODO

Bugzilla 5.0. introduced the C<search_comment_tags> and C<update_comment_tags> methods,
these are yet to be specifically implemented.

=head1 SEE ALSO

L<BZ::Client>, L<BZ::Client::Bug::Attachment>, L<BZ::Client::Bug::Comment>

L<BZ::Client::API>, L<Bugzilla API|https://www.bugzilla.org/docs/tip/en/html/api/Bugzilla/WebService/Bug.html>
