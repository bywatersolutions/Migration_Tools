#!/usr/bin/perl
#---------------------------------
# Copyright 2015 ByWater Solutions
#
#---------------------------------
#
#    J Nelson, modified to be a delete script for fines based on accountlines_id
#---------------------------------
#
# EXPECTS:
#   -input CSV in this form:
#      <accountlines_id>
#
# DOES:
#   -deletes the fines, if --update is set
#
# CREATES:
#   -nothing
#
# REPORTS:
#   -count of records read
#   -count of records deleted

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
my $written = 0;

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

RECORD:
while (my $line=$csv->getline($infl)){
   last RECORD if ($debug and $i>5000); 
   $i++;
   print "." unless ($i % 10);
   print "\r$i" unless ($i % 100);
   my @data = @$line; 

      if ($doo_eet){
         my $update_sth =$dbh->prepare("DELETE FROM accountlines WHERE accountlines_id = ?");
         $update_sth->execute($data[0]);
         $written++;
      }
}

print "\n\n$i records read.\n$written fines deleted.\n";
