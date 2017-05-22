#!/usr/bin/perl
#---------------------------------
# Copyright 2011 ByWater Solutions
#
#---------------------------------
#
# -D Ruth Bavousett
#
#---------------------------------
#
# EXPECTS:
#   -input CSV in this form:
#      <item barcode>
#
# DOES:
#   -deletes the associated line in the issues table, if --update is set
#
# CREATES:
#   -nothing
#
# REPORTS:
#

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use Text::CSV_XS;
use C4::Context;

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

if (($infile_name eq q{})){
   print "Something's missing.\n";
   exit;
}

my $written=0;
my $item_not_found=0;
my $csv=Text::CSV_XS->new({ binary => 1});
my $dbh=C4::Context->dbh();
my $sth=$dbh->prepare("SELECT itemnumber FROM items WHERE barcode = ?");
open my $infl,"<",$infile_name;

RECORD:
while (my $line=$csv->getline($infl)){
   last RECORD if ($debug and $i>5000); 
   $i++;
   print "." unless ($i % 10);
   print "\r$i" unless ($i % 100);
   my @data = @$line; 
   $sth->execute($data[0]);
   my $rec=$sth->fetchrow_hashref();

   if (!$rec){
      print "NO ITEM: $data[0]\n";
      $item_not_found++;
      next RECORD;
   }
FIELD:
   $debug and print "$data[0] ($rec->{itemnumber})\n";
   if ($doo_eet){
         my $update_sth =$dbh->prepare("DELETE FROM issues  WHERE itemnumber = $rec->{'itemnumber'}");
         $update_sth->execute();
         $written++;
   }
}

print "\n\n$i records read.\n$written issues deleted.\n$item_not_found not found due to unknown barcode.\n";
