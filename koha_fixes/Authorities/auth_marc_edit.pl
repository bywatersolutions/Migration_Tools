#!/usr/bin/perl
#---------------------------------
# Copyright 2014 ByWater Solutions
#
#---------------------------------
#
#   Joy Nelson
##  corrected to work with 16.11
#---------------------------------
#
# EXPECTS:
#   nothing
#
# DOES:
#   moves authid to 001 tag if not already there.
#
# CREATES:
#   -nothing
#
# REPORTS:
#   -counts of records read, and edited

use autodie;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use English qw( -no_match_vars );
use Getopt::Long;
use Readonly;
use Text::CSV_XS;
use C4::Context;
use C4::AuthoritiesMarc;
use MARC::Record;
use MARC::Field;
use MARC::Charset;
use MARC::Batch;

local    $OUTPUT_AUTOFLUSH =  1;
Readonly my $NULL_STRING   => q{};

my $debug   = 0;
my $doo_eet = 0;
my $i       = 0;
my $problem = 0;
my $modified =0;

GetOptions(
    'debug'     => \$debug,
    'update'    => \$doo_eet,
);

my $dbh=C4::Context->dbh();
my $sth=$dbh->prepare("SELECT authid FROM auth_header");
$sth->execute();

RECORD:
while (my $row=$sth->fetchrow_hashref()){
   $i++;
   print '.'    unless ($i % 10);
   print "\r$i" unless ($i % 100);

#   my $rec = $marc_sth->fetchrow_hashref();
#   my $marc;
#   eval {$marc = MARC::Record->new_from_usmarc($rec->{marc}); };
#   if ($@){
#      print "bogus record skipped\n";
#      $problem++;
#      next RECORD;
#   }
   my $marc = GetAuthority($row->{authid});
   my $tagg = $marc->field('001');
   my $tagg_value =$tagg->data();

$debug and print "authid is $row->{authid}\n";
$debug and print "001 value is $tagg_value\n";

   if ( ($tagg_value eq $row->{authid}) ) {
      print "001 contains authid - skipping\n";
      next RECORD;
   }
   $tagg->update($row->{authid});

#get authtype code
   my $authtypecode=GuessAuthTypeCode($marc);
   $debug and print "AuthType has value of $authtypecode\n";

#update record
   if ($doo_eet) {
     ModAuthority($row->{authid},$marc,$authtypecode);
     $modified++;
   }
}

print << "END_REPORT";

$i records read.
$modified records edited
$problem records not loaded due to problems.
END_REPORT

exit;      
