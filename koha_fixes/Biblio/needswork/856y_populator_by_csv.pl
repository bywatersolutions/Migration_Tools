#!/usr/bin/perl
#---------------------------------
# Copyright 2011 ByWater Solutions
#
#---------------------------------
#
# -D Ruth Bavousett
# -Joy Nelson, 
#     3-26-2012 edited to include csv
#     expects incoming csv file of biblionumbers
#             value for 942n field
# -D Ruth Bavousett
#     4-9-2012 edited to allow for optional mapping of biblionumbers
#
# -Joy Nelson 4-29-2013
#     edited to make it work for adding 856$y tag for a set of biblionumbers 
#
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
    '856y_value=i'   => \$val,
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
my $framework_sth = $dbh->prepare("SELECT frameworkcode from biblio where biblionumber=?");

RECORD:
while (my $line=$csv->getline($infl)){
   last RECORD if ($debug and $modified > 0);
   $i++;
   print ".";
   print "\r$i" unless ($i % 100);
   my @data = @$line;
   my $bibnumber= $data[0];
   if (defined $biblio_map{$data[0]}) {
      $bibnumber = $biblio_map{$data[0]};
   }
   $framework_sth->execute($bibnumber);
   my $rec = GetMarcBiblio($bibnumber);

   my $field=$rec->field('856');
   if ($field){
      my $curval = $field->subfield("y") || "";
      if ($curval ne $val){
         $debug and print "Biblio: $bibnumber  Old: $curval New: $val\n";
         $field->update('y' => $val);
         if ($doo_eet){
            C4::Biblio::ModBiblioMarc($rec,$bibnumber, $frmwrk->{'frameworkcode'});
         }
         $modified++;
      }
   }
   else{
      my $field=MARC::Field->new("856"," "," ","y" => $val);
      $rec->insert_grouped_field($field);
      if ($doo_eet){
         C4::Biblio::ModBiblioMarc($rec,$bibnumber, $frmwrk->{'frameworkcode'});
      }
      $modified++;
   }
}
print "\n\n$i records examined.\n$modified records modified.\n";


