#!/usr/bin/perl

use strict;
use warnings 'all';

use BZ::Client::Test();
use BZ::Client::Product();
use Test;

my $tester;

sub TestGetSelectableProducts() {
    return TestGetList('get_selectable_products');
}

sub TestGetEnterableProducts() {
    return TestGetList('get_enterable_products', 1);
}

sub TestGetAccessibleProducts() {
    return TestGetList('get_accessible_products');
}

sub TestGetList($) {
    my($method,$allowEmpty) = @_;
    my $client = $tester->client();
    my $ids;
    eval {
        $ids = BZ::Client::Product->$method($client);
        $client->logout();
    };
    if ($@) {
        my $err = $@;
        if (ref($err) eq 'BZ::Client::Exception') {
            print STDERR 'Error: ' . (defined($err->http_code()) ? $err->http_code() : 'undef')
                . ', ' . (defined($err->xmlrpc_code()) ? $err->xmlrpc_code() : 'undef')
                . ', ' . (defined($err->message()) ? $err->message() : 'undef') . "\n";
        } else {
            print STDERR "Error $err\n";
        }
        return 0;
    }
    if (!$ids  ||  ref($ids) ne 'ARRAY'  ||  (!$allowEmpty &&  !@$ids)) {
        print STDERR "No product ID's returned.\n";
        return 0;
    }
    return 1;
}

sub TestGet() {
    my $client = $tester->client();
    my $ids;
    my $products;
    eval {
        $ids = BZ::Client::Product->get_accessible_products($client);
        $products = BZ::Client::Product->get($client, $ids);
        $client->logout();
    };
    if ($@) {
        my $err = $@;
        if (ref($err) eq 'BZ::Client::Exception') {
            print STDERR 'Error: ' . (defined($err->http_code()) ? $err->http_code() : 'undef')
                . ', ' . (defined($err->xmlrpc_code()) ? $err->xmlrpc_code() : 'undef')
                . ', ' . (defined($err->message()) ? $err->message() : 'undef') . "\n";
        } else {
            print STDERR "Error $err\n";
        }
        return 0;
    }
    foreach my $id (@$ids) {
        my $found;
        foreach my $product (@$products) {
            if ($product->id() eq $id) {
                $found = 1;
            }
        }
        if (!$found) {
            print STDERR "No product with ID $id returned.\n";
            return 0;
        }
    }
    foreach my $product (@$products) {
        if (!$product->name()) {
            print STDERR 'The name of product ' . $product->id() . " is not set.\n";
            return 0;
        }
    }
    return 1;
}

plan(tests => 4);

$tester = BZ::Client::Test->new(['config.pl', 't/config.pl']);
my $skipping;
if ($tester->isSkippingIntegrationTests()) {
    $skipping = 'No Bugzilla server configured, skipping';
} else {
    $skipping = 0;
}
skip($skipping, \&TestGetSelectableProducts, 1, 'TestGetSelectableProducts');
skip($skipping, \&TestGetEnterableProducts, 1, 'TestGetEnterableProducts');
skip($skipping, \&TestGetAccessibleProducts, 1, 'TestGetAccessibleProducts');
skip($skipping, \&TestGet, 1, 'TestGet');
