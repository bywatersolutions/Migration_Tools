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
# -D Ruth Bavousett
#     4-9-2012 edited to allow for optional mapping of biblionumbers
#
# -Joy Nelson 4-29-2013
#     edited to make it work for adding 856$y tag for a set of biblionumbers 
# -Joy Nelson 4-9-2017
#   updated to work with 16.11
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
my $val ='';

GetOptions(
    'in:s'     => \$infile_name,
    'debug'         => \$debug,
    'update'        => \$doo_eet,
);

if (($infile_name eq '')){
  print "Something's missing.\n";
  exit;
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

   my $rec=GetMarcBiblio($bibnumber);

   $framework_sth->execute($bibnumber);

   my $frmwrk = $framework_sth->fetchrow_hashref();

   my $field=$rec->field('260');
   my $subfield=$field->subfield('b');

   if ($subfield){
      $debug and print "Biblio: $bibnumber  deleting Old: $subfield\n";
      $field->delete_subfield(code => 'b');
         if ($doo_eet){
            C4::Biblio::ModBiblio($rec,$bibnumber, $frmwrk->{'frameworkcode'});
         }
         $modified++;
   }
}
print "\n\n$i records examined.\n$modified records modified.\n";


