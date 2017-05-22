#!/usr/bin/perl
#---------------------------------
# Copyright 2013 ByWater Solutions
#
#---------------------------------
#
# -Joy Nelson
# 
# Modification log: (initial and date)
# WARNING - WILL NOT WORK ON 17.05.  See bugzilla 17629
#---------------------------------
#
# EXPECTS:
#   inputs of old frameworkcode and new frameworkcode
#
# DOES:
#   -Finds all bibs with OLD framework and updates to the NEW framework
#
# CREATES:
#   -nothing
#
# REPORTS:
#   -counts of records read, written, and modified

use autodie;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use English qw( -no_match_vars );
use Getopt::Long;
use Readonly;
use C4::Context;
use C4::Biblio;

local    $OUTPUT_AUTOFLUSH =  1;
Readonly my $NULL_STRING   => q{};
my $start_time             =  time();

my $debug   = 0;
my $doo_eet = 0;
my $i       = 0;
my $j       = 0;
my $k       = 0;
my $problem = 0;
my $modified_record = 0;
my $oldfmwk;
my $newfmwk;

GetOptions(
    'old_framework=s'    => \$oldfmwk,
    'new_framework=s'    => \$newfmwk,
    'debug'    => \$debug,
    'update'   => \$doo_eet,
);

for my $var ($oldfmwk, $newfmwk) {
   croak ("You're missing something") if $var eq $NULL_STRING;
}

my $dbh=C4::Context->dbh();
my $sth=$dbh->prepare("SELECT biblionumber FROM biblio WHERE frameworkcode = ?");
$sth->execute($oldfmwk);


RECORD:
while ( my $rec = $sth->fetchrow_hashref() ) {
   
   last RECORD unless ($rec);
   $i++;
   print '.'    unless ($i % 10);
   print "\r$i" unless ($i % 100);


   if ($doo_eet) {
      C4::Biblio::ModBiblioframework($rec->{'biblionumber'},$newfmwk);
      $modified_record++;
   }
}

print << "END_REPORT";

$i records read.
$modified_record records were changed.
END_REPORT

my $end_time = time();
my $time     = $end_time - $start_time;
my $minutes  = int($time / 60);
my $seconds  = $time - ($minutes * 60);
my $hours    = int($minutes / 60);
$minutes    -= ($hours * 60);

printf "Finished in %dh:%dm:%ds.\n",$hours,$minutes,$seconds;

exit;
