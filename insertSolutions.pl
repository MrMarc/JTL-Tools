#!/usr/bin/env perl

# This is based on work that is in the public domain
# and modified by Marc Boudreau

#TODO:mpb Figure out how to do the multiple regex with strict
#use strict;
use warnings;

use File::Path;
use Getopt::Long ();
use XML::LibXML;
use Pod::Usage;

my $solutionsFile;
my $variableFile;
my $sigperlFile;
my $outputFile;
my $help;
my $quiet;

my $solutionParser;
my $solutionXmlDoc;
my $solutionXmlContext;

my $variableParser;
my $variableXmlDoc;
my $variableXmlContext;

sub performSubstitution() {
	my $line = $_;
    my $substitution;

    if (($line =~ m/%script_lib_obj:(.*)%/) ) {
        # If the line starts with a script library token
        # then replace it with the corresponding script library
        # By spec. this is only one per line

        return ($solutionXmlContext->find("//CODE_SNIPPET[\@NAME=\"$1\"]")."\n") if (defined $solutionXmlContext);
    }
    elsif ($line =~ m/%(\D.*?)%/) {
        # In case there are multiple variables on the line
        foreach my $expr (1..$#-) {
            next if (${$expr} =~ m/dds_property/);      # Skip warnings about outputs and other not so useful things 
            my $variableToken = ${$expr};

            if (defined $variableXmlContext) {
                $substitution = $variableXmlContext->findvalue("//variable[\@name=\"\%$variableToken\%\"]");
            }

            # TODO:mpb Fix this
            # Looking for problems with strftime tokens

            if (defined $substitution) {
                $line =~ s/%$variableToken%/$substitution/g;
            }
            elsif (defined $variableFile) {
                print STDERR "WARNING: No substitution found for: [\%${$expr}\%]\n" unless (defined $quiet);
            }
        }
    }
    return $line;
}

pod2usage(-verbose => 2, -noperldoc => 1) if ( 
  ! Getopt::Long::GetOptions( 
  "s|solution|script:s" => \$solutionsFile, # The xml containing the Signiant solutions scripts
  "v|variables|var:s"   => \$variableFile,  # The xml containing the variable substitutions. Not substituted if not provided
  "i|input|in:s"        => \$sigperlFile,   # The Signiant perl source (default: STDIN)
  "o|output|out:s"      => \$outputFile,    # where to put the perl output (default: STDOUT)
  "q|quiet"             => \$quiet,         # Don't output STDERR messages (except for Usage)
  "h|help|?"            => \$help ) or
  defined $help);

$outputFile  = "-" if (!defined $outputFile);  # default to STDOUT
$sigperlFile = "-" if (!defined $sigperlFile); # default to STDIN

if (defined $solutionsFile) {
    # Open the Solutions File and get ready to parse it...
    $solutionParser     = XML::LibXML->new(); 
    $solutionXmlDoc     = $solutionParser->parse_file( $solutionsFile );
    $solutionXmlContext = XML::LibXML::XPathContext->new( $solutionXmlDoc );
}
else {
    print STDERR "WARNING: No Solution Script file provided.\n" unless (defined $quiet);
}

if (defined $variableFile) {
    # Open the Variable File and get ready to parse it...
    $variableParser     = XML::LibXML->new(); 
    $variableXmlDoc     = $variableParser->parse_file( $variableFile );
    $variableXmlContext = XML::LibXML::XPathContext->new( $variableXmlDoc );
}
else {
    print STDERR "WARNING: No Variable file provided.\n" unless (defined $quiet);
}

open CODEFILE, "<$sigperlFile" or die "ERROR: Unable to open $sigperlFile\n";
my @lines = <CODEFILE>;
close CODEFILE;

@lines = map { &performSubstitution } @lines;

open OUTFILE,  ">$outputFile" or die "ERROR: Unable to open $outputFile\n";
print OUTFILE @lines;
close OUTFILE;
__END__

=head1 NAME

insertSolutions.pl - Run a Signiant perl file

=head1 SYNOPSIS

insertSolutions.pl [options]

 Options:
    -f -file          Perl input file
    -d -debug         run in debugger
    -dds              use dds_perl
    -ns -noscript     skip insertion of Solution Scripts
    -nv -novariables  skip insertion of the variables
    -show             output code to STDOUT
    -help             brief help message
 
=head1 OPTIONS

=over 8

=item B<-file> (required)

The file containing the Perl script to run.

=item B<-debug>

Perform all the specified substitutions and start the program in the perl debugger.

=item B<-dds>

Run/debug the script with dds_perl (as opposed to the default Perl on the system).

=item B<-noscript>

Perform all other specified substitutions except the insertion of the code in SolutionsScripts.xml.

=item B<-novariable>

Perform all other specified substitutions except the insertion of the variables specified in the corresponding variables file.

=item B<-show>

Perform the specified substitutions and output the resulting script to STDOUT instead of running it.
 
=item B<-help>

Prints this page and exits.

=back

=head1 DESCRIPTION

B<This program> will read the given specified perl script and merge the required elements from the SolutionsScript.xml and the corresponding variable file.
 The resultant file will be run using the system default Perl.

=cut
