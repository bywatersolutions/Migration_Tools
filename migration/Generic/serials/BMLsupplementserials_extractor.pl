#!/usr/bin/perl
#---------------------------------
# Copyright 2011 ByWater Solutions
#
#---------------------------------
#
# -D Ruth Bavousett
#a variation of MARC_field_extractor.pl -jn
#---------------------------------
#
# EXPECTS:
#   -MARC file
#
# DOES:
#   -pulls 004, 852a,k,h,x, 864,i,j,p,x  tags
#   -added pulling out 853 predictions $a$i$j$w$y
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
my $setting = MARC::Charset::assume_encoding('marc8');
open my $out_fh,">:utf8",$output_filename;
#print {$out_fh} "Biblink|852suba|852subk|852subh|852subx|864i|864j|864p|864x|853a|853i|853j|853w|853y|\n";
print {$out_fh} "Biblink|852suba|852subk|852subh|852subx|864i|864j|publisheddate|barcode|receiveddate|85a|853i|853j|853w|853y|\n";

my $locationtag ='';
my $pred_field = '';
my $suba;
my $subk;
my $subh;
my $subx;
my $pred_a = " ";
my $pred_i = " ";
my $pred_j = " ";
my $pred_w = " ";
my $pred_y = " ";
my $publisheddate = " ";
my $pred_b = " ";

RECORD:
while () {
   last RECORD if ($debug and $i > 99);
   my $this_record;
   eval{ $this_record = $batch->next(); };
   if ($EVAL_ERROR){
      print "Bogusness skipped\n";
      next RECORD;
   }
   last RECORD unless ($this_record);
   $i++;
   print '.'    unless $i % 10;;
   print "\r$i" unless $i % 100;

FIELD:
   my $Biblink;
   my $field = $this_record->field('004');
   $Biblink = $field->data();
   $Biblink =~ s/\s+//g;
   
   $locationtag = $this_record->field('852');
   $suba = $locationtag->subfield('a') || " ";
   $subk = $locationtag->subfield('k') || " ";
   $subh = $locationtag->subfield('h') || " ";
   $subx = $locationtag->subfield('x') || " ";

   $pred_field = $this_record->field('853');
   if ($pred_field) {
   $pred_a = $pred_field->subfield('a') || " ";
   $pred_b = $pred_field->subfield('b') || " ";
   $pred_i = $pred_field->subfield('i') || " ";
   $pred_j = $pred_field->subfield('j') || " ";
   $pred_w = $pred_field->subfield('w') || " ";
   $pred_y = $pred_field->subfield('y') || " ";
   }
# foreach my $field ($this_record->field('863')) {
   foreach my $field ($this_record->field('863')) {
       my $vol1=$field->subfield('a') || " ";
       my $vol2=$field->subfield('b') || " ";
         my $publisheddate=$field->subfield('i') || " ";
       my $barcode=$field->subfield('p') || " ";
       my $receiveddate=$field->subfield('x') || " ";
              
       print {$out_fh} "$Biblink|$suba|$subk|$subh|$subx|$vol1|$vol2|$publisheddate|$barcode|$receiveddate|$pred_a|$pred_b|$pred_i|$pred_j|$pred_w|$pred_y|\n";
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
