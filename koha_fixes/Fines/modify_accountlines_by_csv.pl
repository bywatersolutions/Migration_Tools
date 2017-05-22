#!/usr/bin/perl
#---------------------------------
# Copyright 2011 ByWater Solutions
#
#---------------------------------
#
# -D Ruth Bavousett
#  -modified by:
#    J Nelson, took borrower modification script and change to modify accountlines.amountoutstanding 5/25/2012
#    modified to work with 3.16 accounsrewrite
#---------------------------------
#
# EXPECTS:
#   -input CSV in this form:
#      <cardnumber>,<barcode>
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
my $written=0;

my $infile_name = q{};

GetOptions(
   'in:s'     => \$infile_name,
   'debug'    => \$debug,
   'update'   => \$doo_eet,
);

if ($infile_name eq q{}) {
   print "Something's missing.\n";
   exit;
}

my $csv=Text::CSV_XS->new();
my $dbh=C4::Context->dbh();
open my $infl,"<",$infile_name;

my $item_sth=$dbh->prepare("SELECT itemnumber,biblionumber FROM items WHERE barcode=?");
my $getborr_sth=$dbh->prepare ("SELECT borrowernumber from borrowers where cardnumber=?");


RECORD:
while (my $line=$csv->getline($infl)){
   last RECORD if ($debug and $i>50); 
   $i++;
   print "." unless ($i % 10);
   print "\r$i" unless ($i % 100);
   my @data = @$line; 
$debug and print "borrower: $data[0]  item: $data[1]  \n";

#   $item_sth->execute($data[1]);
#   my $itemnum=$item_sth->fetchrow_hashref();

   $getborr_sth->execute($data[0]);
   my $borrnum=$getborr_sth->fetchrow_hashref();
   my $borrower=$borrnum->{'borrowernumber'}; 
     if ($doo_eet && $borrower){
         print "$data[0] => $borrower to be updated\n";
         my $update_sth =$dbh->prepare("UPDATE account_debits SET amount_original=0, amount_outstanding=0,amount_last_increment=0 WHERE borrowernumber = ?  and created_on > '2014-03-17'");
         $update_sth->execute($borrower);
         $written++;
      }
}

print "\n\n$i records read.\n$written borrowers updated.\n";
