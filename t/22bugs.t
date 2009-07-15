#!/usr/bin/perl -w

use strict;
use warnings "all";

use BZ::Client::Test();
use BZ::Client::Bug();
use Test;

my $tester;

sub contains($$) {
    my($value, $values) = @_;
    foreach my $v (@$values) {
        if ($v eq $value) {
            return 1;
        }
    }
    return 0;
}

sub TestStatus() {
    my $values = TestLegalValues("status");
    return $values && contains("NEW", $values) && contains("CLOSED", $values);
}

sub TestPriority() {
    my $values = TestLegalValues("priority");
    return $values && contains("P1", $values) && contains("P5", $values);
}

sub TestSeverity() {
    my $values = TestLegalValues("severity");
    return $values && contains("blocker", $values) && contains("enhancement", $values);
}

sub TestOpSys() {
    my $values = TestLegalValues("op_sys");
    return $values && contains("All", $values);
}

sub TestPlatform() {
    my $values = TestLegalValues("platform");
    return $values && contains("All", $values);
}

sub TestResolution() {
    my $values = TestLegalValues("resolution");
    return $values && contains("FIXED", $values) && contains("DUPLICATE", $values);
}

sub TestLegalValues($) {
    my($field) = @_;
    my $client = $tester->client();
    my $values;
    eval {
        $values = BZ::Client::Bug->legal_values($client, $field);
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
    if (!$values  ||  ref($values) ne "ARRAY"  ||  !@$values) {
        print STDERR "No values returned.\n";
        return undef;
    }
    return $values;
}

sub TestSearchAll() {
    my $bugs = TestSearch({});
    return $bugs && ref($bugs) eq "ARRAY";
}

sub TestSearchOpen() {
    my $all = TestSearch({});
    my $open = TestSearch({ "status" => [ "NEW", "UNCONFIRMED", "ASSIGNED", "REOPENED" ] });
    foreach my $bug (@$all) {
        my $found = 0;
        foreach my $b (@$open) {
            if ($b->id() eq $bug->id()) {
                $found = 1;
                last;
            }
        }
        if ($bug->is_open()) {
            if (!$found) {
                print STDERR "Bug " . $bug->id() . " is open, but not reported as open.\n";
                return 0;
            }
        } else {
            if ($found) {
                print STDERR "Bug " . $bug->id() . " isn't open, but reported as open.\n";
                return 0;
            }
        }
    }
    return 1;
}

sub TestSearchExistingProduct() {
    my $all = TestSearch({});
    my $productName = $all->[0]->product();
    return TestSearchProduct($all, $productName, 0);
}

sub TestSearchInvalidProduct() {
    my $all = TestSearch({});
    return TestSearchProduct($all, "asdflksdfsldkj  sdflkjsdlf", 1);
}

sub TestSearchProduct($$) {
    my($all, $productName, $emptyOk) = @_;
    my $product_bugs = TestSearch({ "product" => $productName }, $emptyOk);
    if ($emptyOk  &&  !$product_bugs) {
        return 1;
    }
    if ($emptyOk  &&  !@$product_bugs) {
        return 1;
    }
    foreach my $bug (@$all) {
        my $found = 0;
        foreach my $b (@$product_bugs) {
            if ($b->id() eq $bug->id()) {
                $found = 1;
                last;
            }
        }
        if ($bug->product() eq $productName) {
            if (!$found) {
                print STDERR "Bug " . $bug->id() . " has product $productName, but not reported to have it.\n";
                return 0;
            }
        } else {
            if ($found) {
                print STDERR "Bug " . $bug->id() . " has product " . $bug->product() . ", but reported to have $productName.\n";
                return 0;
            }
        }
    }
    return 1;
}

sub TestSearch($$) {
    my($params, $emptyOk) = @_;
    my $client = $tester->client();
    my $bugs;
    eval {
        $bugs = BZ::Client::Bug->search($client, $params);
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
    if (!$bugs  ||  ref($bugs) ne "ARRAY"  ||  (!$emptyOk  &&  !@$bugs)) {
        print STDERR "No bugs returned.\n";
        return undef;
    }
    return $bugs;
}

plan(tests => 10);

$tester = BZ::Client::Test->new(["config.pl", "t/config.pl"]);
my $skipping;
if ($tester->isSkippingIntegrationTests()) {
    $skipping = "No Bugzilla server configured, skipping";
} else {
    $skipping = 0;
}

skip($skipping, \&TestStatus, 1, "TestStatus");
skip($skipping, \&TestPriority, 1, "TestPriority");
skip($skipping, \&TestSeverity, 1, "TestSeverity");
skip($skipping, \&TestOpSys, 1, "TestOpSys");
skip($skipping, \&TestPlatform, 1, "TestPlatform");
skip($skipping, \&TestResolution, 1, "TestResolution");
skip($skipping, \&TestSearchAll, 1, "TestSearchAll");
skip($skipping, \&TestSearchOpen, 1, "TestSearchOpen");
skip($skipping, \&TestSearchExistingProduct, 1, "TestSearchExistingProduct");
skip($skipping, \&TestSearchInvalidProduct, 1, "TestSearchInvalidProduct");

