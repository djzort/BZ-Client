#!/bin/false
# ABSTRACT: A client for the Bugzilla web services API.
# PODNAME: BZ::Client

use strict;
use warnings 'all';

package BZ::Client;

use BZ::Client::XMLRPC();
use HTTP::Cookies();

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

sub error {
    my ( $self, $message, $http_code, $xmlrpc_code ) = @_;
    require BZ::Client::Exception;
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

sub logger {
    my ($self) = shift;
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
    my ($self) = shift;
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
            $xmlrpc = BZ::Client::XMLRPC->new( 'url' => $url );
            $xmlrpc->logDirectory( $self->logDirectory() );
            $xmlrpc->logger( $self->logger() );
            $self->xmlrpc($xmlrpc);
        }
        return $xmlrpc;
    }
}

sub login {
    my $self = shift;
    my $user = $self->user()
      or $self->error('The Bugzilla servers user name is not set.');
    my $password = $self->password()
      or $self->error('The Bugzilla servers password is not set.');

    my $params = {
        'login'    => $user,
        'password' => $password,
        'remember' => BZ::Client::XMLRPC::boolean->new(0)
    };
    my $cookies = HTTP::Cookies->new();
    my $response = $self->_api_call( 'User.login', $params, $cookies );
    if ( not defined( $response->{'id'} )
        or $response->{'id'} !~ m/^\d+$/s )
    {
        $self->error('Server did not return a valid user ID.');
    }
    $self->{'cookies'} = $cookies;

    return
}

sub logout {
    my $self    = shift;
    my $cookies = $self->{'cookies'};
    if ($cookies) {
        $self->{'cookies'} = undef;
        my $xmlrpc = $self->xmlrpc();
        $xmlrpc->request( 'methodName' => 'User.logout', params => [] );
    }
}

sub is_logged_in {
    my $self = shift;
    return ( $self->{'cookies'} or $self->{'payload'} ) ? 1 : 0
}

sub api_call {
    my ( $self, $methodName, $params ) = @_;
    if ( !$self->is_logged_in() ) {
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
        $xmlrpc->user_agent()->cookie_jar($cookies);
    }

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

=head1 SYNOPSIS

  my $client = BZ::Client->new( url      => $url,
                                user     => $user,
                                password => $password );
  $client->login();

=head1 CLASS METHODS

This section lists the class methods of BZ::Client.

=head1 new

  my $client = BZ::Client->new( url      => $url,
                                user     => $user,
                                password => $password );

The new method constructs a new instance of BZ::Client. Whenever you
want to connect to the Bugzilla server, you must first create a
Bugzilla client. The methods input is a hash of parameters.

For debuggign, you can pass in a subref named I<logger> which will be
fed debugging information as the client works. Also the I<logDirectory>
option is a directory where the raw http content will be dumped.

=over

=item url

The Bugzilla servers URL, for example C<https://bugzilla.mozilla.org/>.

=item user

The user name to use when logging in to the Bugzilla server. Typically,
this will be your email address.

=item password

The password to use when logging in to the Bugzilla server.

=back

=head1 INSTANCE METHODS

This section lists the methods, which an instance of BZ::Client can
perform.

=head2 url

  my $url = $client->url();
  $client->url( $url );

Returns or sets the Bugzilla servers URL.

=head2 user

  my $user = $client->user();
  $client->user( $user );

Returns or sets the user name to use when logging in to the Bugzilla
server. Typically, this will be your email address.

=head2 password

  my $password = $client->password();
  $client->password( $password );

Returns or sets the password to use when logging in to the Bugzilla server.

=head2 login

Used to login to the Bugzilla server. There is no need to call this method
explicitly: It is done automatically, whenever required.

=head2 is_logged_in

Returns 1 if logged in, otherwise 0

=head2 logout

Deletes local cookies and calls bugzilla's logout function

=head2 logger

Sets or gets the logging function. Argument is a coderef. Returns undef if none.

  my $logger = $client->logger();

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

=head2 api_call

  my $response = $client->api_call( $methodName, $params );

Used by subclasses of L<BZ::Client::API> to invoke methods of the Bugzilla
API. Takes a method name and a hash ref of parameters as input. Returns a
hash ref of named result objects.

=head1 SEE ALSO

L<BZ::Client::Exception>

=cut
