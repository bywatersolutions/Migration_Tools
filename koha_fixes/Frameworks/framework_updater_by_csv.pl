#!/usr/bin/perl
#---------------------------------
# Copyright 2015 Joy Nelson ByWater Solutions
#
#---------------------------------
#   DOES:
#   change biblioframework for bibs in supplied file.
#
#   EXPECTS:
#     a csv with  <biblionumber>
#     specify frameworkcode as runtime options.
# 
#  WARNING - WILL NOT WORK ON 17.05.  See bugzilla 17629
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
my $fmwk;

GetOptions(
    'in:s'     => \$infile_name,
    'debug'         => \$debug,
    'framework=s'           => \$fmwk,
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

RECORD:
while (my $line=$csv->getline($infl)){
   last RECORD if ($debug and $modified > 10);
   $i++;
   print ".";
   print "\r$i" unless ($i % 100);
   my @data = @$line;
   my $bibnumber= $data[0];

   if ($doo_eet){
         C4::Biblio::ModBiblioframework($bibnumber, $fmwk);
         $modified++;
   }
}
print "\n\n$i records examined.\n$modified records modified.\n";


