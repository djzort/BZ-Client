#!/usr/bin/perl -w

use strict;
use warnings 'all';

use BZ::Client::Test();
use BZ::Client::Bug();
use Test::More tests => 6;

my $tester;

sub contains {
    my($value, $values) = @_;
    for my $v (@$values) {
        return 1
            if ($v eq $value)
    }
    return 0
}

sub TestStatus {
    my $values = TestLegalValues('status');
    return $values && contains('NEW', $values) && contains('CLOSED', $values);
}

sub TestPriority {
    my $values = TestLegalValues('priority');
    return $values && contains('P1', $values) && contains('P5', $values);
}

sub TestSeverity {
    my $values = TestLegalValues('severity');
    # these can be changed in bugzilla, so failure may simply indicate that a different value is present
    return $values && (contains('blocker', $values) or contains('enhancement', $values));
}

sub TestOpSys {
    my $values = TestLegalValues('op_sys');
    # these can be changed in bugzilla, so failure may simply indicate that a different value is present
    return $values && (contains('All', $values) or contains('other', $values));
}

sub TestPlatform {
    my $values = TestLegalValues('platform');
    # these can be changed in bugzilla, so failure may simply indicate that a different value is present
    return $values && (contains('All', $values) or contains('Other', $values));
}

sub TestResolution {
    my $values = TestLegalValues('resolution');
    return $values && contains('FIXED', $values) && contains('DUPLICATE', $values);
}

sub TestLegalValues {
    my $field = shift;
    my $client = $tester->client();
    my $values;
    eval {
        $values = BZ::Client::Bug->legal_values($client, $field);
        $client->logout();
    };
    if ($@) {
        my $err = $@;
        if (ref($err) eq 'BZ::Client::Exception') {
            print STDERR 'Error: ' . (defined($err->http_code()) ? $err->http_code() : 'undef')
                . ', ' . (defined($err->xmlrpc_code()) ? $err->xmlrpc_code() : 'undef')
                . ', ' . (defined($err->message()) ? $err->message() : 'undef') . '\n';
        }
        else {
            print STDERR "Error $err\n";
        }
        return undef;
    }
    if (!$values or ref($values) ne 'ARRAY'  or !@$values) {
        print STDERR "No values returned.\n";
        return undef;
    }
    return $values;
}

sub TestSearchAll {
    my $bugs = TestSearch({});
    return $bugs && ref($bugs) eq 'ARRAY';
}

sub TestSearchOpen {
    my $all = TestSearch({});
    my $open = TestSearch({ 'status' => [ 'NEW', 'UNCONFIRMED', 'ASSIGNED', 'REOPENED' ] });
    for my $bug (@$all) {
        my $found = 0;
        for my $b (@$open) {
            if ($b->id() eq $bug->id()) {
                $found = 1;
                last;
            }
        }
        if ($bug->is_open()) {
            if (!$found) {
                print STDERR 'Bug ' . $bug->id() . " is open, but not reported as open.\n";
                return 0;
            }
        }
        else {
            if ($found) {
                print STDERR 'Bug ' . $bug->id() . " isn't open, but reported as open.\n";
                return 0;
            }
        }
    }
    return 1;
}

sub TestSearchExistingProduct {
    my $all = TestSearch({});
    my $productName = $all->[0]->product();
    return TestSearchProduct($all, $productName, 0);
}

sub TestSearchInvalidProduct {
    my $all = TestSearch({});
    return TestSearchProduct($all, 'asdflksdfsldkj  sdflkjsdlf', 1);
}

sub TestSearchProduct {
    my($all, $productName, $emptyOk) = @_;
    my $product_bugs = TestSearch({ 'product' => $productName }, $emptyOk);
    if ($emptyOk  &&  !$product_bugs) {
        return 1;
    }
    if ($emptyOk  &&  !@$product_bugs) {
        return 1;
    }
    for my $bug (@$all) {
        my $found = 0;
        for my $b (@$product_bugs) {
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
        }
        else {
            if ($found) {
                print STDERR 'Bug ' . $bug->id() . ' has product ' . $bug->product() . ", but reported to have $productName.\n";
                return 0;
            }
        }
    }
    return 1;
}

sub TestSearch {
    my($params, $emptyOk) = @_;
    my $client = $tester->client();
    my $bugs;
    eval {
        $bugs = BZ::Client::Bug->search($client, $params);
        $client->logout();
    };
    if ($@) {
        my $err = $@;
        if (ref($err) eq 'BZ::Client::Exception') {
            print STDERR 'Error: ' . (defined($err->http_code()) ? $err->http_code() : 'undef')
                . ', ' . (defined($err->xmlrpc_code()) ? $err->xmlrpc_code() : 'undef')
                . ', ' . (defined($err->message()) ? $err->message() : 'undef') . '\n';
        }
        else {
            print STDERR "Error $err\n";
        }
        return undef;
    }
    if (!$bugs  ||  ref($bugs) ne 'ARRAY'  ||  (!$emptyOk  &&  !@$bugs)) {
        print STDERR "No bugs returned.\n";
        return undef;
    }
    return $bugs;
}

$tester = BZ::Client::Test->new(['config.pl', 't/config.pl']);

SKIP: {

    skip('No Bugzilla server configured, skipping',6)
            if $tester->isSkippingIntegrationTests();

    ok(&TestStatus, 'Status');
    ok(&TestPriority, 'Priority');
    ok(&TestSeverity, 'Severity');
    ok(&TestOpSys, 'OpSys');
    ok(&TestPlatform, 'Platform');
    ok(&TestResolution, 'Resolution');

#these will time out on a large install
#    ok(&TestSearchAll, 'SearchAll');
#    ok(&TestSearchOpen, 'SearchOpen');
#    ok(&TestSearchExistingProduct, 'SearchExistingProduct');
#    ok(&TestSearchInvalidProduct, 'SearchInvalidProduct');

};
