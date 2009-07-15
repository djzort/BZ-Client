#!/usr/bin/perl -w

use strict;
use warnings "all";

use BZ::Client::Test();
use BZ::Client::Bugzilla();
use Test;

my $tester;

sub TestVersion() {
    my $values = TestCall("version");
    return $values  &&  $values->{"version"} eq "3.3.4";
}

sub TestTimezone() {
    my $values = TestCall("timezone");
    return $values  &&  $values->{"timezone"} eq "+0200";
}

sub TestTime() {
    my $values = TestCall("time");
    return $values  &&  $values->{"tz_name"} eq "Europe/Berlin";
}

sub TestExtensions() {
    my $values = TestCall("extensions");
    return $values  &&  ref($values) eq "HASH";
}

sub TestCall($) {
    my($method) = @_;
    my $client = $tester->client();
    my $values;
    eval {
        $values = BZ::Client::Bugzilla->$method($client);
        $client->logout();
    };
    if ($@) {
        my $err = $@;
        if (ref($err) eq "BZ::Client::Exception") {
            print STDERR "Error: " . (defined($err->http_code()) ? $err->http_code() : "undef")
                . ", " . (defined($err->xmlrpc_code()) ? $err->xmlrpc_code() : "undef")
                . ", " . (defined($err->message()) ? $err->message() : "undef") . "\n";
        } else {
            print STDERR "Error $err\n";
        }
        return undef;
    }
    if (!$values  ||  ref($values) ne "HASH") {
        print STDERR "No values returned.\n";
        return undef;
    }
    return $values;
}

plan(tests => 4);

$tester = BZ::Client::Test->new(["config.pl", "t/config.pl"]);
my $skipping;
if ($tester->isSkippingIntegrationTests()) {
    $skipping = "No Bugzilla server configured, skipping";
} else {
    $skipping = 0;
}

skip($skipping, \&TestVersion, 1, "TestVersion");
skip($skipping, \&TestTime, 1, "TestTime");
skip($skipping, \&TestTimezone, 1, "TestTimezone");
skip($skipping, \&TestExtensions, 1, "TestExtensions");

