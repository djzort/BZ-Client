#!/bin/false
# PODNAME: BZ::Client::Product
# ABSTRACT: Client side representation of a product in Bugzilla

use strict;
use warnings 'all';

package BZ::Client::Product;

use parent qw( BZ::Client::API );

# See https://www.bugzilla.org/docs/tip/en/html/api/Bugzilla/WebService/Product.html

## functions

# convenience function
sub _get_list {
    my($class, $methodName, $client) = @_;
    my $result = $class->api_call($client, $methodName);
    my $ids = $result->{'ids'};
    if (!$ids || 'ARRAY' ne ref($ids)) {
        $class->error($client, 'Invalid reply by server, expected array of ids.');
    }
    return $ids
}

sub get_selectable_products {
    my($class, $client) = @_;
    $client->log('debug', __PACKAGE__ . '::get_selectable_products: Asking');
    my $result = $class->_get_list('Product.get_selectable_products', $client);
    $client->log('debug', __PACKAGE__ . '::get_selectable_products: Got ' . @$result);
    return wantarray ? @$result : $result
}

sub get_enterable_products {
    my($class, $client) = @_;
    $client->log('debug', __PACKAGE__ . '::get_enterable_products: Asking');
    my $result = $class->_get_list('Product.get_enterable_products', $client);
    $client->log('debug', __PACKAGE__ . '::get_enterable_products: Got ' . @$result);
    return wantarray ? @$result : $result
}

sub get_accessible_products {
    my($class, $client) = @_;
    $client->log('debug', __PACKAGE__ . '::get_accessible_products: Asking');
    my $result = $class->_get_list('Product.get_accessible_products', $client);
    $client->log('debug', __PACKAGE__ . '::get_accessible_products: Got ' . @$result);
    return wantarray ? @$result : $result
}

# do everything in one place
sub _get {
    my ($class, $client, $result) = @_;
    my $products = $result->{'products'};
    if (!$products || 'ARRAY' ne ref($products)) {
        $class->error($client, 'Invalid reply by server, expected array of products.');
    }
    my @result;
    for my $product (@$products) {
        push(@result, $class->new(
                id          => $product->{'id'},
                name        => $product->{'name'},
                description => $product->{'description'},
                internals   => $product->{'internals'})
            );
    }
    return wantarray @result : \@result
}

sub get_products {
    my($class, $client, $params) = @_;
    my $result = $class->api_call($client, 'Product.get_products', $params);
    return $class->_get($client, $result)
}

sub get {
    my($class, $client, $params) = @_;
    my $result = $class->api_call($client, 'Product.get', $params);
    return $class->_get($client, $result)
}

## methods

sub id {
    my $self = shift;
    if (@_) {
        $self->{'id'} = shift;
    } else {
        return $self->{'id'};
    }
}

sub name {
    my $self = shift;
    if (@_) {
        $self->{'name'} = shift;
    } else {
        return $self->{name};
    }
}

sub description {
    my $self = shift;
    if (@_) {
        $self->{'description'} = shift;
    } else {
        return $self->{'description'};
    }
}

sub internals {
    my $self = shift;
    if (@_) {
        $self->{'internals'} = shift;
    } else {
        return $self->{'internals'};
    }
}

1;

__END__

=pod

=encoding utf8

=head1 SYNOPSIS

This class provides methods for accessing and managing products in Bugzilla. Instances
of this class are returned by L<BZ::Client::Product::get>.

 my $client = BZ::Client->new( url       => $url,
                               user      => $user,
                               password  => $password );

 my $ids = BZ::Client::Product->get_accessible_products( $client );
 my $products = BZ::Client::Product->get( $client, \%params );

=head1 CLASS METHODS

This section lists the class methods, which are available in this module.

=head2 get_selectable_products

 @products = BZ::Client::Product->get_selectable_products( $client );
 $products = BZ::Client::Product->get_selectable_products( $client );

Returns a list of the ids of the products the user can search on.

Note: Marked as experimental as of Bugzilla 5.0.

=head3 Parameters

(none)

=head3 Returns

An array of product ID's

=head3 Errors

(none)

=head2 get_enterable_products

 @products = BZ::Client::Product->get_enterable_products( $client );
 $products = BZ::Client::Product->get_enterable_products( $client );

Returns a list of the ids of the products the user can enter bugs against.

Note: Marked as experimental as of Bugzilla 5.0.

=head3 Parameters

(none)

=head3 Returns

An array of product ID's

=head3 Errors

(none)

=head2 get_accessible_products

 @products = BZ::Client::Product->get_selectable_products( $client );
 $products = BZ::Client::Product->get_selectable_products( $client );

Returns a list of the ids of the products the user can search or enter bugs against.

Note: Marked as unstable as of Bugzilla 5.0.

=head3 Parameters

(none)

=head3 Returns

An array of product ID's

=head3 Errors

(none)

=head2 get

 @products = BZ::Client::Product->get( $client, \%params );
 $products = BZ::Client::Product->get( $client, \%params );

Returns a list of BZ::Client::Product instances based on the given parameters.

=head3 Parameters

In addition to the parameters below, this method also accepts the standard
L<include_fields> and L<exclude_fields> arguments.

Note: You must at least specify one of L</ids> or L</names>.

=over 4

=item ids

I<ids> (array) An array of product ids.

=item names

I<names> (array) An array of product names.

Added in Bugzilla 4.2.

=item type

The group of products to return. Valid values are: C<accessible> (default),
C<selectable>, and C<enterable>. L</type> can be a single value or an array
of values if more than one group is needed with duplicates removed.

=back

=head3 Returns

An array or arrayref of bug instance objects with the given ID's.

See L</INSTANCE METHODS> for how to use them.

=head3 Errors

(none)

=head2 new

 my $product = BZ::Client::Product->new( id           => $id,
                                         name         => $name,
                                         description  => $description );

Creates a new instance with the given ID, name, and description.

=head1 INSTANCE METHODS

This section lists the modules instance methods.

=head2 id

 $id = $product->id();
 $product->id( $id );

Gets or sets the products ID.

=head2 name

 $name = $product->name();
 $product->name( $name );

Gets or sets the products name.

=head2 description

 $description = $product->description();
 $product->description( $description );

Gets or sets the products description.

=head1 SEE ALSO

L<BZ::Client>, L<BZ::Client::API>, L<Bugzilla API|https://www.bugzilla.org/docs/tip/en/html/api/Bugzilla/WebService/Product.html>

