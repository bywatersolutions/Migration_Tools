#!/usr/bin/perl
#---------------------------------
# Copyright 2011 ByWater Solutions
#---------------------------------
#
# -D Ruth Bavousett
#  edited 8/23/2013 to load borrower guarantors
#
#---------------------------------
#
# EXPECTS:
#   -input CSV in this form:
#      <guarantorbarcode><child borrower barcode>
#
# DOES:
#   -updates the values described, if --update is set
#
# CREATES:
#   -nothing
#
# REPORTS:
#   -count of records read
#   -count of borrowers modified
#   -count of borrowers not modified due to missing barcode
#   -details of what will be changed, if --debug is set

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use Text::CSV_XS;
use C4::Context;
use C4::Members;
$|=1;
my $debug = 0;
my $doo_eet = 0;
my $i=0;

my $infile_name = q{};

GetOptions(
   'in:s'     => \$infile_name,
   'debug'    => \$debug,
   'update'   => \$doo_eet,
);

if ( $infile_name eq q{} ) {
   print "Something's missing.\n";
   exit;
}

my $written=0;
my $guarantor_not_found=0;
my $borrower_not_found=0;
my $csv=Text::CSV_XS->new({ binary => 1});
my $dbh=C4::Context->dbh();
my $sth=$dbh->prepare("SELECT borrowernumber,surname,firstname FROM borrowers WHERE cardnumber = ?");
open my $infl,"<",$infile_name;

RECORD:
while (my $line=$csv->getline($infl)){
   last RECORD if ($debug and $i>5000); 
   $i++;
   print "." unless ($i % 10);
   print "\r$i" unless ($i % 100);
   my @data = @$line; 

   $sth->execute($data[1]);
   my $rec=$sth->fetchrow_hashref();
   my $childborr = $rec->{'borrowernumber'};


   if (!$childborr){
      print "NO CHILD BORROWER FOUND: $data[1]\n";
      $borrower_not_found++;
      next RECORD;
   }
$debug and print "child borrower is: $childborr\n";

   $sth->execute($data[0]);
   my $rec2=$sth->fetchrow_hashref();
   my $guarantor=$rec2->{'borrowernumber'};
  

   if (!$guarantor){
      print "NO ADULT BORROWER FOUND: $data[0]\n";
      $guarantor_not_found++;
      next RECORD;
   }
$debug and print "guarantor is: $guarantor\n";

   if ( ($doo_eet) && ($guarantor) && ($childborr) ){
         my $update_sth =$dbh->prepare("UPDATE borrowers SET guarantorid=?, contactname=?, contactfirstname=?,relationship='guardian' WHERE borrowernumber = ?");
         $update_sth->execute($guarantor,$rec2->{'surname'},$rec2->{'firstname'},$childborr);
         $written++;
   }

}

print "\n\n$i records read.\n$written borrowers updated.\n$borrower_not_found not updated due to unknown barcode.\n$guarantor_not_found guarantors not found";
