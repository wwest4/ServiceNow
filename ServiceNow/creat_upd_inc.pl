#!/usr/bin/env perl -w
#
# Prereqs:
# * ServiceNow Perl API (manual install, unfortunately)
# * SOAP::Lite (prerequisites http://soaplite.com/prereqs.html) 0.71 or later
# * MIME::Types
# * Readonly
# * version
#
# william.west@yale.edu
#
use strict;
use warnings;
use version; our $VERSION = qv('1.0.0');
use ServiceNow;
use ServiceNow::Configuration;
use ServiceNow::ITIL::Incident;
use Sys::Hostname;
use Time::Local;
use English qw(-no_match_vars);
use Readonly;

use vars qw($INSTANCE $USERNAME $PASSWORD $SHORT_DESCRIPTION $CONFIG
  $ASSIGNMENT_GROUP $SYSLOG $OWNER $INCIDENT_TYPE
  $BUSINESS_SERVICE $PROVIDER_SERVICE $CONTACT_TYPE
  @DESCRIPTION @ERROR);

my ( $incident, @work_notes, $PWHANDLE );

### replace INSTANCE with your instance name
### fill in USERNAME and PASSWORD

$INSTANCE          = 'https://INSTANCE.service-now.com/';
$USERNAME          = '';
$PASSWORD          = '';
$SHORT_DESCRIPTION = 'this is a short description';
$ASSIGNMENT_GROUP  = '';
$OWNER             = 'Guest';
$INCIDENT_TYPE     = 'Service Event';
$CONTACT_TYPE      = 'Self-service';
$BUSINESS_SERVICE  = 'Other';
$PROVIDER_SERVICE  = 'Other';
$SYSLOG            = '/usr/local/logs/syslog';
@DESCRIPTION       = <DATA>;

#
# generate work notes
@work_notes = get_work_notes();

#
# initialize the API (expects globals INSTANCE, USERNAME, PASSWORD; sets CONFIG)
init_sn_api();

#
# create a new incident
$incident = create_new_incident();

#
# if there have been errors, substitute those for the work notes
!scalar(@ERROR) || ( @work_notes = @ERROR );

#
# add work notes, set client id and contact type, then update
$incident->setValue( 'work_notes', join q{}, @work_notes );
$incident->setValue( 'caller_id',    $OWNER );
$incident->setValue( 'contact_type', $CONTACT_TYPE );
$incident->update();

#
##
#### end main

#
# set up SN API
sub init_sn_api {
    $CONFIG = ServiceNow::Configuration->new();
    $CONFIG->setUserName($USERNAME);
    $CONFIG->setUserPassword($PASSWORD);
    $CONFIG->setSoapEndPoint($INSTANCE);
    return;
}

#
# create a new incident w/ the appropriate fields populated
sub create_new_incident {
    my $inc;
    $inc = ServiceNow::ITIL::Incident->new($CONFIG);
    $inc->setValue( 'short_description',     $SHORT_DESCRIPTION );
    $inc->setValue( 'assignment_group',      $ASSIGNMENT_GROUP );
    $inc->setValue( 'description',           join q{}, @DESCRIPTION );
#    $inc->setValue( 'u_contact',             $OWNER );
#    $inc->setValue( 'u_incident_type',       $INCIDENT_TYPE );
#    $inc->setValue( 'u_it_business_service', $BUSINESS_SERVICE );
#    $inc->setValue( 'u_it_provider_service', $PROVIDER_SERVICE );
    $inc->insert();
    return $inc;
}

sub get_work_notes {
    my @rep;
    push @rep, "this is a work note";
    return @rep;
}

__DATA__
This is a description
It can have multiple lines
