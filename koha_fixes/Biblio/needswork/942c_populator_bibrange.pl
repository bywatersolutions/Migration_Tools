#!/usr/bin/perl
#---------------------------------
# Copyright 2011 ByWater Solutions
#
#---------------------------------
#
#  DOES: adds/updates the 942$c 
#    adds the 942c doesn't exist OR
#    updates the 942c doesn't match the items itype
#
#
# -D Ruth Bavousett
# -Joy Nelson
#   update to work with 16.11
#
#---------------------------------

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use Text::CSV;
use MARC::Charset;
use MARC::Record;
use MARC::Field;
use C4::Context;
use C4::Biblio;
use C4::Items;
$|=1;
my $debug=0;
my $doo_eet=0;
my $itype_map_name="";
my %itype_map;
my $start;
my $end;

GetOptions(
    'map=s'         => \$itype_map_name,
    'bibstart=s'    => \$start,
    'bibend=s'      => \$end,
    'debug'         => \$debug,
    'update'        => \$doo_eet,
);


if ($itype_map_name){
   my $csv = Text::CSV->new();
   open my $mapfile,"<$itype_map_name";
   while (my $row = $csv->getline($mapfile)){
      my @data = @$row;
      $itype_map{$data[0]} = $data[1];
   }
   close $mapfile;
}

my $dbh=C4::Context->dbh();
my $i=0;
my $modified=0;
my $iggy = MARC::Charset::ignore_errors(1);
my $setting = MARC::Charset::assume_encoding('utf8');

my $sth=$dbh->prepare("SELECT biblionumber,frameworkcode from biblio WHERE biblioitems.biblionumber between ? and ? ");
$sth->execute($start,$end);
my $item_sth = $dbh->prepare("SELECT itype FROM items WHERE biblionumber=? LIMIT 1");
my $upd_sth = $dbh->prepare("UPDATE biblioitems SET itemtype=? WHERE biblionumber=?");

while (my $thisrec=$sth->fetchrow_hashref()){
   $i++;
   print ".";
   print "\r$i" unless ($i % 100);

   my $rec = GetMarcBiblio($thisrec->{'biblionumber'});

   my $curval = $rec->subfield("942","c") || "";

   $item_sth->execute($thisrec->{'biblionumber'});
   my $itmrec=$item_sth->fetchrow_hashref();
   my $val = $itmrec->{'itype'} || "";
   $val = $itype_map{$val} if (exists ($itype_map{$val}));

   if ($val ne $curval){
      $debug and print "Biblio: $thisrec->{'biblionumber'}  Old: $curval New: $val\n";
      $rec->field("942")->update( "c" => $val );
      if ($doo_eet){
            $upd_sth->execute($val,$thisrec->{'biblionumber'});
            C4::Biblio::ModBiblioMarc($rec,$thisrec->{'biblionumber'}, $thisrec->{'frameworkcode'});
      }
      $modified++;
   }
}
print "\n\n$i records examined.\n$modified records modified.\n";

