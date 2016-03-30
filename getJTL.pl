#!/usr/bin/env perl

# This is based on work that is in the public domain
# and modified by Marc Boudreau
use strict;
use warnings;
 
# find the directory this script is running in and add it to the list of library locations (@INC)
# to look into so that require JobTemplateLibraryService module below can be in the same current 
#directory as this script
use FindBin qw($Bin);
use lib $Bin;

require JobTemplateLibraryService;

package main;

use Getopt::Long;
use Pod::Usage;

my $jtlName;
my $mgr;
my $passwd;
my $user;
my $help;

pod2usage(-verbose => 2, -noperldoc => 1) if ( 
  @ARGV < 4 or
  !GetOptions( 
  "j|jtl=s"         => \$jtlName,     # The Job Template Library name
  "m|mgr=s"         => \$mgr,         # The Signiant manager name
  "p|pwd=s"         => \$passwd,      # The password for the user
  "u|usr=s"         => \$user,        # The username to connect to the manager
  "h|help|?"        => \$help ) or
  (!defined $jtlName) or
  (!defined $mgr)     or
  (!defined $passwd)  or
  (!defined $user)    or
  defined $help);

my $soap = new SigniantJobTemplateLibraryService();
$soap->setup( "http://$mgr/signiant/", $user, $passwd ) or die "ERROR: Unable to create SOAP connection";

my ( $err, $jtlXML ) = $soap->exportJobTemplateLibrary($jtlName);

die "ERROR: JTL export [$jtlName] returns error [$err]" if ($err);

open( JTLFILE, ">$jtlName.xml" ) or die "ERROR: unable to create [$jtlName.xml]";
print JTLFILE $jtlXML;
close JTLFILE;
__END__

=head1 NAME

getJTL.pl - Get the XML for a JTL

=head1 SYNOPSIS

getJTL.pl [options]

 Options:
    -j -jtl           Job Template Library name
    -m -mgr           Signiant manager name
    -u -usr           username
    -p -pwd           password
    -help             brief help message
 
=head1 OPTIONS

=over 8

=item B<-jtl>

The name of the Job Template Library (JTL)to retreive.

=item B<-mgr>

The hostname of the Signiant manager to retreive the JTL from.

=item B<-usr>

The Signiant username to connect to the specified manager.

=item B<-pwd>

The Signiant password for the specified user.

=item B<-help>

Prints this page and exits.

=back

=head1 DESCRIPTION

B<This program> will connect to a Signiant manager and download the specified Job Template Library
 to a file in the local directory. NOTE: This connection can be slow.

=cut
