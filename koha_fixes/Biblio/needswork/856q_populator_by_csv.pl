#!/usr/bin/perl
#---------------------------------
# Copyright 2011 ByWater Solutions
#
#---------------------------------
#
# -D Ruth Bavousett
#
# -Joy Nelson 11-5-2013
#     edited to make it work for using barcode to find biblionumber and  adding  856q
#  4-9-2017 updated to work on 16.11
#---------------------------------

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use Text::CSV_XS;
use MARC::Charset;
use MARC::Record;
use MARC::Field;
use C4::Context;
use C4::Biblio;
use C4::Items;
$|=1;
my $debug=0;
my $doo_eet=0;

my $infile_name = q{};
my $val =0;
my $mapfile_name = q{};

GetOptions(
    'in:s'     => \$infile_name,
    'map=s'         => \$mapfile_name,
    '856q_value=s'  => \$val,
    'debug'         => \$debug,
    'update'        => \$doo_eet,
);

if (($infile_name eq '')){
  print "Something's missing.\n";
  exit;
}

my %biblio_map;
if ($mapfile_name ne q{}) {
   print "Reading map file...\n";
   my $csv = Text::CSV_XS->new();
   open my $map_file,'<',$mapfile_name;
   while (my $line = $csv->getline($map_file)) {
      my @data = @$line;
      $biblio_map{$data[0]} = $data[1];
   }
   close $map_file;
}

my $csv=Text::CSV_XS->new();
my $dbh=C4::Context->dbh();
my $i=0;
my $modified=0;

my $iggy = MARC::Charset::ignore_errors(1);
my $setting = MARC::Charset::assume_encoding('utf8');

open my $infl,"<",$infile_name;
my $getbib_sth = $dbh->prepare("SELECT biblionumber from items where barcode=?");
my $framework_sth = $dbh->prepare("SELECT frameworkcode from biblio where biblionumber=?");

RECORD:
while (my $line=$csv->getline($infl)){
   last RECORD if ($debug and $i > 100);
   $i++;
   print ".";
   print "\r$i" unless ($i % 100);
   my @data = @$line;

   $getbib_sth->execute($data[0]);

   my $bib = $getbib_sth->fetchrow_hashref();
   my $bibnumber = $bib->{biblionumber};


   if (!$bibnumber) {
      next RECORD;
   }
  $debug and print "bibnumber is $bibnumber\n";

   if (defined $biblio_map{biblionumber}) {
      $bibnumber = $biblio_map{biblionumber};
   }

   $framework_sth->execute($bibnumber);

   my $frmwrk = $framework_sth->fetchrow_hashref();

   my $rec = GetMarcBiblio($bibnumber);

   my $field=$rec->field('856');
   if (!$field){
      my $field=MARC::Field->new("856"," "," ","q" => $val,"u" => $data[1]);
      $rec->insert_grouped_field($field);
      if ($doo_eet){
         C4::Biblio::ModBiblioMarc($rec,$bibnumber, $frmwrk->{'frameworkcode'});
      }
      $modified++;
   }
}
print "\n\n$i records examined.\n$modified records modified.\n";


