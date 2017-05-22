#!/usr/bin/perl
#---------------------------------
# Copyright 2011 ByWater Solutions
#
#---------------------------------
#
# -D Ruth Bavousett
# -Joy Nelson
#   corrected error procedure when no borrower found 5-1-2013
#
#---------------------------------
#
# EXPECTS:
#   -input file CSV in this form:
#       <patron_barcode>,<attribute_value>
#   -attribute name (code) to load
#
# DOES:
#   -adds patron attribute value, if borrower is defined and --update is specified
#
# CREATES:
#   -nothing
#
# REPORTS:
#   -values it *would* have added, if --debug is specified
#   -count of records read
#   -count of records not loaded because borrower barcode does not exist
#   -count of records loaded 

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use Text::CSV_XS;
use C4::Context;
use C4::Members;
$|=1;
my $debug=0;
my $doo_eet=0;
my $i=0;

my $infile_name = "";
my $attribute_name = "";

GetOptions(
    'in=s'     => \$infile_name,
    'attr=s'   => \$attribute_name,
    'debug'    => \$debug,
    'update'   => \$doo_eet,
);

if (($infile_name eq q{}) || ($attribute_name eq q{})){
   print "You're missing something.\n";
   exit;
}

my $borrower_not_found=0;
my $written=0;
my $csv=Text::CSV_XS->new();
my $dbh=C4::Context->dbh();
my $sth=$dbh->prepare("INSERT INTO borrower_attributes (borrowernumber,code,attribute) VALUES (?,?,?)");

open my $io,"<$infile_name";
RECORD:
while (my $row=$csv->getline($io)){
   last RECORD if ($debug and $i>20);
   $i++;
   print "." unless ($i %10);
   print "\r$i" unless ($i % 100);
   my @data=@$row;
   my $borrower=GetMemberDetails(undef,$data[0]);
   my $borrnum = $borrower->{borrowernumber};
   if (!$borrnum){
      $borrower_not_found++;
      next RECORD;
   }
   $debug and print "$data[0] ($borrower->{borrowernumber}): $attribute_name:$data[1]\n";
   if ($doo_eet) {
      $sth->execute($borrower->{borrowernumber},$attribute_name,$data[1]);
   }
   $written++;
}
close $io;

print "\n\n$i records read.\n$borrower_not_found records not loaded because borrower not found.\n$written records loaded.\n";
