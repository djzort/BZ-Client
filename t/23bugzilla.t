#!/usr/bin/perl

use strict;
use warnings 'all';

use BZ::Client::Test();
use BZ::Client::Bugzilla();
use Test::More;

# these next three lines need more thought
use Test::RequiresInternet ('landfill.bugzilla.org' => 443);
plan tests => 72;
my @bugzillas = do 't/servers.cfg';

sub TestCall {
    my($method,$tester) = @_;
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
        ok(0, 'No errors: ' . $method) and diag($msg);
        return undef;
    }
    else {
        ok(1, 'No errors: ' . $method)
    }
    return $values;
}

# $tester = BZ::Client::Test->new(['config.pl', 't/config.pl']);
#
for my $server ( @bugzillas ) {

my $tester = BZ::Client::Test->new( %$server, logDirectory => '/tmp/bz' );

SKIP: {
    skip('No Bugzilla server configured, skipping',11)
        if $tester->isSkippingIntegrationTests();

{
    my $version = TestCall('version',$tester);
    ok( ($version and ! ref $version), 'Got something from Version');
    like( $version, qr/^\d+\.\d+(\.\d+)?(\-\d+)?\+?$/, 'Resembles a version number' );
}
{
    my $tz = TestCall('timezone',$tester);
    ok( ($tz and ! ref($tz)), 'Got something from Timezone');
    like( $tz, qr/^[-+]\d\d\d\d$/, 'Resembles a Time offset' );
    ok ($tz eq '+0000', 'Should be +0000');
}
{
    my $values = TestCall('time',$tester);
    ok( ($values and ref($values) eq 'HASH'), 'Got something from "time" call');

    like( $values->{'tz_name'}, qr!^(\w+/\w+|UTC)$!, 'Resembles a Timezone name' );
    ok( $values->{'tz_name'} eq 'UTC', 'Timezone name should always be UTC' );

    like( $values->{'tz_short_name'}, qr!^(\w+/\w+|UTC)$!, 'Resembles a Timezone short name' );
    ok( $values->{'tz_short_name'} eq 'UTC', 'Timezone short name should always be UTC' );

    ok( ref $values->{'web_time'} eq 'DateTime', 'web_time should be DateTime' );
    ok( ref $values->{'web_time_utc'} eq 'DateTime', 'web_time_utc should be DateTime' );
    ok( ref $values->{'db_time'} eq 'DateTime', 'db_time should be DateTime' );

}
SKIP: {
    skip('I wont look at parameters for this server', 3)
        unless $server->{tests}->{parameters};
    my $values = TestCall('parameters',$tester);
    ok( ($values and ref($values) eq 'HASH'), 'Got something from Parameters');
    ok( scalar keys %$values, 'Got something inside Parameters');
}
SKIP: {
    skip('I wont look at last_audit_time for this server', 2)
        unless $server->{tests}->{last_audit_time};
    my $values = TestCall('last_audit_time',$tester);
    ok( ($values and ref($values) eq 'DateTime'), 'Got DateTime from Last Audit Time');
}

SKIP: {
    skip('I wont look at extensions for this server', 3)
        unless $server->{tests}->{extensions};
    my $values = TestCall('extensions',$tester);
    ok( ($values and ref($values) eq 'HASH'), 'Got something from Extensions');
    ok( scalar keys %$values, 'Got something inside Extensions');
}

}

}
