use 5.010000;
use ExtUtils::MakeMaker;

use Getopt::Long();
use Data::Dumper();

sub Usage(;$) {
    my $msg = shift;
    if ($msg) {
        print STDERR "$msg\n\n";
    }
    print STDERR <<"USAGE";
Usage: perl $0 <options>

Possible options are:
  --logDirectory=<directory>  Configures the log directory, where
                              XML-RPC requests and responses are being
                              logged.
  --testUrl=<url>             Configures the Bugzilla server to use for
                              integration tests.
  --testUser=<user>           Configures the Bugzilla user to use for
                              integration tests.
  --testPassword=<password>   Configures the Bugzilla password to use for
                              integration tests.
USAGE
    exit 1;
}

my($testUrl, $testUser, $testPassword, $logDirectory);
Getopt::Long::GetOptions(
    'help' => \&Usage,
    'logDirectory=s' => \$logDirectory,
    'testUrl=s' => \$testUrl,
    'testUser=s' => \$testUser,
    'testPassword=s' => \$testPassword
    ) || die Usage();

my $config = {
    logDirectory => $logDirectory,
    testUser => $testUser,
    testUrl => $testUrl,
    testPassword => $testPassword
};

my $configFile = 't/config.pl';
open(my $fh, '>', $configFile)
    or die "Failed to create $configFile: $!";
(print $fh Data::Dumper->new([$config])->Indent(1)->Terse(1)->Dump())
    or die "Failed to write to $configFile: $!";
close($fh)
    or die "Failed to close $configFile: $!";

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'BZ::Client',
    VERSION_FROM      => 'lib/BZ/Client.pm', # finds $VERSION
    PREREQ_PM         => { 'XML::Parser' => 0, 'XML::Writer' => 0, 'URI' => 0, 'DateTime::Format::ISO8601' => 0 }, # e.g., Module::Name => 1.1
    ABSTRACT          => 'BZ::Client - A client for the Bugzilla web services API.',
    AUTHOR            => 'Jochen Wiedmann <jochen.wiedmann@gmail.com>',
);
