#!/usr/bin/env perl

# This is based on work that is in the public domain
# and modified by Marc Boudreau
use strict;
use warnings;

use File::Basename;
use Getopt::Long ();
use Pod::Usage;
use HTML::Entities;

my $folder;
my $help;
my $encode;
my $oneLine;

my $outputFileHandle;
my $outputFileName;

my ($cmd, $path, $suf) = fileparse($0,".pl");

pod2usage(-verbose => 2, -noperldoc => 1) if (
    ! Getopt::Long::GetOptions( 
    "d|dir=s"                  => \$folder,
    "e|encode"                 => \$encode,
    "1"                        => \$oneLine,
    "h|help|?"                 => \$help ) or
    defined $help);

my @files;

@files = `ls $folder/*` if (defined $folder);
$folder = '' if (!defined $folder);

my $siglist;

$siglist = "<SIGLIST TYPE='PATHLIST' XATTRS='".$folder."'>\n";

foreach my $file (@files) {
    chomp($file);
    #my $fullFile = "$folder/$file";
    my $fullFile = $file;
    # TODO:mpb make this work with directories as well
    next if (!-f $fullFile);
    $siglist .= "<EL S='". (-s $fullFile) . "'";
    $siglist .= " T='F'";
    # TODO:mpb Fix MT='modtime'
    #$siglist .= " MT='". (-M $fullFile) . "'";
    $siglist .= " MT='2012-03-28T03:36:07Z'";
    $siglist .= " V='".$file."'/>\n";
}

$siglist .= "</SIGLIST>\n";

$siglist = encode_entities($siglist) if (defined $encode);
$siglist =~ s/\n//g if (defined $oneLine);

print $siglist;

__END__

=head1 NAME

sigLs.pl - Create a SIGXML listing for a directory

=head1 SYNOPSIS

sigLs.pl [options]

 Options:
    -d -dir           directory
    -e -encode        perform an HTML entity encoding
    -help             brief help message
 
=head1 OPTIONS

=over 8

=item B<-dir> 

The directory to create the SIGLIST XML for

=item B<-encode> 

Encode the output with HTML entities encoded

=item B<-1> 

Output on one line

=item B<-help>

Prints this page and exits.

=back

=head1 DESCRIPTION

B<This program> creates a SIGXML listing for the specified directory.
The listing may be optionally HTML encoded.

=cut
