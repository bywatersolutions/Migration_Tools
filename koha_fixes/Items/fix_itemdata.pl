#!/usr/bin/perl
#---------------------------------
# Copyright 2012 ByWater Solutions
#
#---------------------------------
#
# -Joy Nelson
# 
# Modification log: (initial and date)
#   - took script to fix callnumber and modified it to take item notes and then parse into various item fiels
#---------------------------------
#
# EXPECTS:
#   -nothing
#
# DOES:
#   -updates items.replacementprice, dateaccessioned, datelastseen from itemnotes data, if --update is set
#
# CREATES:
#   -nothing
#
# REPORTS:
#   -number of issues considered
#   -number of issues modified

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
use C4::Items;

local    $OUTPUT_AUTOFLUSH =  1;
Readonly my $NULL_STRING   => q{};
my $start_time             =  time();

my $debug   = 0;
my $doo_eet = 0;
my $i       = 0;
my $j       = 0;
my $k       = 0;
my $written = 0;
my $problem = 0;

GetOptions(
    'debug'    => \$debug,
    'update'   => \$doo_eet,

);

my $dbh = C4::Context->dbh();
my $items_sth = $dbh->prepare("SELECT itemnumber, itemnotes FROM items where homebranch='W48'");
my $itemupdate_sth = $dbh->prepare("UPDATE items SET dateaccessioned = ?, datelastseen = ?, replacementprice =?  WHERE itemnumber = ?");

$items_sth->execute();
my $itemnote;
my @noteparts;
my $noteparts;
my $dateacquired;
my $datelastseen;
my $price;
my $notes;
my $itemnum;
my $month;
my $day;
my $year;


LINE:
while (my $line=$items_sth->fetchrow_hashref()) {
   $i++;
   print '.'    unless ($i % 10);
   print "\r$i" unless ($i % 100);

   $notes = $line->{'itemnotes'};
   $itemnum = $line->{'itemnumber'};
   @noteparts = split, /|/, $notes;
   if ($noteparts[0] =~ m/Accession/ ) {
     $dateacquired = substr($noteparts[0],10);
      my ($month,$day,$year) = $dateacquired =~ /(\d+).(\d+).(\d+)/;
        if ($month && $day && $year){
           $dateacquired = sprintf "%4d-%02d-%02d",$year,$month,$day;
           if ($dateacquired eq "0000-00-00") {
               $dateacquired = " ";
            }
         }
   }
   else {
     $dateacquired =" ";
   }

   if ($noteparts[1] =~ m/Inventory/ ){   
      $datelastseen = substr($noteparts[1],10);
       my ($month,$day,$year) = $datelastseen =~ /(\d+).(\d+).(\d+)/;
        if ($month && $day && $year){
           $datelastseen = sprintf "%4d-%02d-%02d",$year,$month,$day;
           if ($datelastseen eq "0000-00-00") {
               $datelastseen = " ";
            }
         }
   }
   else {
      $datelastseen = " ";
   }

   if ($noteparts[4] =~ m/Replacement/) {
      $price = substr($noteparts[4],12);
   }
   else {
      $price = 0;
   }


$debug and print "$itemnum    $dateacquired    $datelastseen   $replacementprice\n";


   if ($doo_eet) {
   $itemupdate_sth->execute($dateacquired,$datelastseen,$replacementprice,$itemnum);
   }
   $written++;
}

print << "END_REPORT";

$i issues read.
$written issues updated.
END_REPORT

my $end_time = time();
my $time     = $end_time - $start_time;
my $minutes  = int($time / 60);
my $seconds  = $time - ($minutes * 60);
my $hours    = int($minutes / 60);
$minutes    -= ($hours * 60);

printf "Finished in %dh:%dm:%ds.\n",$hours,$minutes,$seconds;

exit;
