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
