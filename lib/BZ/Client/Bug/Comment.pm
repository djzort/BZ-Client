#!/bin/false
# PODNAME: BZ::Client::Bug::Comment
# ABSTRACT: Client side representation of an Comment on a Bug in Bugzilla

use strict;
use warnings 'all';

package BZ::Client::Bug::Comment;

use parent qw( BZ::Client::API );

# See https://www.bugzilla.org/docs/tip/en/html/api/Bugzilla/WebService/Bug.html
# These are in order as per the above

## functions

sub get {
    my($class, $client, $params) = @_;
    $client->log('debug', __PACKAGE__ . "::get: Asking for $params");
    my $result = $class->api_call($client, 'Bug.comments', $params);

    if (my $comments = $result->{comments}) {
        if (!$comments || 'HASH' ne ref($comments)) {
            $class->error($client,
                'Invalid reply by server, expected hash of comments.');
        }
        for my $id (keys %$comments) {
            $comments->{$id} = __PACKAGE__->new( %{$comments->{$id}} );
        }
    }

    if (my $bugs = $result->{bugs}) {
        if (!$bugs || 'HASH' ne ref($bugs)) {
            $class->error($client,
                'Invalid reply by server, expected array of bugs.');
        }
        for my $id (keys %$bugs) {
            $bugs->{$id} = [
                map { __PACKAGE__->new( %$_  ) } @{$bugs->{$id}->{comments}} ];
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
        $class->error($client, 'Invalid reply by server, expected comment ID.');
    }
    return $id
}

## rw methods

sub bug_id {
    my $self = shift;
    if (@_) {
        $self->{'bug_id'} = shift;
    }
    else {
        return $self->{'bug_id'}
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

sub is_private {
    my $self = shift;
    if (@_) {
        $self->{'is_private'} = shift;
    }
    else {
        return $self->{'is_private'}
    }
}

sub work_time {
    my $self = shift;
    if (@_) {
        $self->{'work_time'} = shift;
    }
    else {
        return $self->{'work_time'}
    }
}

## ro methods

sub id { my $self = shift; return $self->{'id'} }

sub attachment_id { my $self = shift; return $self->{'attachment_id'} }

sub count { my $self = shift; return $self->{'count'} }

sub text { my $self = shift; return $self->{'text'} }

sub creator { my $self = shift; return $self->{'creator'} || $self->{'author'} }

sub author { goto &creator }

sub creation_time { my $self = shift; return $self->{'creation_time'} }

sub time { goto &creation_time }


1;
