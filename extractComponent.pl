#!/usr/bin/env perl

# This is based on work that is in the public domain
# and modified by Marc Boudreau
#use strict;
use warnings;

use File::Path;
use XML::LibXML;
use Getopt::Long ();
use Pod::Usage;
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
my $xpath = "/component//property[\@name=\"Commands\"]/property";

pod2usage(-verbose => 2, -noperldoc => 1) if (
    ! Getopt::Long::GetOptions( 
    "cmd:s"         => \$cmdName,       # The component commands (default all)
    "q|quiet"       => \$quiet,         # Don't output STDERR messages (except for Usage)
    "s|skip"        => \$skip,          # Don't create the variables file
    "n|nuke"        => \$nuke,          # Don't create backup files
    "f|file=s"      => \$xmlFilename,   # The xml containing the component (defaults to STDIN)
    "h|help|?"      => \$help ) or
    defined $help);

$DB::single = 1;
open XMLFILE, "<$xmlFilename" or die "ERROR: Unable to open $xmlFilename";
my @lines = <XMLFILE>;
close XMLFILE;

$DB::single = 1;

my $parser     = XML::LibXML->new();
my $xmlDoc     = $parser->parse_string( "@lines" );
my $xmlContext = XML::LibXML::XPathContext->new( $xmlDoc );
my $nodes      = $xmlContext->findnodes( $xpath );

$DB::single = 1;

if ( $nodes->size() ) {
    foreach my $node ( $nodes->get_nodelist ) {

        my $currentComponentName = $node->findvalue("../../\@name"); # Use the relative operators to get around the property within a property issue
        my $prettyName           = $node->findvalue("\@displayName");
        my $name                 = $node->findvalue("\@name");
        my $code                 = $node->findvalue("child::value");

        if (defined $componentName) {
            next if ($componentName ne $currentComponentName);
        }

        if (defined $cmdName) {
            # TODO:mpb Turn this into an array?
            next if ($cmdName ne $name);
        }

        print STDERR "Writing: $currentComponentName | $prettyName\n" unless (defined $quiet);
        my $path = "./$currentComponentName";

        mkpath($path);
        if (-d $path) {
            # Write the code to a file - Backup the old one
            if (-e "$path/$name.pl") {
                rename "$path/$name.pl", "$path/$name.pl.bak" unless (defined $nuke);
            }
            # The input XML is encoded with a newline followed by a space
            # Get rid of the space
            $code =~ s/\n /\n/g;

            open  CODEFILE, ">", "$path/$name.pl";
            print CODEFILE $code;
            close CODEFILE;

            next if (defined $skip); # Skip the inputs file

            # Create the template input file when it doesn't already exist
            # Merge any new values if it does
            my $inputFile = "$path/$name.in";
            my %variables;

            if (-e $inputFile) {
                open  OLDVARIABLES, "<", "$inputFile";
                my @oldLines = <OLDVARIABLES>;
                close OLDVARIABLES;

                my $oldParser     = XML::LibXML->new();
                my $oldXmlDoc     = $parser->parse_string( "@oldLines" );
                my $oldXmlContext = XML::LibXML::XPathContext->new( $oldXmlDoc );

                my $oldVarNodes   = $oldXmlContext->find("//variable");
                foreach my $oldNode ($oldVarNodes->get_nodelist()) {
                    $variables{$oldNode->findvalue("\@name")} =
                        $oldNode->findvalue("text()");
                }
            }

            foreach my $line (split /\n/ ,$code) {
                if ($line =~ m/(%.*%)/) {
                    my $var = $1;
                    next if ($var =~ m/%dds_/);
                    next if ($var =~ m/%script_lib_obj/);
                    next if ($var =~ m/%.*%.*%/); 
                    next if ($var !~ m/%[a-zA-Z0-9_\.]*%/); 

                    $variables{$var} = '' if (!defined $variables{$var});
                    $variables{'%sp_log_severity%'} = 'INFO' if (!defined $variables{'%sp_log_severity%'});
                }
            }

            # Create the XML document for the variables
            my $variablesDoc  = XML::LibXML::Document->new();
            my $variablesRoot = $variablesDoc->createElement("variables");

            for my $var (sort keys %variables) {
                my $tag = $variablesDoc->createElement("variable");
                $tag->setAttribute('name'=> "$var");
                $tag->appendTextNode($variables{$var});
                $variablesRoot->appendChild($tag);
            }
            $variablesDoc->setDocumentElement($variablesRoot);

            open  VARIABLESFILE, ">", "$inputFile";
            print VARIABLESFILE $variablesDoc->toString(1);
            close VARIABLESFILE;
        }
    }
}
__END__

=head1 NAME

extractpl.pl - retrieve Perl code from a Job Template Library

=head1 SYNOPSIS

extractComponent.pl [options]

 Options:
    -f -file          xml containing the Component (defaults to STDIN)
    -cmd              desired component command (default all)
    -s -skip          skip creation of variables file
    -n -nuke          skip creation of backup files
    -q -quiet         don't output STDERR messages
    -help             brief help message
 
=head1 OPTIONS

=over 8

=item B<-file>

The xml file containing the component (STDIN by default).


=item B<-cmd>

The name of the specific command to be extracted. By default all components are extracted.

=item B<-skip>

Skip creation of the variables substitution file.

=item B<-nuke>

Do not create a backup of any existing Perl files.

=item B<-quiet>

Don't output error messages.
 
=item B<-help>

Prints this page and exits.

=back

=head1 DESCRIPTION

B<This program> will read the specified component XML file and extract the specified commands. It will also create a file that will list all Signiant input variables that are in the script.
 The scripts will be placed in sub-directories beneath the current directory. The folder structure will be:

 ./<Component>/<Command>.pl (code)
 ./<Component>/<Command>.in (inputs - in XML)

 If files already exist in the folder, a backup is made of the code file and any NEW inputs are merged with any existing input file.

=cut
