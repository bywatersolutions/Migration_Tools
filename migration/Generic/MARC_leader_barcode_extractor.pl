#!/usr/bin/perl
#---------------------------------
# Copyright 2017 ByWater Solutions
#
#---------------------------------
#
# -D Ruth Bavousett
# edited: Joy Nelson
# 01272017 - made more generic to read leader itemtype
# pulls out leader and barcode field from item tag
#
#  Expects: Marc file containing item tags.  Each item tag must have a barcode
#
#---------------------------------

use strict;
use Getopt::Long;
use MARC::File::USMARC;
use MARC::Record;
use MARC::Batch;
use MARC::Charset;
$|=1;
my $debug=0;

my $infile_name = "";
my $outfile_name = "";
my $tag;
my $sub1;

GetOptions(
    'in=s'          => \$infile_name,
    'tag=s'         => \$tag,
    'sub=s'         => \$sub1,
    'out=s'         => \$outfile_name,
    'debug'         => \$debug,
);


my $fh = IO::File->new($infile_name);
my $batch = MARC::Batch->new('USMARC',$fh);
$batch->warnings_off();
$batch->strict_off();
my $iggy = MARC::Charset::ignore_errors(1);
my $setting = MARC::Charset::assume_encoding('marc8');
open my $out_fh,">:utf8",$outfile_name;


my $i=0;

while () {
   my $record = $batch->next();
   $i++;
   print ".";
   print "\r$i" unless $i % 100;
   if ($@){
      print "Bogusness skipped\n";
      next;
   }
   last unless ($record);
   
   my $item_type;

   foreach my $field ($record->leader()){
     $item_type = substr($record->leader(),6,2);
   }

   foreach my $itemtag ($record->field($tag)) {
      my $itembarcode=$itemtag->subfield($sub1) || "NO BARCODE FOUND ";
      print {$out_fh} "$itembarcode,$item_type\n";
   }

}




exit;
