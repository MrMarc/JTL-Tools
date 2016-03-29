#!/usr/bin/env perl

# This is based on work that is in the public domain
# and modified by Marc Boudreau
use strict;
use warnings;

use File::Temp qw/ tempfile /;
use File::Basename;
use Getopt::Long ();
use Pod::Usage;

my $perlFilename;
my $help;
my $runDebugger;
my $useDDS;
my $useDDD;
my $showCode;
my $makeCode;
my $noSolutions;
my $noVariables;

my $outputFileHandle;
my $outputFileName;

my ($cmd, $path, $suf) = fileparse($0,".pl");

pod2usage(-verbose => 2, -noperldoc => 1) if (
    ! Getopt::Long::GetOptions( 
    "f|file=s"                 => \$perlFilename,   # The file containing the code to run (required)
    "d|debug"                  => \$runDebugger,    # Run code in the debugger (default: no)
    "ddd"                      => \$useDDD,         # Use the ddd debugger
    "dds"                      => \$useDDS,         # Use the Signiant dds_perl
    "ns|noscript"              => \$noSolutions,    # Don't insert the xml containing the Signiant solutions scripts
    "nv|novariables"           => \$noVariables,    # Don't insert the xml containing the variable substitutions. Not substituted if not provided
    "show"                     => \$showCode,       # Output code to STDOUT - don't run (default: no)
    "code"                     => \$makeCode,       # Output code to File - don't run (default: no)
    "h|help|?"                 => \$help ) or
    (!defined $perlFilename) or
    defined $help);

my ($codeFile,$codePath,$codeSuf) = fileparse($perlFilename,".pl");

if ((defined $noSolutions) or
    (defined $noVariables)) {
    $showCode = 1;  # Makes sure the we display the code
}
elsif (!defined $showCode) {
    ($outputFileHandle,$outputFileName) = tempfile( "tmpXXXX" , SUFFIX => '.pl');
}

# Build the command line
my $solutionsCmdLine = "\"$path"."insertSolutions.pl\" -i=\"$perlFilename\"";

$solutionsCmdLine .= " -s=\"$path"."SolutionsScripts.xml\"" if (!defined $noSolutions);
$solutionsCmdLine .= " -v=\"$codePath"."$codeFile".".in\""  if (!defined $noVariables);
$solutionsCmdLine .= " -o=\"$outputFileName\""              if (defined $outputFileName);

system($solutionsCmdLine) == 0 or die "ERROR: Unable to perform variable substitution\n";

# empty outputFileName should show the code on the screen

print "Output File: [$outputFileName]" if ($makeCode);

if ( (!defined $makeCode) and (!defined $showCode) and (defined $outputFileName)) {
    # Means we want to run/debug the code
    my $options;
    $options = 'export PERL5LIB=~/signiant/dds/bin;'; # make sure the perl code in the ddsbin directory can be found
    $options = '~/signiant/dds/bin/perl/bin/perl' if (defined  $useDDS);
    $options = 'perl'                                if (!defined $useDDS);

    $options .= ' -d'                                if (defined  $runDebugger);

    $options = 'ddd'                                 if (defined  $useDDD);

    system("$options $outputFileName");
    unlink($outputFileName);
}
__END__

=head1 NAME

sigRun.pl - Run a Signiant perl file

=head1 SYNOPSIS

sigRun.pl [options]

 Options:
    -f -file          Perl input file
    -d -debug         run in debugger
    -ddd              debug using ddd
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
 
=item B<-code>

Perform the specified substitutions and output the resulting script to a temporary file instead of running it.
 
=item B<-help>

Prints this page and exits.

=back

=head1 DESCRIPTION

B<This program> will read the given specified perl script and merge the required elements from the SolutionsScript.xml and the corresponding variable file.
 The resultant file will be run using the system default Perl.

=cut
