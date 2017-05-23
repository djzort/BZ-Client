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

my $bug = BZ::Client::Bug::Attachment->get( $bz, { ids => 42508 } );

my $attachment = $bug->{bugs}->{42508}->[0];

# p $attachment;

my $data = $attachment->data();

# p $data;

open( my $raw, '>', '/tmp/raw.jpg');
binmode $raw;
print $raw $data->raw();
close $raw;
printf("Length is %d\n", length($data->raw));

open( my $base64, '>', '/tmp/base64.jpg');
print $base64 $data->base64();
close $base64;
printf("Length is %d\n", length($data->base64));




