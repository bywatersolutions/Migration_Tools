#!/usr/bin/perl
#---------------------------------
# Copyright 2012 ByWater Solutions
#
#---------------------------------
#
# -Joy Nelson, edited
#    pulls a list of biblionumber and a tag/subfield value
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
my $val="";
my $tag;
my $sub;
my $output_filename;

GetOptions(
    'out=s'         => \$output_filename,
    'debug'         => \$debug,
    'update'        => \$doo_eet,
);


my $dbh=C4::Context->dbh();
my $i=0;

my $iggy = MARC::Charset::ignore_errors(1);
my $setting = MARC::Charset::assume_encoding('utf8');

my $sth = $dbh->prepare("SELECT biblionumber FROM biblioitems");
$sth->execute();

open my $out_fh,">:utf8",$output_filename;
print {$out_fh} "biblionumber|951_b|951_c|951_d|951_p|951_u|951_y\n";
RECORD:
while (my $thisrec=$sth->fetchrow_hashref()){
   last RECORD if (($debug) && ($i>10) );
   $i++;
   print ".";
   print "\r$i" unless ($i % 100);

   my $bib = $thisrec->{'biblionumber'};

   my $rec = GetMarcBiblio($bib);

   my $tag=$rec->field('951');

   my $subb = $tag->subfield('b') || " ";
   my $subc = $tag->subfield('c') || " ";
   my $subd = $tag->subfield('d') || " ";
   my $subp = $tag->subfield('p') || " ";
   my $subu = $tag->subfield('u') || " ";
   my $suby = $tag->subfield('y') || " ";

   if ($tag){
         print {$out_fh} "$bib|$subb|$subc|$subd|$subp|$subu|$suby\n";
   }
}
print "\n\n$i records examined.\n";

