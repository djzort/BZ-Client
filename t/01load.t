#!/usr/bin/perl -w

use strict;
use warnings 'all';

use Test;
use File::Find();

our @MODULES = qw(
        BZ/Client/XMLRPC
        BZ/Client/Product
        BZ/Client/Exception
        BZ/Client/XMLRPC/Array
        BZ/Client/XMLRPC/Value
        BZ/Client/XMLRPC/Handler
        BZ/Client/XMLRPC/Response
        BZ/Client/XMLRPC/Struct
        BZ/Client/XMLRPC/Parser
        BZ/Client/Bug
        BZ/Client/Bugzilla
        BZ/Client/API
        BZ/Client/Test
        BZ/Client
    );

plan(tests => (scalar(@MODULES) + 1));

sub CountModules {
    my $numModules;
    File::Find::find(sub {
        if ($_ =~ m/\.pm$/  &&  -f $_) {
            ++$numModules;
        }
    }, 'lib');
    return $numModules;
}

sub CheckModule {
    my $module = shift;
    eval {
        my $mod = $module . '.pm';
        $mod =~ s/\:\:/\//g;
        require $mod;
    };
    my $err = $@;
    if ($err) {
    }
    ok($err, q||, $module . ($err ? ": $err" : q||));
}

for my $module (@MODULES) {
    CheckModule($module);
}

my $numModules = CountModules();
ok(scalar(@MODULES), $numModules, 'Expected ' . scalar(@MODULES) . ", got $numModules");

