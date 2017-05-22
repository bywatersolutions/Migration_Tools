#!/usr/bin/perl
#---------------------------------
# Copyright 2011 ByWater Solutions
#
#---------------------------------
#
# -D Ruth Bavousett
#a variation of MARC_field_extractor.pl -jn
#modified for Mercy College- jn
#---------------------------------
#
# EXPECTS:
#   -MARC file
#
# DOES:
#   -pulls 004, 852a 864a,b,i,j,p,x and 865a,b,i,j,p,x tags
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
print {$out_fh} "Biblink|852suba|suba|subb|subi|subj|barcode|receiveddate|\n";

my $locationtag ='';
my $pred_field = '';
my $suba;
my $subk;
my $subh;
my $subx;
my $vol1;
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

   foreach my $field ($this_record->field('864')) {
       my $suppl1a=$field->subfield('a') || " ";
       my $suppl1b=$field->subfield('b') || " ";
       my $vol1=$field->subfield('i') || " ";
       my $vol2=$field->subfield('j') || " ";
       my $barcode=$field->subfield('p') || " ";
       my $receiveddate=$field->subfield('x') || " ";
              
       print {$out_fh} "$Biblink|$suba|$suppl1a|$suppl1b|$vol1|$vol2|$barcode|$receiveddate\n";
       $written++;
   }
   foreach my $field ($this_record->field('865')) {
       my $suppl2a=$field->subfield('a') || " ";
       my $suppl2b=$field->subfield('b') || " ";
       my $vol1a=$field->subfield('i') || " ";
       my $vol2a=$field->subfield('j') || " ";
       my $barcode2=$field->subfield('p') || " ";
       my $receiveddate2=$field->subfield('x') || " ";

       print {$out_fh} "$Biblink|$suba|$suppl2a|$suppl2b|$vol1a|$vol2a|$barcode2|$receiveddate2\n";
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
