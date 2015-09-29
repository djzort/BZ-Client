#!/bin/false
# ABSTRACT: A client for the Bugzilla web services API.
# PODNAME: BZ::Client

use strict;
use warnings 'all';

package BZ::Client;

use BZ::Client::XMLRPC;
use BZ::Client::Exception;
use HTTP::CookieJar;

sub new {
    my $class = shift;
    my $self  = {@_};
    bless( $self, ref($class) || $class );
    return $self
}

sub url {
    my $self = shift;
    if (@_) {
        $self->{'url'} = shift;
    }
    else {
        return $self->{'url'};
    }
}

sub api_key {
    my $self = shift;
    if (@_) {
        $self->{'api_key'} = shift;
    }
    else {
        return $self->{'api_key'};
    }
}

sub user {
    my $self = shift;
    if (@_) {
        $self->{'user'} = shift;
    }
    else {
        return $self->{'user'};
    }
}

sub password {
    my $self = shift;
    if (@_) {
        $self->{'password'} = shift;
    }
    else {
        return $self->{'password'};
    }
}

sub autologin {
    my $self = shift;
    if (@_) {
        $self->{'autologin'} = shift;
    }
    else {
        $self->{'autologin'} = 1
           unless defined($self->{'autologin'});
        return $self->{'autologin'};
    }
}

sub error {
    my ( $self, $message, $http_code, $xmlrpc_code ) = @_;
    BZ::Client::Exception->throw(
        message     => $message,
        http_code   => $http_code,
        xmlrpc_code => $xmlrpc_code
    );
}

sub log {
    my ( $self, $level, $msg ) = @_;
    my $logger = $self->logger();
    if ($logger) {
        &$logger( $level, $msg );
    }
}

# FIXME nothing actually uses this?
sub logger {
    my $self = shift;
    if (@_) {
        my $logger = shift;
        $self->error('Cannot set logger to non-coderef.')
            unless ref $logger eq 'CODE';
        $self->{'logger'} = $logger;
    }
    else {
        return $self->{'logger'};
    }
}

sub logDirectory {
    my $self = shift;
    if (@_) {
        $self->{'logDirectory'} = shift;
    }
    else {
        return $self->{'logDirectory'};
    }
}

sub xmlrpc {
    my $self = shift;
    if (@_) {
        $self->{'xmlrpc'} = shift;
    }
    else {
        my $xmlrpc = $self->{'xmlrpc'};
        if ( !$xmlrpc ) {
            my $url = $self->url()
              || $self->error('The Bugzilla servers URL is not set.');
            $xmlrpc = BZ::Client::XMLRPC->new(
                    url     => $url,
                    connect => $self->{'connect'} );
            $xmlrpc->logDirectory( $self->logDirectory() );
            $xmlrpc->logger( $self->logger() );
            $self->xmlrpc($xmlrpc);
        }
        return $xmlrpc;
    }
}

sub login {
    my $self = shift;

    if ($self->api_key()) {
        $self->log( 'debug', 'BZ::Client::login, no need for User.login call when using api_key' );
        return 1
    }

    my $rl = BZ::Client::XMLRPC::boolean->new($self->{'restrictlogin'} ? 1 : 0);
    my %params = (
        'remember'       => BZ::Client::XMLRPC::boolean->FALSE, # dropped in 4.4 as cookies no longer used
        'restrictlogin'  => $rl, # added in 3.6
        'restrict_login' => $rl, # added in 4.4 for tokens
    );

    # FIXME username and password can be provided to any function and it will be ok
    my $user = $self->user()
        or $self->error('The Bugzilla servers user name is not set.');
    my $password = $self->password()
        or $self->error('The Bugzilla servers password is not set.');

    $params{login} = $user;
    $params{password} = $password;
    $self->log( 'debug', 'BZ::Client::login, going to log in with username and password' );

    my $cookies = HTTP::CookieJar->new();
    my $response = $self->_api_call( 'User.login', \%params, $cookies );
    if ( not defined( $response->{'id'} )
        or $response->{'id'} !~ m/^\d+$/s )
    {
        $self->error('Server did not return a valid user ID.');
    }
    $self->log( 'debug', 'BZ::Client::login, got ID ' . $response->{'id'} );
    if ( my $token = $response->{'token'} ) { # for 4.4.3 onward
        $self->{'token'} = $token;
        $self->log( 'debug', 'BZ::Client::login, got token ' . $token );
    }
    else {
        $self->{'cookies'} = $cookies;
    }
    return 1
}

sub logout {
    my $self    = shift;
    return 1 unless $self->is_logged_in;

    my $cookies = $self->{'cookies'};
    my $token = $self->{'token'};
    if ($cookies or $token) {
        # cannot use _api_call() as response from logout is empty
        my $params = {};
        $params->{'token'} = $self->{'token'}
            if $self->{'token'};
        $self->xmlrpc->request( 'methodName' => 'User.logout', params => [$params] );
        $cookies->clear() if $cookies;
        delete $self->{'token'};
        delete $self->{'cookies'};
    }
    return 1
}

sub is_logged_in {
    my $self = shift;
    return 1 if $self->{'cookies'};
    return 1 if $self->{'token'};
    return 1 if $self->{'api_key'};
    return
}

sub api_call {
    my ( $self, $methodName, $params ) = @_;
    $params ||= {};
    if ( $self->autologin && not $self->is_logged_in() ) {
        $self->login();
    }

    return $self->_api_call( $methodName, $params )
}

sub _api_call {

    my ( $self, $methodName, $params, $cookies ) = @_;

    $self->log( 'debug',
        "BZ::Client::_api_call, sending request for method $methodName to "
          . $self->url() );

    my $xmlrpc = $self->xmlrpc();

    if ($cookies) {
        $xmlrpc->web_agent->{cookie_jar} = $cookies;
    }

    $params->{Bugzilla_token} = $self->{'token'}
        if ($self->{'token'}
            and not $params->{token}
            and not $params->{Bugzilla_token});

    $params->{Bugzilla_api_key} = $self->api_key()
        if ($self->api_key()
            and not $params->{Bugzilla_token}
            and not $params->{Bugzilla_api_key});

    my $response =
      $xmlrpc->request( 'methodName' => $methodName, params => [$params] );

    if ( not $response ) {
        $self->error('Empty response from server.');
    }

    if ( ref($response) ne 'HASH' ) {
        $self->error("Invalid response from server: $response");
    }

    $self->log( 'debug',
        "BZ::Client::_api_call, got response for method $methodName" );

    return $response
}

1;

__END__

=pod

=encoding utf8

=head1 WARNING

USE THIS 2.0 DEVELOPMENT VERSION AT YOUR OWN RISK!

(Which is actually, a clausing in the open source license this software is provided under)

THE API IS CHANGING, STUFF IS BREAKING, YMMV!

USE THE 1.x SERIES UNLESS YOU PREFER DEBUGGING TO GETTING THINGS DONE.

=head1 SYNOPSIS

  my $client = BZ::Client->new( url       => $url,
                                user      => $user,
                                password  => $password,
                                autologin => 0
                                );
  $client->login();

=head1 CLASS METHODS

This section lists the class methods of BZ::Client.

=head2 new

  my $client = BZ::Client->new( url      => $url,
                                user     => $user,
                                password => $password );

  my $client = BZ::Client->new( url      => $url,
                                api_key  => $api_key );

The new method constructs a new instance of BZ::Client. Whenever you
want to connect to the Bugzilla server, you must first create a
Bugzilla client. The methods input is a hash of parameters.

For debugging, you can pass in a subref named I<logger> which will be
fed debugging information as the client works. Also the I<logDirectory>
option is a directory where the raw http content will be dumped.

=head3 Parameters

=over

=item url

The Bugzilla servers URL, for example C<https://bugzilla.mozilla.org/>.

=item api_key

API keys were introduced in 5.0.

An API Key can be obtained in the web interface of your Bugzilla server,
with the following steps:

=over 4

=item Click 'Preferences' link

=item Click 'API Keys' tab

=item Click the checkbox next to 'Generate a new API key...'

=item If you like, add some description in the textbox

=item Click the 'Submit Changes' button

=item Key appears in the table under the 'Existing API keys' subheading

=back

=item user

The user name to use when logging in to the Bugzilla server. Typically,
this will be your email address.

=item password

The password to use when logging in to the Bugzilla server.

=item autologin

If set to 1 (true), will try to log in (if not already logged in) when
the first API call is made. This is default.

If set to 0, will try APi calls without logging in. You can
still call $client->login() to log in manually.

Note: once you're logged in, you'll stay that way until you call I<logout>

=item restrictlogin

If set to 1 (true), will ask Bugzilla to restrict logins to your IP only.
Generally this is a good idea, but may caused problems if you are using
a loadbalanced forward proxy.

Default: 0

=item connect

A hashref with options for L<HTTP::Tiny>, this is passed through so the
bellow are for reference only:

=over 4

=item http_proxy, https_proxy, proxy

Nominates a proxy for HTTP, HTTPS or both, respectively.

You might also use C<$ENV{all_proxy}>, C<$ENV{http_proxy}>, C<$ENV{https_proxy}>
or C<$ENV{all_proxy}>.

=item timeout

Request timeout in seconds (default is 60)

=item verify_SSL

A boolean that indicates whether to validate the SSL certificate of an
"https" connection (default is false)

=back

=back

=head1 INSTANCE METHODS

This section lists the methods, which an instance of BZ::Client can
perform.

=head2 url

 $url = $client->url();
 $client->url( $url );

Returns or sets the Bugzilla servers URL.

=head2 user

 $user = $client->user();
 $client->user( $user );

Returns or sets the user name to use when logging in to the Bugzilla
server. Typically, this will be your email address.

=head2 password

 $password = $client->password();
 $client->password( $password );

Returns or sets the password to use when logging in to the Bugzilla server.

=head2 autologin

If I<login> is automatically called, or not.

=head2 login

Used to login to the Bugzilla server. By default, there is no need to call
this method explicitly: It is done automatically, whenever required.

If I<autologin> is set to 0, call this to log in.

=head2 is_logged_in

Returns 1 if logged in, otherwise 0

=head2 logout

Deletes local cookies and calls bugzilla's logout function

=head2 logger

Sets or gets the logging function. Argument is a coderef. Returns undef if none.

 $logger = $client->logger();

 $client->logger(
     sub {
         my ($level, $msg) = @_;
         print STDERR "$level $message\n";
         return 1
     });

Also can be set via new(), e.g.

 $client = BZ::Client->new( logger => sub { },
                            url    => $url
                            user   => $user,
                            password => $password );

=head2 log

 $client->log( $level, $message );

Sends log messages to whatever is loaded via I<logger>.

=head2 api_call

 $response = $client->api_call( $methodName, $params );

Used by subclasses of L<BZ::Client::API> to invoke methods of the Bugzilla
API. Takes a method name and a hash ref of parameters as input. Returns a
hash ref of named result objects.

=head1 ERROR CODES

=head2 300 (Invalid Username or Password)

The username does not exist, or the password is wrong.

=head2 301 (Login Disabled)

The ability to login with this account has been disabled. A reason may be specified with the error.

=head2 305 (New Password Required)

The current password is correct, but the user is asked to change his password.

=head2 50 (Param Required)

A login or password parameter was not provided.

=head1 TESTING

Bugzilla maintains demos of all supported versions and trunk at L<https://landfill.bugzilla.org>

You might consider using that for testing against live versions>

=head1 SEE ALSO

L<BZ::Client::Exception>

=cut
