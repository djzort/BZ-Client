#!/usr/bin/perl

use strict;
use warnings 'all';

use BZ::Client::Test();
use BZ::Client::Bugzilla();
use Test::More tests => 11;

my $tester;

sub TestCall {
    my($method) = @_;
    my $client = $tester->client();
    my $values;
    eval {
        $values = BZ::Client::Bugzilla->$method($client);
        $client->logout();
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
            $msg =  "Error $err";
        }
        ok(0, 'No errors') and diag($msg);
        return undef;
    }
    else {
        ok(1, 'No errors')
    }
    return $values;
}

$tester = BZ::Client::Test->new(['config.pl', 't/config.pl']);
SKIP: {
    skip('No Bugzilla server configured, skipping',11)
        if $tester->isSkippingIntegrationTests();

{
    my $values = TestCall('version');
    ok( ($values and ref($values) eq 'HASH'), 'Got something from Version');
    like( $values->{'version'}, qr/^\d+\.\d+(\.\d+)?(\-\d+)?$/, 'Resembles a version number' );
}
{
    my $values = TestCall('timezone');
    ok( ($values and ref($values) eq 'HASH'), 'Got something from Timezone');
    like( $values->{'timezone'}, qr/^[-+]\d\d\d\d$/, 'Resembles a Time offset' );
}
{
    my $values = TestCall('time');
    ok( ($values and ref($values) eq 'HASH'), 'Got something from Timezone name');
    like( $values->{'tz_name'}, qr!^(\w+/\w+|UTC)$!, 'Resembles a Timezone name' );
}
{
    my $values = TestCall('extensions');
    ok( ($values and ref($values) eq 'HASH'), 'Got something from Extensions');
}

};
