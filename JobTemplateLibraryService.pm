package SigniantJobTemplateLibraryService; 

use SOAP::Lite;

####################################################################################
# constructor
sub new
{
    my ($class) = @_;
    my $self = {
        _baseUrl   => undef,
        _username  => undef,
        _password  => undef,
        _lastError => undef
    };
    bless $self, $class;
    return $self;
}

####################################################################################
# general setup
sub setup
{
    my ( $self, $baseUrl, $username, $password ) = @_;
    if ( $baseUrl !~ /\/$/ )
    {
        $baseUrl .= "/";
    }
    $self->baseUrl($baseUrl);
    $self->username($username);
    $self->password($password);
    $self->lastError(" ");
    return "ok";
}

####################################################################################
# returns (rc, @jobNames)

sub getJobTemplateLibraryNames
{
    my ( $self, $jobGroup, $jobName, $action ) = @_;

    my $soapCall = SOAP::Lite->proxy( $self->baseUrl . "services/JobTemplateLibraryService" )->uri("");

    # Make the SOAP call
    my $soapResult = $soapCall->getJobTemplateLibraryNames( $self->username, $self->password, $jobName, $jobGroup, $action );

    # .. and handle the result.
    if ( $soapResult->fault )
    {
        showFault( $self, $soapResult );
        return (1);
    }
    else
    {
        return ( 0, split /,/, $soapResult->result );
    }

    return ( $soapResult->result() );
}

####################################################################################
# returns (rc)
sub newJobTemplateLibrary
{
    my ( $self, $jtlName ) = @_;

    my $soapCall = SOAP::Lite->proxy( $self->baseUrl . "services/JobTemplateLibraryService" )->uri("");

    # Make the SOAP call
    my $soapResult = $soapCall->newJobTemplateLibrary( $self->username, $self->password, $jtlName );

    # .. and handle the result.
    if ( $soapResult->fault )
    {
        showFault( $self, $soapResult );
        return (1);
    }

    return ( $soapResult->result() );
    }

####################################################################################
# returns (rc)
sub importJobTemplateLibrary
{
    my ( $self, $jtlName, $jtlData ) = @_;

    my $soapCall = SOAP::Lite->proxy( $self->baseUrl . "services/JobTemplateLibraryService" )->uri("");

    # Make the SOAP call
    my $soapResult = $soapCall->importJobTemplateLibrary( $self->username, $self->password, $jtlName, $jtlData );

    # .. and handle the result.
    if ( $soapResult->fault )
    {
        showFault( $self, $soapResult );
        return ( 1, "" );
    }

    return ( 0, $soapResult->result() );
}

####################################################################################
# returns (rc, jtlXMLString)
sub exportJobTemplateLibrary
{
    my ( $self, $jtlName ) = @_;

    my $soapCall = SOAP::Lite->proxy( $self->baseUrl . "services/JobTemplateLibraryService" )->uri("");

    # Make the SOAP call
    my $soapResult = $soapCall->exportJobTemplateLibrary( $self->username, $self->password, $jtlName );

    # .. and handle the result.
    if ( $soapResult->fault )
    {
        showFault( $self, $soapResult );
        return ( 1, 0 );
    }

    return ( 0, $soapResult->result() );
}

#################################################
    sub dumpComplexHashAsString
    {
        my ( $self, $depth, %theHash ) = @_;
        my $outp     = "";
        my $depthStr = "  " x $depth;
        foreach my $key ( sort keys %theHash )
        {
            my $val = $theHash{$key};
            if ( $val =~ /HASH\(0x.*\)/ )
            {
                $outp .= $depthStr . "$key = " . $val . "\n";
                $outp .= dumpComplexHashAsString( $self, $depth + 1, %{ $theHash{$key} } );
            }
            else
            {
                $outp .= $depthStr . "$key = " . $val . "\n";
            }
        }

        return ($outp);
    }

#################################################
sub showFault
{
    my ( $self, $soapResult ) = @_;
    my $err =
    "Fault Code   : "
    . $soapResult->faultcode . "\n"
    . "Fault String : "
    . $soapResult->faultstring . "\n"
    . "Fault Detail      : "
    . $soapResult->faultdetail . "\n"
    . dumpComplexHashAsString( $self, 0, %{ $soapResult->faultdetail } ) . "\n";
    $self->lastError($err);
    print STDERR $err;
}

#################################################
############ accessor methods ###################
#################################################

#accessor method for baseUrl
sub baseUrl
{
    my ( $self, $baseUrl ) = @_;
    $self->{_baseUrl} = $baseUrl if defined($baseUrl);
    return $self->{_baseUrl};
}

#accessor method for username
sub username
{
    my ( $self, $username ) = @_;
    $self->{_username} = $username if defined($username);
    return $self->{_username};
}

#accessor method for password
sub password
{
    my ( $self, $password ) = @_;
    $self->{_password} = $password if defined($password);
    return $self->{_password};
}

#accessor method for lastError
sub lastError
{
    my ( $self, $lastError ) = @_;
    $self->{_lastError} = $lastError if defined($lastError);
    return $self->{_lastError};
}

1;
