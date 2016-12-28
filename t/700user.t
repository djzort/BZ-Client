#!/usr/bin/env perl
# vim: softtabstop=4 tabstop=4 shiftwidth=4 ft=perl expandtab smarttab

use strict;
use warnings 'all';
use utf8;

use lib 't/lib';

use BZ::Client::Test;
use BZ::Client::User;
use Test::More;
use Text::Password::Pronounceable;
my $pp = Text::Password::Pronounceable->new(10,14);

use Data::Dumper;
$Data::Dumper::Indent   = 1;
$Data::Dumper::Sortkeys = 1;

# these next three lines need more thought
use Test::RequiresInternet ( 'landfill.bugzilla.org' => 443 );
my @bugzillas = do 't/servers.cfg';
plan tests => ( scalar @bugzillas * 15 );

my $tester;

sub quoteme {
    my @args = @_;
    for my $foo (@args) {
        $foo =~ s{\n}{\\n}g;
        $foo =~ s{\r}{\\r}g;
    }
    @args;
}

my %quirks = (
    '5.0' => {
        'offer_account_by_email' => [
            # test insufficient arguments
            {
                params => { },
                error => {
                        xmlrpc => 50,
                        message => 'The function requires a email argument, and that argument was not set.',
                },
                response => undef,
            },
            # test error 500
            {
                params => { email => 'djzort@cpan.org' },
                error => {
                        xmlrpc => 500,
                        message => 'There is already an account with the login name djzort@cpan.org.'
                },
                response => undef,
            },
            # test error 500 with lazy syntax
            {
                params => 'djzort@cpan.org',
                error => {
                        xmlrpc => 500,
                        message => 'There is already an account with the login name djzort@cpan.org.'
                },
                response => undef,
            },
            # test error 501
            {
                params => { email => 'djzortATcpan.org' },
                error => {
                        xmlrpc => 501,
                        message => q|The e-mail address you entered (djzortATcpan.org) didn't pass our syntax checking for a legal email address. A legal address must contain exactly one '@', and at least one '.' after the @. It also must not contain any illegal characters.|,
                },
                response => undef,
            },
            {

                params => { email => sprintf('bz-client-testing-%s@cpan.org',$pp->generate) },
                response => 1,

            },
        ]
    },

);

# for now, all 4.4 tests are the same as 5.0
$quirks{'4.4'} = $quirks{'5.0'};

sub TestOffer {
    my $list = shift;
    my $client = $tester->client();

    my $cnt = 0;
    my $return = 1;

    for my $data (@$list) {

        $cnt++;
        my $ok;

        eval {
            $ok = BZ::Client::User->offer_account_by_email($client, $data->{params});
            $client->logout();
        };

        my $error = $data->{error};

        if ($@) {
            my $err = $@;
            my $msg;
            if ( ref $err eq 'BZ::Client::Exception' ) {

                if ($error) {

                    if ($error->{message}) {
                        is( $err->message(), $error->{message},
                            sprintf( q|Error message correct. Test # %d|, $cnt ))
                            or $return = 0;
                    }
                    else {
                        ok( 0, 'No Error message to check? Test ' . $cnt )
                            or $return = 0;
                    }

                    if ($error->{xmlrpc}) {
                        is( $err->xmlrpc_code(), $error->{xmlrpc},
                            sprintf( q|Error xmlrpc_code correct. Test # %d|, $cnt ))
                            or $return = 0;
                    }

                    if ($error->{http}) {
                        is( $err->httprpc_code(), $error->{http},
                            sprintf( q|Error http_code correct. Test # %d|, $cnt ))
                            or $return = 0;
                    }

                }

                $msg =
                    'Error: '
                  . ( defined( $err->http_code() )   ? $err->http_code() : 'undef' )   . ', '
                  . ( defined( $err->xmlrpc_code() ) ? $err->xmlrpc_code() : 'undef' ) . ', '
                  . ( defined( $err->message() )     ? $err->message() : 'undef' );

            }
            else {

                $msg = "Error: $err\n";

                if ($error) {

                    if ($error->{message}) {
                        is( $err, $error->{message}, 'Error message correct. Test # ' . $cnt )
                            or $return = 0;
                    }
                    else {
                        ok( 0, 'No Error message to check? Test #' . $cnt )
                            or $return = 0;
                    }

                    ok( 0, 'Error before xmlrpc code was provided' ) if $error->{xmlrpc};
                    ok( 0, 'Error before http code was provided' ) if $error->{http};

                }

            }

            unless ($error) {
                diag($msg);
                ok( 0, 'No errors: offer_account_by_email. Test # ' . $cnt );
                diag Dumper $@;
                $return = 0;
            }
        }
        else { # if ($@)
            if ($error) {
                ok( 0, 'Expected an error when running: offer_account_by_email, test # ' . $cnt );
                ok( 0, 'Expected xmlrpc error code: ' . $error->{xmlrpc} ) if $error->{xmlrpc};
                ok( 0, 'Expected http error code :' . $error->{http} ) if $error->{http};

                $return = 0;
            }
            else {
                ok( 1, 'No errors: offer_account_by_email, test # ' .$cnt );
            }
        } # if ($@)

        is( $ok, $data->{response}, 'offer_account_by_email response check' )
            if exists $data->{response};


    } # for my $data (@$list)

    return $return;
}

for my $server (@bugzillas) {

    diag sprintf 'Trying server: %s', $server->{testUrl} || '???';

    $tester = BZ::Client::Test->new( %$server, logDirectory => '/tmp/bz' );

  SKIP: {
        skip( 'No Bugzilla server configured, skipping', 4 )
          if $tester->isSkippingIntegrationTests();
        diag sprintf 'Server %s is version %s', $server->{testUrl}, $server->{version};

          ok( TestOffer( $quirks{$server->{version}}{offer_account_by_email} ), 'Test Offering Accounts via Email');

    }

}
