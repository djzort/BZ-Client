#!/usr/bin/perl -w

use strict;
use warnings "all";

use BZ::Client::Test();
use Test;

my $tester;

sub TestBasic() {
    my $client = $tester->client();
    if ($client->is_logged_in()) {
        print STDERR "The client is already logged in.\n";
        return 0;
    }
    eval {
        $client->login();
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
    }
    if (!$client->is_logged_in()) {
        print STDERR "The client isn't logged in.\n";
        return 0;
    }
    eval {
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
    }
    if ($client->is_logged_in()) {
        print STDERR "The client is still logged in.\n";
        return 0;
    }
    return 1;
}

plan(tests => 1);

$tester = BZ::Client::Test->new(["config.pl", "t/config.pl"]);
my $skipping;
if ($tester->isSkippingIntegrationTests()) {
    $skipping = "No Bugzilla server configured, skipping";
} else {
    $skipping = 0;
}
skip($skipping, \&TestBasic, 1, "TestBasic");

