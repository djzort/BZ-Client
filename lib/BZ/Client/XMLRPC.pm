#!/bin/false
# PODNAME: BZ::Client::XMLRPC
# ABSTRACT: Performs XML-RPC calls on behalf of the client.

use strict;
use warnings 'all';

package BZ::Client::XMLRPC;

use LWP();
use XML::Writer();
use Encode;
use BZ::Client::XMLRPC::Parser();
use DateTime::Format::Strptime();
use DateTime::TimeZone();

our $counter;
our $fmt = DateTime::Format::Strptime->new( pattern=> '%C%Y-%m-%dT%T', time_zone => 'UTC' );
our $tz = DateTime::TimeZone->new( name => 'UTC' );


sub new {
    my $class = shift;
    my $self = { @_ };
    bless($self, ref($class) || $class);
    return $self;
}

sub url {
    my $self = shift;
    if (@_) {
        $self->{'url'} = shift;
    } else {
        return $self->{'url'};
    }
}

sub user_agent {
    my $self = shift;
    if (@_) {
        $self->{'user_agent'} = shift;
    } else {
        my $ua = $self->{'user_agent'};
        if (!defined($ua)) {
            $ua = LWP::UserAgent->new();
            $ua->agent("BZ::Client::XMLRPC $BZ::Client::XMLRPC::VERSION");
            $self->user_agent($ua);
        }
        return $ua;
    }
}

sub error {
    my($self, $message, $http_code, $xmlrpc_code) = @_;
    require BZ::Client::Exception;
    BZ::Client::Exception->throw('message' => $message,
                                 'http_code' => $http_code,
                                 'xmlrpc_code' => $xmlrpc_code)
}

sub value {
    my($self, $writer, $value) = @_;
    if (ref($value) eq 'HASH') {
        $writer->startTag('value');
        $writer->startTag('struct');
        for my $key (sort keys %$value) {
            $writer->startTag('member');
            $writer->startTag('name');
            $writer->characters($key);
            $writer->endTag('name');
            $self->value($writer, $value->{$key});
            $writer->endTag('member');
        }
        $writer->endTag('struct');
        $writer->endTag('value');
    } elsif (ref($value) eq 'ARRAY') {
        $writer->startTag('value');
        $writer->startTag('array');
        $writer->startTag('data');
        for my $val (@$value) {
            $self->value($writer, $val);
        }
        $writer->endTag('data');
        $writer->endTag('array');
        $writer->endTag('value');
    } elsif (ref($value) eq 'BZ::Client::XMLRPC::int') {
        $writer->startTag('value');
        $writer->startTag('i4');
        $writer->characters($$value);
        $writer->endTag('i4');
        $writer->endTag('value');
    } elsif (ref($value) eq 'BZ::Client::XMLRPC::boolean') {
        $writer->startTag('value');
        $writer->startTag('boolean');
        $writer->characters($$value ? '1' : '0');
        $writer->endTag('boolean');
        $writer->endTag('value');
    } elsif (ref($value) eq 'BZ::Client::XMLRPC::double') {
        $writer->startTag('value');
        $writer->startTag('double');
        $writer->characters($$value);
        $writer->endTag('double');
        $writer->endTag('value');
    } elsif (ref($value) eq 'DateTime') {
        my $clone = $value->clone();
        $clone->set_time_zone($tz);
        $clone->set_formatter($fmt);
        $writer->startTag('value');
        $writer->startTag('dateTime.iso8601');
        $writer->characters($clone->iso8601(). 'Z');
        $writer->endTag('dateTime.iso8601');
        $writer->endTag('value');
    } else {
        $writer->startTag('value');
        $writer->characters($value);
        $writer->endTag('value');
    }
}

sub create_request {
    my($self, $methodName, $params) = @_;
    my $contents;
    my $writer = XML::Writer->new(OUTPUT => \$contents, ENCODING => 'UTF-8');
    $writer->startTag('methodCall');
    $writer->startTag('methodName');
    $writer->characters($methodName);
    $writer->endTag('methodName');
    $writer->startTag('params');
    for my $param (@$params) {
        $writer->startTag('param');
        $self->value($writer, $param);
        $writer->endTag('param');
    }
    $writer->endTag('params');
    $writer->endTag('methodCall');
    $writer->end();
    return encode('utf8', $contents)
}

sub get_response {
    my($self, $contents) = @_;
    return _get_response($self, { 'url' => $self->url() . '/xmlrpc.cgi',
                                  'contentType' => 'text/xml',
                                  'contents' => encode_utf8($contents) })
}

sub _get_response {
    my($self, $params) = @_;
    my $url = $params->{'url'};
    my $contentType = $params->{'contentType'};
    my $contents = $params->{'contents'};
    if (ref($contents) eq 'ARRAY') {
        require URI;
        my $uri = URI->new('http:');
        $uri->query_form($contents);
        $contents = $uri->query();
    }

    my $req = HTTP::Request->new(POST => $url);
    $req->content_type($contentType);
    $req->content($contents);
    if ($self->{'request_only'}) {
        return $req;
    }
    my $ua = $self->user_agent();

    my($logDir,$logId) = $self->logDirectory();

    if ($logDir) {
        $logId = ++$counter;
        require File::Spec;
        my $fileName = File::Spec->catfile($logDir, "$$.$logId.request.log");
        if (open(my $fh, '>', $fileName)) {
            for my $header ($req->header_field_names()) {
                for my $value ($req->header($header)) {
                    print $fh "$header: $value\n";
                }
            }
            if ($ua->cookie_jar()) {
                print $fh $ua->cookie_jar()->as_string();
            }
            print $fh "\n";
            print $fh $contents;
            close($fh);
        }
    }

    my $res = $ua->request($req);
    my $response = $res->is_success() ? $res->content() : undef;
    if ($logDir) {
        my $fileName = File::Spec->catfile($logDir, "$$.$logId.response.log");
        if (open(my $fh, '>', $fileName)) {
            for my $header ($res->header_field_names()) {
                for my $value ($res->header($header)) {
                    print $fh "$header: $value\n";
                }
            }
            print $fh "\n";
            if ($res->is_success) {
                print $fh $response;
            }
            close($fh);
        }
    }
    if (!$res->is_success()) {
        my $msg = $res->status_line();
        my $code = $res->code();
        if ($code == 401) {
           $self->error('Authorization error, perhaps invalid user name and/or password', $code);
        } elsif ($code == 404) {
           $self->error('Bugzilla server not found, perhaps invalid URL.', $code);
        } else {
           $self->error("Unknown error: $msg", $code);
        }
    }

    return $response
}

sub parse_response {
    my($self, $contents) = @_;
    my $parser = BZ::Client::XMLRPC::Parser->new();
    return $parser->parse($contents)
}

sub request {
    my $self = shift;
    my %args = @_;
    my $methodName = $args{'methodName'};
    $self->error('Missing argument: methodName') unless defined($methodName);
    my $params = $args{'params'};
    $self->error('Missing argument: params') unless defined($params);
    $self->error('Invalid argument: params (Expected array)') unless ref($params) eq 'ARRAY';
    my $contents = $self->create_request($methodName, $params);
    $self->log('debug', "BZ::Client::XMLRPC::request: Sending method $methodName to " . $self->url());
    my $response = $self->get_response($contents);
    $self->log('debug', "BZ::Client::XMLRPC::request: Got result for method $methodName");
    return $self->parse_response($response)
}

sub log {
    my($self, $level, $msg) = @_;
    my $logger = $self->logger();
    if ($logger) {
        &$logger($level, $msg);
    }
}

sub logger {
    my($self) = shift;
    if (@_) {
        $self->{'logger'} = shift;
    } else {
        return $self->{'logger'};
    }
}

sub logDirectory {
    my($self) = shift;
    if (@_) {
        $self->{'logDirectory'} = shift;
    } else {
        return $self->{'logDirectory'};
    }
}

package BZ::Client::XMLRPC::int;

sub new {
    my($class, $value) = @_;
    return bless(\$value, (ref($class) || $class))
}

package BZ::Client::XMLRPC::boolean;

sub new {
    my($class, $value) = @_;
    return bless(\$value, (ref($class) || $class))
}

use constant TRUE => BZ::Client::XMLRPC::boolean->new(1);
use constant FALSE => BZ::Client::XMLRPC::boolean->new(0);

package BZ::Client::XMLRPC::double;

sub new {
    my($class, $value) = @_;
    return bless(\$value, (ref($class) || $class))
}

1;

__END__

=encoding utf-8

=head1 SYNOPSIS

  my $xmlrpc = BZ::Client::XMLRPC->new( url => $url);
  my $result = $xmlrpc->request( methodName => $methodName, params => $params);

An instance of BZ::Client::XMLRPC is able to perform XML-RPC calls against the
given URL. A request is performed by passing the method name and the method
parameters to the method L</request>. The request result is returned.

=head1 CLASS METHODS

This section lists the possible class methods.

=head2 new

  my $xmlrpc = BZ::Client::XMLRPC->new( url => $url);

Creates a new instance with the given URL.

=head1 INSTANCE METHODS

This section lists the possible instance methods.

=head2 url

  my $url = $xmlrpc->url();
  $xmlrpc->url( $url );

Returns or sets the XML-RPC servers URL.

=head2 request

  my $result = $xmlrpc->request( methodName => $methodName,  params => $params);

Calls the XML-RPC servers method C<$methodCall>, passing the parameters given by
C<$params>, an array of parameters. Parameters may be hash refs, array refs, or
atomic values. Array refs and hash refs may recursively contain array or hash
refs as values. An instance of L<BZ::Client::Exception> is thrown in case of
errors.

=head1 SEE ALSO

  L<BZ::Client>, L<BZ::Client::Exception>
