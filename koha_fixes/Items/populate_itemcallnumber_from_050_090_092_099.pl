#!/usr/bin/perl
#---------------------------------
# Copyright 2013 ByWater Solutions
#
#---------------------------------
#
# -Joy Nelson
# 
# Modification log: (initial and date)
#   edited 10/2/2015 - looks in 050 and 090 -created better loops to look for data
#                      also created loop to skip items that already have a callnumber
#
#---------------------------------
#
# EXPECTS:
#   -nothing
#
# DOES:
#   -captures date from 050ab or 090ab, and uses that as item callnumber, if --update is set
#
# CREATES:
#   -nothing
#
# REPORTS:
#   -shows what would be changed, if --debug is set
#   -count of items found
#   -count of items modified

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
use C4::Biblio;
use C4::Items;
use MARC::Record;
use MARC::Field;

local    $OUTPUT_AUTOFLUSH =  1;
Readonly my $NULL_STRING   => q{};
my $start_time             =  time();

my $debug   = 0;
my $doo_eet = 0;
my $written = 0;
my $problem = 0;
my $i=0;

GetOptions(
    'debug'    => \$debug,
    'update'   => \$doo_eet,
);

my $dbh=C4::Context->dbh();
my $sth=$dbh->prepare("SELECT itemnumber,biblionumber,itemcallnumber FROM items");
$sth->execute();

LINE:
while (my $line=$sth->fetchrow_hashref()) {
   $i++;
   print '.'    unless ($i % 10);
   print "\r$i" unless ($i % 100);

   if ($line->{itemcallnumber}) {
      print "Callnumber found for $line->{itemnumber} - skipping\n";
      next LINE;
   }

   my $biblio = GetMarcBiblio($line->{biblionumber});
   my $fld050a = $biblio->subfield('050','a');
   my $fld050b = $biblio->subfield('050','b') || " ";
   my $itemcall;

   if ($fld050a) {
     $itemcall = $fld050a . " " . $fld050b;
     $debug and print "050ab is $itemcall\n";
   }
   else {
      if ($biblio->subfield('090','a')) {
        print "No 050 found --seeking a 090 value\n";
        my $fld090a = $biblio->subfield('090','a') ;
        my $fld090b = $biblio->subfield('090','b') || " ";
        if ($fld090a) {
           $itemcall = $fld090a . " " . $fld090b;
           $debug and print "090ab is $itemcall\n";
        }
      }
      elsif ($biblio->subfield('092','a')) {
        print "No 050 or 90 found --seeking a 092 value\n";
        my $fld092a = $biblio->subfield('092','a') ;
        my $fld092b = $biblio->subfield('092','b') || " ";
        if ($fld092a) {
           $itemcall = $fld092a . " " . $fld092b;
           $debug and print "092ab is $itemcall\n";
        }
      }
      elsif ($biblio->subfield('099','a')) {
        print "No 050, 90 or 92 found --seeking a 099 value\n";
        my $fld099a = $biblio->subfield('099','a') ;
        my $fld099b = $biblio->subfield('099','b') || " ";
        if ($fld099a) {
           $itemcall = $fld099a . " " . $fld099b;
           $debug and print "099ab is $itemcall\n";
        }
      }
      else {
           print "no callnumber found for $line->{biblionumber} \n";
           next LINE;
      }
   }

   if (!$itemcall) {
      $problem++;
      next LINE;
   }

 
   $debug and print "ITEM $line->{itemnumber} callnumber: $itemcall\n";
  
   if ($doo_eet) {
      ModItem({ itemcallnumber => $itemcall },undef,$line->{itemnumber});
   }
   $written++; 
}

print << "END_REPORT";

$i records read.
$written records updated.
$problem records not updated due to problems.
END_REPORT

my $end_time = time();
my $time     = $end_time - $start_time;
my $minutes  = int($time / 60);
my $seconds  = $time - ($minutes * 60);
my $hours    = int($minutes / 60);
$minutes    -= ($hours * 60);

printf "Finished in %dh:%dm:%ds.\n",$hours,$minutes,$seconds;

exit;
