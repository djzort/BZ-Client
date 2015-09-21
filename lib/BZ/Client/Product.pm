#!/bin/false
# PODNAME: BZ::Client::Product
# ABSTRACT: Client side representation of a product in Bugzilla

use strict;
use warnings 'all';

package BZ::Client::Product;

use parent qw( BZ::Client::API );

# See https://www.bugzilla.org/docs/tip/en/html/api/Bugzilla/WebService/Product.html

## functions

sub get_selectable_products {
    my($class, $client) = @_;
    $client->log('debug', __PACKAGE__ . '::get_selectable_products: Asking');
    my $result = $class->get_list('Product.get_selectable_products', $client);
    $client->log('debug', __PACKAGE__ . '::get_selectable_products: Got ' . @$result);
    return $result
}

sub get_enterable_products {
    my($class, $client) = @_;
    $client->log('debug', __PACKAGE__ . '::get_enterable_products: Asking');
    my $result = $class->get_list('Product.get_enterable_products', $client);
    $client->log('debug', __PACKAGE__ . '::get_enterable_products: Got ' . @$result);
    return $result
}

sub get_accessible_products {
    my($class, $client) = @_;
    $client->log('debug', __PACKAGE__ . '::get_accessible_products: Asking');
    my $result = $class->get_list('Product.get_accessible_products', $client);
    $client->log('debug', __PACKAGE__ . '::get_accessible_products: Got ' . @$result);
    return $result
}

sub get_list {
    my($class, $methodName, $client) = @_;
    my $result = $class->api_call($client, $methodName);
    my $ids = $result->{'ids'};
    if (!$ids  ||  'ARRAY' ne ref($ids)) {
        $class->error($client, 'Invalid reply by server, expected array of ids.');
    }
    return $ids
}

sub get {
    my($class, $client, $ids) = @_;
    my $result = $class->api_call($client, 'Product.get', { 'ids' => $ids });
    my $products = $result->{'products'};
    if (!$products  ||  'ARRAY' ne ref($products)) {
        $class->error($client, 'Invalid reply by server, expected array of products.');
    }
    my @result;
    for my $product (@$products) {
        push(@result, $class->new(id => $product->{'id'},
                                  name => $product->{'name'},
                                  description => $product->{'description'},
                                  internals => $product->{'internals'}));
    }
    return \@result
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
  my $products = BZ::Client::Product->get( $client, $ids );

=head1 CLASS METHODS

This section lists the class methods, which are available in this module.

=head2 get_selectable_products

  my @products = BZ::Client::Product->get_selectable_products( $client );

Returns a list of the ids of the products the user can search on.

=head2 get_enterable_products

  my @products = BZ::Client::Product->get_selectable_products( $client );

Returns a list of the ids of the products the user can enter bugs against.

=head2 get_accessible_products

  my @products = BZ::Client::Product->get_selectable_products( $client );

Returns a list of the ids of the products the user can search or enter bugs against.

=head2 get

  my @products = BZ::Client::Product->get( $client, \@ids );

Returns a list of BZ::Client::Product instances with the product ID's
mentioned in the list @ids.

=head2 new

  my $product = BZ::Client->Product->new( id           => $id,
                                          name         => $name,
                                          description  => $description );

Creates a new instance with the given ID, name, and description.

=head1 INSTANCE METHODS

This section lists the modules instance methods.

=head2 id

  my $id = $product->id();
  $product->id( $id );

Gets or sets the products ID.

=head2 name

  my $name = $product->name();
  $product->name( $name );

Gets or sets the products name.

=head2 description

  my $description = $product->description();
  $product->description( $description );

Gets or sets the products description.

=head1 SEE ALSO

  L<BZ::Client>, L<BZ::Client::API>, L<Bugzilla API|https://www.bugzilla.org/docs/tip/en/html/api/Bugzilla/WebService/Product.html>

