#!/usr/bin/env perl
# vim: softtabstop=4 tabstop=4 shiftwidth=4 ft=perl expandtab smarttab

use strict;
use warnings 'all';

use lib 't/lib';

use BZ::Client::Test;
use BZ::Client::Product;
use Test::More;

use Data::Dumper; $Data::Dumper::Indent = 1; $Data::Dumper::Sortkeys = 1;

# these next three lines need more thought
use Test::RequiresInternet ( 'landfill.bugzilla.org' => 443 );
my @bugzillas = do 't/servers.cfg';
plan tests => (scalar @bugzillas * 13) + 16;

my $tester;

my %quirks = (

    '5.0' => {},
    '4.4' => {
products => {
    #1 => { name => "WorldControl", description => 'A small little program for controlling the world. Can be used\nfor good or for evil. Sub-components can be created using the WorldControl API to extend control into almost any aspect of reality.'
    #    },
        2 => { name => "FoodReplicator", description => "Software that controls a piece of hardware that will create any food item through a voice interface."},
        3 => { name => "MyOwnBadSelf", description => "feh."}, 
        #4 => { name => "Spider S��ret��ns", description => "Spider secretions"}, 
        19 => { name => "Sam's Widget", description => "Special SAM widgets"}, 
        20 => { name => "LJL Test Product", description => "Test product description"}, 
        21 => { name => "testing-funky-hyphens", description => "Hyphen testing product"},

    },
    },

);

sub TestGetList {
    my($method,$allowEmpty) = @_;
    my $client = $tester->client();
    my $ids;
    SKIP: {
        skip( "BZ::Client::Product cannot do method: $method ?", 1 )
            unless ok( BZ::Client::Product->can($method),
                       "BZ::Client::Product implements method: $method" );

        eval {
            $ids = BZ::Client::Product->$method($client);
            $client->logout();
        };

        if ($@) {
            my $err = $@;
            my $msg;
            if (ref($err) eq 'BZ::Client::Exception') {
                $msg = 'Error: ' .
                    (defined($err->http_code())   ? $err->http_code()   : 'undef') . ', ' .
                    (defined($err->xmlrpc_code()) ? $err->xmlrpc_code() : 'undef') . ', ' .
                    (defined($err->message())     ? $err->message()     : 'undef');
            }

            else {
                $msg = "Error $err";
            }
            ok( 0, 'No errors: ' . $method );
            diag($msg);
            return
        }
        else {
            ok( 1, 'No errors: ' . $method )
        }

        if (!$ids or ref $ids ne 'ARRAY' or (!$allowEmpty and !@$ids)) {
            diag q/No product ID's returned./;
            return
        }

        return $ids

    }
}

sub TestGet {
    my $client = $tester->client();
    my $ids;
    my $products;
    eval {
        $ids = BZ::Client::Product->get_accessible_products($client);
        $products = BZ::Client::Product->get($client, { ids => $ids });
        $client->logout();
    };

    for my $p (sort { $a->id <=> $b->id } @$products) {
        my $product = $quirks{4.4}{products}{$p->id};
        unless ($product) {
            diag 'Server provided unknown product, ID: ' . $p->id;
            next;
        }
        ok($product->{name} eq $p->name, 'Product name of ' . $p->id . ' matches') and
        ok($product->{description} eq $p->description, 'Product description of '.$p->id.' matches') or
        diag 'Got: ' .$p->id .' => { name => "' . $p->name . '", description => "' . $p->description .  qq|"}, \nAim: name = "| . $product->{name} . '" description = "' . $product->{description} . '"';
    }

    if ($@) {
        my $err = $@;
        my $msg;
        if (ref $err eq 'BZ::Client::Exception') {
            $msg = 'Error: ' .
                (defined($err->http_code())   ? $err->http_code()   : 'undef') . ', ' .
                (defined($err->xmlrpc_code()) ? $err->xmlrpc_code() : 'undef') . ', ' .
                (defined($err->message())     ? $err->message()     : 'undef');
        }
        else {
            $msg = "Error $err\n";
        }
        ok( 0, 'No errors: get' );
        diag($msg);
        return
    }
    else {
        ok( 1, 'No errors: get' )
    }

    my $return;

    # careful of the list context, scalar () forces it to be a number
    ok( scalar (grep { my $id = $_; grep { $_->id() eq $id } @$products } @$ids),
        'All product ID\'s were found.' )
    and $return = 1;

    my @unnamed = grep { ! $_->name() } @$products;
    ok( ! @unnamed, 'All products have a name' )
    and $return = 1;

    diag( map { 'The name of product ' . $_->id() . ' is not set.' } @unnamed )
        if @unnamed;

    return $return
}


for my $server (@bugzillas) {

    diag sprintf 'Trying server: %s', $server->{testUrl} || '???';

    $tester = BZ::Client::Test->new( %$server, logDirectory => '/tmp/bz' );

    SKIP: {
        skip( 'No Bugzilla server configured, skipping', 4 )
            if $tester->isSkippingIntegrationTests();

        ok( TestGetList('get_selectable_products'),   'Test out get_selectable_products');
        ok( TestGetList('get_enterable_products', 1), 'Test out get_enterable_products');
        ok( TestGetList('get_accessible_products'),   'Test out get_accessible_products');
        ok( TestGet(), 'Test out getting each product one by one');

    }

}
