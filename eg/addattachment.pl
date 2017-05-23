#!/usr/bin/env perl
#
use strict;
use warnings;

use Data::Printer;

use BZ::Client;
use BZ::Client::Bug;
use BZ::Client::Bug::Attachment;

my $bz = BZ::Client->new(
    'api_key' => '8k2xZlv666WTk0hCtJtuFqcRecwpo3lHG0GJefqp',
    url => 'https://landfill.bugzilla.org/bugzilla-5.0-branch/',
);

# my $file = '/tmp/609299a1128b20719e1ce667a0b10bd8bd11267167e1ab5fbe3af6fb74cd30f9.jpg';
my $file = '/tmp/tmp_1d22790aad18814436feed62a2444402_tPF7H2_html_m6df54da1.png';

eval {

my $bug = BZ::Client::Bug::Attachment->add( $bz,
{
ids => 42508,
file_name => $file,
summary => 'Hello',
content_type => 'image/png',
} );

p $bug;

};
if ($@) {
p $@
}

#my $attachment = $bug->{bugs}->{42508}->[0];

# p $attachment;

#my $data = $attachment->data();

# p $data;





