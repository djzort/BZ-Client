#!/bin/false
# PODNAME: BZ::Client::Product
# ABSTRACT: Client side representation of a product in Bugzilla

use strict;
use warnings 'all';

package BZ::Client::Product;

use parent qw( BZ::Client::API );

# See https://www.bugzilla.org/docs/tip/en/html/api/Bugzilla/WebService/Product.html

## functions

sub create {
    my($class, $client, $params) = @_;
    $client->log('debug', __PACKAGE__ . '::create: Creating');
    my $result = $class->api_call($client, 'Product.create', $params);
    my $id = $result->{'id'};
    if (!$id) {
        $class->error($client, 'Invalid reply by server, expected bug ID.');
    }
    $client->log('debug', __PACKAGE__ . "::create: Made $id");
    return $id
}

sub update {
    my($class, $client, $params) = @_;
    $client->log('debug', __PACKAGE__ . '::update: Updating');
    my $result = $class->api_call($client, 'Product.update', $params);
    my $products = $result->{'products'};
    if (!$products || 'ARRAY' ne ref($products)) {
        $class->error($client, 'Invalid reply by server, expected array of products details.');
    }
    $client->log('debug', __PACKAGE__ . '::update: Updated stuff');
    return wantarray ? @$products : $products
}

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

=head2 create

 $id = BZ::Client::Product->create( $client, \%params );

This allows you to create a new product in Bugzilla.

Marked as experimental as of Bugzilla 5.0.

=head3 Parameters

Some params must be set, or an error will be thrown. These params are noted as Required.

=over 4

=item name

I<name> (string) The name of this product. Must be globally unique within Bugzilla.

Required.

=item description

I<description> (string) A description for this product. Allows some simple HTML.

Required.

=item version

I<version> (string) The default version for this product.

Required.

=item has_unconfirmed

I<has_unconfirmed> (boolean) Allow the UNCONFIRMED status to be set on bugs in this product. Default: true.

=item classification

I<classification> (string) The name of the Classification which contains this product.

=item default_milestone

I<default_milestone> (string) The default milestone for this product. Default '---'.

=item is_open

I<is_open> (boolean) True if the product is currently allowing bugs to be entered into it. Default: true.

=item create_series

I<create_series> (boolean) True if you want series for New Charts to be created for this new product. Default: true.

=back

=head3 Returns

The ID of the newly-filed product.

=head3 Errors

=over 4

=item 51 - Classification does not exist

You must specify an existing classification name.

=item 700 - Product blank name

You must specify a non-blank name for this product.

=item 701 - Product name too long

The name specified for this product was longer than the maximum allowed length.

=item 702 - Product name already exists

You specified the name of a product that already exists. (Product names must be globally unique in Bugzilla.)

=item 703 - Product must have description

You must specify a description for this product.

=item 704 - Product must have version

You must specify a version for this product.

=back

=head2 update

 $id = BZ::Client::Product->update( $client, \%params );

This allows you to update a product in Bugzilla.

As of Bugzilla 5.0. this is marked as experimental.

Added in Bugzilla 4.4.

=head3 Parameters

Either L</ids> or L</names> is required to select the bugs you want to update.

All other values change or set something in the product.

=over 4

=item ids

I<ids> (array) Numeric ids of the products you wish to update.

=item names

I<names> (array) Text names of the products that you wish to update.

=item default_milestone

I<default_milestone> (string) When a new bug is filed, what milestone does it
get by default if the user does not choose one? Must represent a milestone that
is valid for this product.

=item description

I<description> (string) Update the long description for these products to this value.

=item has_unconfirmed

I<has_unconfirmed> (boolean) Allow the UNCONFIRMED status to be set on bugs in this products.

=item is_open

I<is_open> (boolean) True if the product is currently allowing bugs to be entered into it.
Otherwise false.

=back

=head3 Returns

An array or arrayref of hashes containing the following:

=over 4

=item id

I<id> (int) The id of the product that was updated.

=item changes

The changes that were actually done on this product. The keys are the names of the
fields that were changed, and the values are a hash with two keys:

=over 4

=item added

I<added> (string) The value that this field was changed to.

=item removed

I<removed> (string) The value that was previously set in this field.

=back

Note that booleans will be represented with the strings '1' and '0'.

Here's an example of what a return value might look like:

 [
     {
         id => 123,
         changes => {
             name => {
                 removed => 'FooName',
                 added   => 'BarName'
             },
             has_unconfirmed => {
                 removed => '1',
                 added   => '0',
             }
         }
     },
     \%etc
 ],

=back

=head3 Errors

=over 4

=item 700 - Product blank name

You must specify a non-blank name for this product.

=item 701 - Product name too long

The name specified for this product was longer than the maximum allowed length.

=item 702 - Product name already exists

You specified the name of a product that already exists. (Product names must be globally unique in Bugzilla.)

=item 703 - Product must have description

You must specify a description for this product.

=item 705 - Product must define a default milestone

You must define a default milestone.

=back

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

=head2 get_products

Compatibilty with Bugzilla 3.0 API. Exactly equivalent to L</get>.

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

