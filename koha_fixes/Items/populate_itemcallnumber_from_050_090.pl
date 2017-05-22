#!/usr/bin/perl
#---------------------------------
# Copyright 2013 ByWater Solutions
#
#---------------------------------
#
# -Joy Nelson
# 
# Modification log: (initial and date)
#   edited 10/2/2015 - looks in 092  -created better loops to look for data
#                      also created loop to skip items that already have a callnumber
#
#---------------------------------
#
# EXPECTS:
#   -nothing
#
# DOES:
#   -captures date from 092ab or 090ab, and uses that as item callnumber, if --update is set
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
my $sth=$dbh->prepare("SELECT itemnumber,biblionumber,itemcallnumber FROM items where itype in ('PAM','PER')";
$ste->execute();

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
   my% $fld092a = $biblio->subfield('092','a');
   my $fld092b = $biblio->subfield('092','b') || " ";
   my $itemcall;

   if ($fld092a) {
     $itemcall = $fld092a . " " . $fld092b;
     $debug and print "092ab is $itemcall\n";
   }
 
  $debug and print "090ab is $itemcall\n";
 
  {
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
