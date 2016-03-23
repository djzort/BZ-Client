#!/usr/bin/env perl
# vim: softtabstop=4 tabstop=4 shiftwidth=4 ft=perl expandtab smarttab

use strict;
use warnings 'all';

use lib 't/lib';

use BZ::Client::Test;
use Test::More;

use Data::Dumper;
$Data::Dumper::Indent   = 1;
$Data::Dumper::Sortkeys = 1;

# these next three lines need more thought
use Test::RequiresInternet ( 'landfill.bugzilla.org' => 443 );
my @bugzillas = do 't/servers.cfg';
plan tests => (scalar @bugzillas * 10);

for my $server (@bugzillas) {
    diag(sprintf 'Server version: %s', $server->{version} || '???' );
    my $tester = BZ::Client::Test->new( %$server, logDirectory => '/tmp/bz' );

  SKIP: {
        skip( 'No Bugzilla server configured, skipping', 10 )
          if $tester->isSkippingIntegrationTests();

        my $client = $tester->client();

        # check client isnt logged in before log in
      diag( sprintf 'apikey: %s', $server->{testApiKey} || 'NaN' );

      SKIP: {
            skip( 'Always logged in when using apikey', 1 )
              if $server->{testApiKey};
            ok( !$client->is_logged_in(),
                'The client is NOT already logged in' )
              or
              BAIL_OUT( 'Already logged in? cannot proceed' . Dumper($client) );
        }

        # try to login
        {
            my $ret;
            eval { $ret = $client->login(); };

            if ($@) {
                my $err = $@;
                my $msg;
                if ( ref($err) eq 'BZ::Client::Exception' ) {
                    $msg =
                      'Error: '
                      . (
                        defined( $err->http_code() ) ? $err->http_code()
                        : 'undef' )
                      . ', '
                      . (
                        defined( $err->xmlrpc_code() ) ? $err->xmlrpc_code()
                        : 'undef' )
                      . ', '
                      . (
                        defined( $err->message() ) ? $err->message()
                        : 'undef' );
                }
                else {
                    $msg = "Error $err";
                }
                ok( 0, 'No errors from ->login' ) or diag($msg);
            }
            else {
                ok( 1, 'No errors from ->login' );
            }

            ok( $ret,                    '->login returned true' );
            ok( $client->is_logged_in(), 'The client IS now logged in' )
              or BAIL_OUT('Not logged in, cannot proceed');

        }

        # logout when logged in
        {
            my $ret;
            eval { $ret = $client->logout(); };

            if ($@) {
                my $err = $@;
                my $msg;
                if ( ref($err) eq 'BZ::Client::Exception' ) {
                    $msg =
                      'Error: '
                      . (
                        defined( $err->http_code() ) ? $err->http_code()
                        : 'undef' )
                      . ', '
                      . (
                        defined( $err->xmlrpc_code() ) ? $err->xmlrpc_code()
                        : 'undef' )
                      . ', '
                      . (
                        defined( $err->message() ) ? $err->message()
                        : 'undef' );
                }
                else {
                    $msg = "Error $err";
                }
                ok( 0, 'No errors from ->logout' ) or diag($msg);
            }
            else {
                ok( 1, 'No errors from ->logout' );
            }

            ok( $ret, '->logout returned true' );
            diag( sprintf 'apikey: %s', $server->{testApiKey} || 'NaN' );
          SKIP: {
                skip( 'Always logged in when using apikey', 1 )
                  if $server->{testApiKey};
                ok( !$client->is_logged_in(),
                    'The client is no longer logged in.' );
            }
        }

        # logout when not logged in
        {
            my $ret;
            eval { $ret = $client->logout(); };

            if ($@) {
                my $err = $@;
                my $msg;
                if ( ref($err) eq 'BZ::Client::Exception' ) {
                    $msg =
                      'Error: '
                      . (
                        defined( $err->http_code() ) ? $err->http_code()
                        : 'undef' )
                      . ', '
                      . (
                        defined( $err->xmlrpc_code() ) ? $err->xmlrpc_code()
                        : 'undef' )
                      . ', '
                      . (
                        defined( $err->message() ) ? $err->message()
                        : 'undef' );
                }
                else {
                    $msg = "Error $err";
                }
                ok( 0, 'No errors from ->logout (again)' ) or diag($msg);
            }
            else {
                ok( 1, 'No errors from ->logout (again)' );
            }

            ok( $ret, '->logout (again) returned true' );
            diag( sprintf 'apikey: %s', $server->{testApiKey} || 'NaN' );
          SKIP: {
                skip( 'Always logged in when using apikey', 1 )
                  if $server->{testApiKey};
                ok( !$client->is_logged_in(),
                    'The client is STILL not logged in.' );
            }

        }

    }

}

1
