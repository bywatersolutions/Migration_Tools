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
    'tag=s'   	    => \$tag,
    'sub=s'	    => \$sub,
);


my $dbh=C4::Context->dbh();
my $i=0;

my $iggy = MARC::Charset::ignore_errors(1);
my $setting = MARC::Charset::assume_encoding('utf8');

my $sth = $dbh->prepare("SELECT biblionumber FROM biblioitems");
$sth->execute();

open my $out_fh,">:utf8",$output_filename;

RECORD:
while (my $thisrec=$sth->fetchrow_hashref()){
   last RECORD if (($debug) && ($i>10) );
   $i++;
   print ".";
   print "\r$i" unless ($i % 100);

   my $bib = $thisrec->{'biblionumber'};

   my $rec = GetMarcBiblio($bib);

   my $field=$rec->subfield($tag,$sub);

   if ($field){
         print {$out_fh} "$bib|$field \n";
   }
}
print "\n\n$i records examined.\n";

