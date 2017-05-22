#!/usr/bin/perl
#---------------------------------
# Copyright 2015 ByWater Solutions
#
#---------------------------------
#
# -Joy Nelson
#   4-9-2017 updated to work on 16.11
#---------------------------------
#
# EXPECTS:
#   -amount itype code to find
#
# DOES:
#   -updates the itype value, if --update is set to the mapped itype found in the leader
#
# CREATES:
#   -nothing
#
# REPORTS:
#   -count of records read
#   -details of what will be changed, if --debug is set

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use Text::CSV_XS;
use C4::Context;
use C4::Biblio;
use C4::Items;

$|=1;
my $debug = 0;
my $doo_eet = 0;
my $i=0;
my $NULL_STRING = " ";
my $itypemapfilename;
my $itypetochg       = q{};
my %itype_map;

GetOptions(
   'itypeval:s'    => \$itypetochg,
   'itypemap:s'   => \$itypemapfilename,
   'debug'    => \$debug,
   'update'   => \$doo_eet,
);

if ( ($itypetochg eq '') || ($itypemapfilename eq '')){
   print "Something's missing.\n";
   exit;
}

print "Reading in itype map file.\n";
if ($itypemapfilename ne $NULL_STRING) {
   my $csv = Text::CSV_XS->new();
   open my $mapfile,'<',$itypemapfilename;
   while (my $line = $csv->getline($mapfile)) {
      my @data = @$line;
      $itype_map{$data[0]} = $data[1];
      print "$data[0] is $itype_map{$data[0]}\n";
   }
   close $mapfile;
}

my $written=0;
my $dbh=C4::Context->dbh();
my $sth=$dbh->prepare("SELECT biblionumber FROM items where itype=?");
my $itype_sth=$dbh->prepare("UPDATE items set itype=? where biblionumber=?");

$sth->execute($itypetochg);

RECORD:
while (my $row=$sth->fetchrow_hashref()){
   last RECORD if ($debug and $i>0);
   $i++;
   print "." unless ($i % 10);
   print "\r$i" unless ($i % 100);
   my $biblio=$row->{'biblionumber'};
   print "this biblionumber is $biblio\n";

#get marc record
   my $rec=GetMarcBiblio($biblio);

   print "checking leader\n";
   #itemtype
   my $newitype;
   my $raw_item_type = substr($rec->leader(),6,2);
   if (exists($itype_map{$raw_item_type})){
      $newitype = $itype_map{$raw_item_type};
      print "itemtype is $newitype\n";
   }
   else {
     next RECORD;
   }

   $debug and print "($row->{biblionumber}) updating to $newitype \n";

   if ($doo_eet){
     $itype_sth->execute($newitype,$biblio);
     $written++;
   }
}

print "\n\n$i records read.\n$written items updated.\n";
