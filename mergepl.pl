#!/usr/bin/env perl

# This is based on work that is in the public domain
# and modified by Marc Boudreau

#TODO:mpb Figure out how to do the multiple regex with strict
#use strict;
use warnings;

use File::Path;
use File::Copy;
use File::Basename;
use File::Spec;
use Getopt::Long ();
use Pod::Usage;
use XML::LibXML;
use HTML::Entities;

my $perlFilename;
my $jtlFilename;
my $noBackup;

pod2usage(-verbose => 2, -noperldoc => 1) if ( 
  @ARGV < 1 or
  ! Getopt::Long::GetOptions( 
  "f|file=s"   => \$perlFilename,       # The file containing the perl code to merge
  "nb|nobak:s" => \$noBackup,           # Don't create a backup file for the JTL
  "h|help|?"   => \$help ) or           # TODO:mpb reintegrate this. Will need to pass JTL/Start Component/Component
  (!defined $perlFilename) or
  defined $help);

# Deconstruct the perl path name
die "ERROR: Perl file [$perlFilename] does not exist" unless (-e $perlFilename);
my ($codeFile,$codePath,$codeSuf) = fileparse($perlFilename,".pl");

open PERL, "<$perlFilename" or die "ERROR: unable to open Perl file [$perlFilename]";
my @perlLines = <PERL>;
close PERL;

# Reconstruct the JTL Name
my @dirArray      = File::Spec->splitdir( $codePath );
my $jtlName       = $dirArray[0];
my $wfName        = $dirArray[1];
my $componentName = $dirArray[2];

$jtlFilename      = "$jtlName.xml";

die "ERROR: JTL file [$jtlFilename] does not exist" unless (-e $jtlFilename);

my $jtlParser     = XML::LibXML->new(); 
my $jtlXmlDoc     = $jtlParser->parse_file( $jtlFilename );
my $jtlXmlContext = XML::LibXML::XPathContext->new( $jtlXmlDoc );

my $componentNode = $jtlXmlContext->findnodes(
    "/workflow[\@name=\"$jtlName\"]/jobTemplateComponents[\@name=\"$wfName\"]//links/task[\@name=\"$componentName\"]/property[\@name=\"Commands\"]/property[\@name=\"$codeFile\"]/value");

die "ERROR: Component not found" if ($componentNode->size() eq 0);
die "ERROR: More than one component found" if ($componentNode->size() > 1);

foreach my $node ( $componentNode->get_nodelist ) {
    $node->removeChildNodes();
    $node->appendText("@perlLines");
}

copy($jtlFilename,$jtlFilename.".bak") unless (defined $noBackup);

$jtlXmlDoc->toFile($jtlFilename,1);

__END__

=head1 NAME

merge.pl - Merge perl into JTL

=head1 SYNOPSIS

merge.pl [options]

 Options:
    -f -file         Perl input file
    -nb -nobak       no backup
    -help            brief help message

=head1 OPTIONS

=over 8

=item B<-file>

The file containing the Perl code to merge

=item B<-nobak>

Skip creating a backup for the original JTL

=item B<-help>

Prints this page and exits.

=back

=head1 DESCRIPTION

B<This program> will read the given specified perl file and merge it into the 
 appropriate JTL file in the current directory.  The 'Start Component' and the 'Component' names are determined from the path relative to the current directory.  

 i.e. the file must be in JTL/Start Component/Component/tgt_proc_cmd.pl

 NOTE: The output XML will have quotes ("" and '') in the output Perl.
This is OK in standard XML. For "best" results, import into a manager
and re-export if you are worried about the output.

 The output XML will also have self-terminated tags (<value/> vs
<value></value>). The Signiant manager doesn't do this. Again, this is OK.

=cut
