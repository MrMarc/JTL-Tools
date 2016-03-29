#!/usr/bin/env perl

# This is based on work that is in the public domain
# and modified by Marc Boudreau
#use strict;
use warnings;

use File::Path;
use XML::LibXML;
use Getopt::Long ();
use Pod::Usage;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Data::Dumper;

my $xmlFilename = "-"; # Use STDIN as the default
my $help;
my $componentName;
my $cmdName;
my $quiet;
my $nuke;
my $skip;

# The following xPath gives all the component commands that are in a given 
# workflow JTL as of version 9 (and probably version 8)
# NOTE: there are some strangenesses of Signiant JTLs that require the '//'
my $xpath = "//task";

sub makeApplicationXML {
    my $name    = $_[0];
    my $version = $_[1];

    my $xml =<<"__XML__";
<?xml version="1.0" encoding="UTF-8"?>
<application display="$name" dtm_version="10.0.0.0"
  name="$name Application" version="$version">
  <install>
    <component display="$name" plugin="components/$name.xml"/>
  </install>
  <uninstall>
    <component display="$name" plugin="components/$name.xml"/>
  </uninstall>
  <feature_id/>
</application>
__XML__

    return $xml;
}

pod2usage(-verbose => 2, -noperldoc => 1) if (
    ! Getopt::Long::GetOptions( 
    "j|jtl:s"       => \$xmlFilename,   # The xml containing the JTL (defaults to STDIN)
    "comp:s"        => \$componentName, # The components desired (default all)
    "q|quiet"       => \$quiet,         # Don't output STDERR messages (except for Usage)
    "n|nuke"        => \$nuke,          # Don't create backup files
    "h|help|?"      => \$help ) or
    defined $help);

open XMLFILE, "<$xmlFilename" or die "ERROR: Unable to open $xmlFilename";
my @lines = <XMLFILE>;
close XMLFILE;

my $parser     = XML::LibXML->new();
my $xmlDoc     = $parser->parse_string( "@lines" );
my $xmlContext = XML::LibXML::XPathContext->new( $xmlDoc );
my $nodes      = $xmlContext->findnodes( $xpath );

if ( $nodes->size() ) {
    foreach my $node ( $nodes->get_nodelist ) {

        my $currentComponentName = $node->findvalue("\@componentType"); # Use the relative operators to get around the property within a property issue
        my $prettyName           = $node->findvalue("\@description");
        my $name                 = $node->findvalue("\@name");
        my $version              = $node->findvalue("\@version");
        my $text                 = $node->findvalue("self::value");

        if (defined $componentName) {
            next if ($componentName ne $currentComponentName);
        }
        $DB::single = 1;

        my $file = "$currentComponentName"."_$version.zip";
        print STDERR "Writing: $file | $currentComponentName | $prettyName\n" unless (defined $quiet);

        # Write the code to a file - Backup the old one
        if (-e $file) {
            rename "$file", "$file.bak" unless (defined $nuke);
        }

        my $zip = Archive::Zip->new();

        # Create the application.xml file
        my $appXML = $zip->addString( makeApplicationXML($currentComponentName,$version), 'application.xml' );
        $appXML->desiredCompressionMethod( COMPRESSION_DEFLATED );

        # Make the component sub-directory
        my $componentDir = $zip->addDirectory( 'components/' );

        $DB::single = 1;
        my $nodeText = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' . "\n" . $node;
        $nodeText =~ s/\<task/\<component/g;
        $nodeText =~ s/\<\/task/\<\/component/g;

        # Gets ride of Wide Characters - happens occasionally
        $nodeText =~ s/[^\x00-\x7f]//g;

        # Create the application.xml file
        my $componentXML = $zip->addString( $nodeText, "components/$currentComponentName.xml" );
        $componentXML->desiredCompressionMethod( COMPRESSION_DEFLATED );

        unless ($zip->writeToFileNamed($file) == AZ_OK) {
            die "Unable to write Zip file\n";
        }
    }
}
__END__

=head1 NAME

writeComponents.pl - create installable components from a Job Template Library

=head1 SYNOPSIS

writeComponents.pl [options]

 Options:
    -j -jtl           xml containing the JTL (defaults to STDIN)
    -comp             desired component (default all)
    -n -nuke          skip creation of backup files
    -q -quiet         don't output STDERR messages
    -help             brief help message
 
=head1 OPTIONS

=over 8

=item B<-jtl>

The xml file containing the Job Template library (STDIN by default).

=item B<-comp>

The name of the specific component to be extracted. By default all components are extracted.

=item B<-nuke>

Do not create a backup of any existing Perl files.

=item B<-quiet>

Don't output error messages.
 
=item B<-help>

Prints this page and exits.

=back

=head1 DESCRIPTION

B<This program> will read the specified JTL file and extract the requested components. 

 If files already exist in the folder, a backup is made of the code file and any NEW inputs in the JTL are merged with any existing input file.

=cut
