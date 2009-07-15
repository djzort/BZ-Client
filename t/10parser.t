#!/usr/bin/perl -w

use strict;
use warnings "all";

use BZ::Client::XMLRPC::Parser;

use Test;


sub parse($) {
    my $contents = shift;
    my $parser = BZ::Client::XMLRPC::Parser->new();
    my $result;
    eval {
        $result = $parser->parse($contents);
    };
    if ($@) {
        my $msg;
        if (ref($@) eq "BZ::Client::Exception") {
            $msg = $@->message();
        } else {
            $msg = $@;
        }
        print STDERR "$msg\n";
        return undef;
    }
    return $result;
}

sub parse_error($) {
    my $contents = shift;
    my $parser = BZ::Client::XMLRPC::Parser->new();
    my $result;
    eval {
        $result = $parser->parse($contents);
    };
    if (!$@) {
        print STDERR "Expected exception, got none.\n";
        return undef;
    }
    if (ref($@) ne "BZ::Client::Exception") {
        print STDERR "$@\n";
        return undef;
    }
    return $@;
}

sub TestBasic() {
    my $doc = <<"EOF";
<methodResponse> 
    <params>
        <param>
            <value><string>South Dakota</string></value>
        </param>
    </params>
</methodResponse>
EOF
    return parse($doc);
}

sub TestStrings() {
    my $doc = <<"EOF";
<methodResponse> 
    <params>
        <param>
            <value>
              <array>
                <data>
                  <value><string>South Dakota</string></value>
                  <value>North Dakota</value>
                </data>
              </array>
            </value>
        </param>
    </params>
</methodResponse>
EOF
    my $result = parse($doc);
    if (!$result  ||  ref($result) ne "ARRAY") {
	return "Expected array, got " . (defined($result) ? $result : "undef");
    }
    if (@$result != 2) {
	return "Expected 2 result elements, got " . scalar(@$result);
    }
    my $res0 = $result->[0];
    if (!$res0  ||  $res0 ne "South Dakota") {
	return "Expected first result element to be 'South Dakota', got " . (defined($res0) ? "'$res0'" : "undef");
    }
    my $res1 = $result->[1];
    if (!$res1  ||  $res1 ne "North Dakota") {
	return "Expected first result element to be 'North Dakota', got " . (defined($res0) ? "'$res0'" : "undef");
    }
    return undef;
}

sub TestStructure() {
    my $doc = <<"EOF";
<methodResponse> 
  <params>
    <param>
      <value>
        <struct>
          <member>
            <name>foo</name>
            <value>bar</value>
          </member>
          <member>
            <name>yum</name>
            <value>yam</value>
          </member>
        </struct>
      </value>
    </param>
  </params>
</methodResponse>
EOF
    my $result = parse($doc);
    if (!$result || ref($result) ne "HASH") {
	return "Expected hash, got " . (defined($result) ? $result : "undef");
    }
    if ((keys %$result) != 2) {
	return "Expected 2 result members, got " . scalar(keys %$result);
    }
    my $res0 = $result->{"foo"};
    if (!$res0  ||  $res0 ne "bar") {
        return "Expected result member 'foo' to be 'bar', got " . (defined($res0) ? "'$res0'" : "undef");
    }
    my $res1 = $result->{"yum"};
    if (!$res1  ||  $res1 ne "yam") {
        return "Expected result member 'yum' to be 'yam', got " . (defined($res1) ? "'$res1'" : "undef");
    }
    return undef;
}

sub TestFault() {
    my $doc = <<"EOF";
<methodResponse> 
  <fault>
    <value>
      <struct>
        <member>
          <name>faultCode</name>
          <value>401343</value>
        </member>
        <member>
          <name>faultString</name>
          <value>Some problem occurred</value>
        </member>
      </struct>
    </value>
  </fault>
</methodResponse>
EOF
    my $result = parse_error($doc);
    my $code = $result->xmlrpc_code();
    if (!defined($code)  ||  $code != 401343) {
        return "Expected faultCode 401343, got " . (defined($code) ? $code : "undef");
    }
    my $message = $result->message();
    if (!defined($message)  ||  $message ne "Some problem occurred") {
	return "Expected faultString 'Some problem occurred', got " . (defined($message) ? "'$message'" : "undef");
    }
    my $http_code = $result->http_code();
    if (defined($http_code)) {
        return "Expected no http_code, got " . $http_code;
    }
    return undef;
}

sub TestLogin() {
    my $doc = <<"EOF";
<methodResponse>
  <params>
    <param>
      <value>
        <struct>
          <member>
            <name>id</name>
            <value><int>1</int></value>
          </member>
        </struct>
      </value>
    </param>
  </params>
</methodResponse>
EOF
    my $result = parse($doc);
    if (!$result || ref($result) ne "HASH") {
	return "Expected hash, got " . (defined($result) ? $result : "undef");
    }
    if ((keys %$result) != 1) {
	return "Expected 1 result member, got " . scalar(keys %$result);
    }
    my $res0 = $result->{"id"};
    if (!$res0  ||  $res0 ne "1") {
        return "Expected result member 'id' to be '1', got " . (defined($res0) ? "'$res0'" : "undef");
    }
    return undef;
}

plan(tests => 5);

ok(TestBasic(), "South Dakota");
my $res = TestStrings();
ok($res, undef, $res);
$res = TestStructure();
ok($res, undef, $res);
$res = TestFault();
ok($res, undef, $res);
$res = TestLogin();
ok($res, undef, $res);

