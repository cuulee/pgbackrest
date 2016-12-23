####################################################################################################################################
# HostTest.pm - Encapsulate a docker host for testing
####################################################################################################################################
package pgBackRestTest::Common::HostTest;

####################################################################################################################################
# Perl includes
####################################################################################################################################
use strict;
use warnings FATAL => qw(all);
use Carp qw(confess);

use Cwd qw(abs_path);
use Exporter qw(import);
    our @EXPORT = qw();

use pgBackRest::Common::Log;
use pgBackRest::Common::String;

use pgBackRestTest::Common::ExecuteTest;

####################################################################################################################################
# new
####################################################################################################################################
sub new
{
    my $class = shift;          # Class name

    # Create the class hash
    my $self = {};
    bless $self, $class;

    # Assign function parameters, defaults, and log debug info
    (
        my $strOperation,
        $self->{strName},
        $self->{strContainer},
        $self->{strImage},
        $self->{strUser},
        $self->{strOS},
        $self->{stryMount}
    ) =
        logDebugParam
        (
            __PACKAGE__ . '->new', \@_,
            {name => 'strName', trace => true},
            {name => 'strContainer', trace => true},
            {name => 'strImage', trace => true},
            {name => 'strUser', trace => true},
            {name => 'strOS', trace => true},
            {name => 'stryMount', required => false, trace => true}
        );

    executeTest("docker rm -f $self->{strContainer}", {bSuppressError => true});

    executeTest("docker run -itd -h $self->{strName} --name=$self->{strContainer}" .
                (defined($self->{stryMount}) ? ' -v ' . join(' -v ', @{$self->{stryMount}}) : '') .
                " $self->{strImage}");

    # Get IP Address
    $self->{strIP} = trim(executeTest("docker inspect --format '\{\{ .NetworkSettings.IPAddress \}\}' $self->{strContainer}"));
    $self->{bActive} = true;

    # Return from function and log return values if any
    return logDebugReturn
    (
        $strOperation,
        {name => 'self', value => $self, trace => true}
    );
}

####################################################################################################################################
# remove
####################################################################################################################################
sub remove
{
    my $self = shift;

    # Assign function parameters, defaults, and log debug info
    my ($strOperation) = logDebugParam(__PACKAGE__ . '->remove');

    if ($self->{bActive})
    {
        executeTest("docker rm -f $self->{strContainer}", {bSuppressError => true});
        $self->{bActive} = false;
    }

    # Return from function and log return values if any
    return logDebugReturn($strOperation);
}


####################################################################################################################################
# execute
####################################################################################################################################
sub execute
{
    my $self = shift;

    # Assign function parameters, defaults, and log debug info
    my
    (
        $strOperation,
        $strCommand,
        $oParam,
        $strUser
    ) =
        logDebugParam
        (
            __PACKAGE__ . '->execute', \@_,
            {name => 'strCommand'},
            {name => 'oParam', required=> false},
            {name => 'strUser', required => false}
        );

    # Set the user
    if (!defined($strUser))
    {
        $strUser = $self->{strUser};
    }

    $strCommand =~ s/'/'\\''/g;

    my $oExec = new pgBackRestTest::Common::ExecuteTest(
        "docker exec -u ${strUser} $self->{strContainer} sh -c '${strCommand}'" , $oParam);

    # Return from function and log return values if any
    return logDebugReturn
    (
        $strOperation,
        {name => 'oExec', value => $oExec, trace => true}
    );
}

####################################################################################################################################
# executeSimple
####################################################################################################################################
sub executeSimple
{
    my $self = shift;

    # Assign function parameters, defaults, and log debug info
    my
    (
        $strOperation,
        $strCommand,
        $oParam,
        $strUser
    ) =
        logDebugParam
        (
            __PACKAGE__ . '->executeSimple', \@_,
            {name => 'strCommand', trace => true},
            {name => 'oParam', required=> false, trace => true},
            {name => 'strUser', required => false, trace => true}
        );

    my $oExec = $self->execute($strCommand, $oParam, $strUser);
    $oExec->begin();
    $oExec->end();

    # Return from function and log return values if any
    return logDebugReturn
    (
        $strOperation,
        {name => 'strOutLog', value => $oExec->{strOutLog}, trace => true}
    );
}

####################################################################################################################################
# copyTo
####################################################################################################################################
sub copyTo
{
    my $self = shift;

    # Assign function parameters, defaults, and log debug info
    my
    (
        $strOperation,
        $strSource,
        $strDestination,
        $strOwner,
        $strMode
    ) =
        logDebugParam
        (
            __PACKAGE__ . '->copyTo', \@_,
            {name => 'strSource'},
            {name => 'strDestination'},
            {name => 'strOwner', required => false},
            {name => 'strMode', required => false}
        );

    executeTest("docker cp ${strSource} $self->{strContainer}:${strDestination}");

    if (defined($strOwner))
    {
        $self->executeSimple("chown ${strOwner} ${strDestination}", undef, 'root');
    }

    if (defined($strMode))
    {
        $self->executeSimple("chmod ${strMode} ${strDestination}", undef, 'root');
    }

    # Return from function and log return values if any
    return logDebugReturn($strOperation);
}

####################################################################################################################################
# copyFrom
####################################################################################################################################
sub copyFrom
{
    my $self = shift;

    # Assign function parameters, defaults, and log debug info
    my
    (
        $strOperation,
        $strSource,
        $strDestination
    ) =
        logDebugParam
        (
            __PACKAGE__ . '->copyFrom', \@_,
            {name => 'strSource'},
            {name => 'strDestination'}
        );

    executeTest("docker cp $self->{strContainer}:${strSource} ${strDestination}");

    # Return from function and log return values if any
    return logDebugReturn($strOperation);
}

####################################################################################################################################
# ipGet
####################################################################################################################################
sub ipGet
{
    my $self = shift;

    return $self->{strIP};
}

####################################################################################################################################
# nameGet
####################################################################################################################################
sub nameGet
{
    my $self = shift;

    return $self->{strName};
}

####################################################################################################################################
# nameTest
####################################################################################################################################
sub nameTest
{
    my $self = shift;
    my $strName = shift;

    return $self->{strName} eq $strName;
}

####################################################################################################################################
# userGet
####################################################################################################################################
sub userGet
{
    my $self = shift;

    return $self->{strUser};
}

1;
