#!/usr/bin/env perl

# This is based on work that is in the public domain
# and modified by Marc Boudreau
use strict;
use warnings;

require JobTemplateLibraryService;

package main;

use Getopt::Long ();
use File::Basename;
use Pod::Usage;

my $jtlName;
my $jtlFilename;
my $mgr;
my $passwd;
my $user;
my $help;

pod2usage(-verbose => 2, -noperldoc => 1) if ( 
  @ARGV < 4 or
  ! Getopt::Long::GetOptions( 
  "j|jtl:s"         => \$jtlName,     # The Job Template Library name
  "f|file=s"        => \$jtlFilename, # The file to read the JTL from
  "m|mgr=s"         => \$mgr,         # The Signiant manager name
  "p|pwd=s"         => \$passwd,      # The password for the user
  "u|usr=s"         => \$user,        # The username to connect to the manager
  "h|help|?"        => \$help ) or
  (!defined $mgr)               or
  (!defined $jtlFilename)       or
  (!defined $user)              or
  (!defined $passwd)            or
  defined $help);

die "ERROR: [$jtlFilename] Does not exist" if (!-e $jtlFilename);

my ( $tmpName, $jtlPath, $jtlSuf ) = fileparse($jtlFilename,".xml");

$jtlName = $tmpName if (!defined $jtlName);

open( JTLFILE, "<$jtlFilename" ) or die "ERROR: unable to open [$jtlFilename.xml]";
my @jtlLines = <JTLFILE>;
close JTLFILE;

my $soap = new SigniantJobTemplateLibraryService();
$soap->setup( "http://$mgr/signiant/", $user, $passwd ) or die "ERROR: Unable to create SOAP connection";

my $err = $soap->importJobTemplateLibrary($jtlName,"@jtlLines");
__END__

=head1 NAME

putJTL.pl - Run a Signiant perl file

=head1 SYNOPSIS

putJTL.pl [options]

 Options:
    -j -jtl           Job Template Library name (optional)
    -f -file          Job Template Library XML file
    -m -mgr           Signiant manager hostname
    -u -usr           Signiant username
    -p -pwd           Signiant password
    -help             brief help message
 
=head1 OPTIONS

=over 8

=item B<-jtl> 

The name of the Job Template Library to store the XML as. If this is not provided, the name will be determined from the filename provided.

=item B<-file>

Perform all the specified substitutions and start the program in the perl debugger.

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

B<This program> will connect to a Signiant manager and upload the specified XML file as a Job Template Library.
 NOTE: This connection can be slow.

=cut
