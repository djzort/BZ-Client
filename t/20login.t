#!/usr/bin/perl

use strict;
use warnings 'all';

use lib 't/lib';


use BZ::Client::Test;
use Test::More;
# use Test::RequiresInternet ( 'www.something.com' => 80, other => 443 );
use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;

plan tests => 10;

my $tester = BZ::Client::Test->new(['config.pl', 't/config.pl']);

SKIP: {
    skip('No Bugzilla server configured, skipping',10)
        if $tester->isSkippingIntegrationTests();

    my $client = $tester->client();

    # check client isnt logged in before log in
    ok(! $client->is_logged_in(), 'The client is NOT already logged in')
        or BAIL_OUT('Already logged in? cannot proceed' . Dumper( $client ));

    # try to login
    {
    my $ret;
    eval {
        $ret = $client->login();
    };

    if ($@) {
        my $err = $@;
        my $msg;
        if (ref($err) eq 'BZ::Client::Exception') {
            $msg = 'Error: ' . (defined($err->http_code()) ? $err->http_code() : 'undef')
                . ', ' . (defined($err->xmlrpc_code()) ? $err->xmlrpc_code() : 'undef')
                . ', ' . (defined($err->message()) ? $err->message() : 'undef');
        }
        else {
            $msg = "Error $err";
        }
        ok(0, 'No errors from ->login') or diag($msg)
    }
    else {
        ok(1, 'No errors from ->login')
    }

    ok($ret, '->login returned true');
    ok($client->is_logged_in(), 'The client IS now logged in')
        or BAIL_OUT('Not logged in, cannot proceed');

    }

    # logout when logged in
    {
    my $ret;
    eval {
        $ret = $client->logout();
    };

    if ($@) {
        my $err = $@;
        my $msg;
        if (ref($err) eq 'BZ::Client::Exception') {
            $msg = 'Error: ' . (defined($err->http_code()) ? $err->http_code() : 'undef')
                . ', ' . (defined($err->xmlrpc_code()) ? $err->xmlrpc_code() : 'undef')
                . ', ' . (defined($err->message()) ? $err->message() : 'undef');
        }
        else {
            $msg = "Error $err";
        }
        ok(0, 'No errors from ->logout') or diag($msg)
    }
    else {
        ok(1, 'No errors from ->logout')
    }

    ok($ret, '->logout returned true');
    ok(! $client->is_logged_in(), 'The client is no longer logged in.');
    }

    # logout when not logged in
    {
    my $ret;
    eval {
        $ret = $client->logout();
    };

    if ($@) {
        my $err = $@;
        my $msg;
        if (ref($err) eq 'BZ::Client::Exception') {
            $msg = 'Error: ' . (defined($err->http_code()) ? $err->http_code() : 'undef')
                . ', ' . (defined($err->xmlrpc_code()) ? $err->xmlrpc_code() : 'undef')
                . ', ' . (defined($err->message()) ? $err->message() : 'undef');
        }
        else {
            $msg = "Error $err";
        }
        ok(0, 'No errors from ->logout (again)') or diag($msg)
    }
    else {
        ok(1, 'No errors from ->logout (again)')
    }

    ok($ret, '->logout (again) returned true');
    ok(! $client->is_logged_in(), 'The client is STILL not logged in.');

    }

};

1
