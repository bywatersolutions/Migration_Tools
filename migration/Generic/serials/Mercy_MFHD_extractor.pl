#!/usr/bin/perl
#---------------------------------
# Copyright 2011 ByWater Solutions
#
#---------------------------------
#
# -D Ruth Bavousett
#a variation of MARC_field_extractor.pl -jn
#modified for Mercy College -jn
#---------------------------------
#
# EXPECTS:
#   -MARC file
#
# DOES:
#   -pulls 004, 852a 863a,b,i,j,p,x  tags
#
# CREATES:
#   -CSV with columns of data
#
# REPORTS:
#   -nothing

use autodie; 
use strict;
use warnings;
use Carp;
use Data::Dumper;
use English qw( -no_match_vars );
use Getopt::Long;
use MARC::File::USMARC;
use MARC::Record;
use MARC::Batch;
use MARC::Charset;
use Text::CSV_XS;

local $OUTPUT_AUTOFLUSH = 1;

my $debug   = 0;
my $doo_eet = 0;
my $i       = 0;

my $input_filename  = "";
my $output_filename = "";
my @maps;

GetOptions(
    'in=s'          => \$input_filename,
    'out=s'         => \$output_filename,
    'debug'         => \$debug,
);

if (($input_filename eq '') || ($output_filename eq '')) {
  print "Something's missing.\n";
  exit;
}

my $written = 0;

my $in_fh  = IO::File->new($input_filename);
my $batch = MARC::Batch->new('USMARC',$in_fh);
$batch->warnings_off();
$batch->strict_off();
my $iggy    = MARC::Charset::ignore_errors(1);
#my $setting = MARC::Charset::assume_encoding('marc8');
open my $out_fh,">:utf8",$output_filename;
print {$out_fh} "Biblink|852suba|863a|863b|863i|863j|863p|863x\n";

my $locationtag ='';
my $pred_field = '';
my $subk;
my $subh;
my $subx;
my $pred_a = " ";
my $pred_i = " ";
my $pred_j = " ";
my $pred_w = " ";
my $pred_y = " ";

RECORD:
while () {
   last RECORD if ($debug and $i > 99);
   my $this_record;
   eval{ $this_record = $batch->next(); };
   if ($EVAL_ERROR){
      print "Bogusness skipped\n";
      next RECORD;
   }
 #  last RECORD unless ($this_record);
   $i++;
 #  print '.'    unless $i % 10;;
#  print "\r$i" unless $i % 100;

FIELD:

   my $Biblink;
   my $field = $this_record->field('004');
   $Biblink = $field->data();
   $Biblink =~ s/\s+//g;
   
#   $locationtag = ($this_record->field('852'));
#   $suba = $locationtag->subfield('a') || " ";
   
     $locationtag = $this_record->field('852');
     my $suba = $locationtag->subfield('a');



#   $subk = $locationtag->subfield('k') || " ";
#   $subh = $locationtag->subfield('h') || " ";
#   $subx = $locationtag->subfield('x') || " ";

#   $pred_field = $this_record->field('853');
#   if ($pred_field) {
#   $pred_a = $pred_field->subfield('a') || " ";
#   $pred_i = $pred_field->subfield('i') || " ";
#   $pred_j = $pred_field->subfield('j') || " ";
#   $pred_w = $pred_field->subfield('w') || " ";
#   $pred_y = $pred_field->subfield('y') || " ";
#   }

   foreach my $field ($this_record->field('863')) {
       my $holdinga=$field->subfield('a') || " ";
       my $holdingb=$field->subfield('b') || " ";
       my $vol1=$field->subfield('i') || " ";
       my $vol2=$field->subfield('j') || " ";
       my $barcode=$field->subfield('p') || " ";
       my $receiveddate=$field->subfield('x') || " ";
              
       print {$out_fh} "$Biblink|$suba|$holdinga|$holdingb|$vol1|$vol2|$barcode|$receiveddate\n";
#       print {$out_fh} "$vol1|$vol2|$barcode|$receiveddate|\n";
       $written++;
   }
}

close $out_fh;
close $in_fh;

print << "END_REPORT";


$i records read.
$written records written.
END_REPORT

exit;
