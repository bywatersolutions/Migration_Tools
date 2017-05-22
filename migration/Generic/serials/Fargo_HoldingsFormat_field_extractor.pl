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
#   -pulls 001, 999_b  tags
#   -added pulling out 853 predictions $a$b$c$u$y
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

my $NULL_STRING ="";
my $input_filename  = "";
my $output_filename = "";
my $frommapfile;
my $tomapfile;
my %frommap;
my %tomap;

GetOptions(
    'in=s'          => \$input_filename,
    'out=s'         => \$output_filename,
    'frommap=s'     => \$frommapfile,
    'tomap=s'       => \$tomapfile,
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
print {$out_fh} "Biblink|holdingnumber001|branch|853a|853b|853c|853u|853y|from|to\n";

my $holding;
my $pred_field;
my $pred_a = " ";
my $pred_b = " ";
my $pred_c = " ";
my $pred_u = " ";
my $pred_y = " ";
my $fromdate;
my $todate;
my $branch;

print "Reading in from  map file.\n";
if ($frommapfile ne $NULL_STRING) {
   my $csv = Text::CSV_XS->new();
   open my $mapfile,'<',$frommapfile;
   while (my $line = $csv->getline($mapfile)) {
      my @data = @$line;
      $frommap{$data[0]} = $data[1];
#print "$data[0] and $colmap{$data[0]}\n";
   }
   close $mapfile;
}
print "Reading in to  map file.\n";
if ($tomapfile ne $NULL_STRING) {
   my $csv = Text::CSV_XS->new();
   open my $mapfile,'<',$tomapfile;
   while (my $line = $csv->getline($mapfile)) {
      my @data = @$line;
      $tomap{$data[0]} = $data[1];
#print "$data[0] and $colmap{$data[0]}\n";
   }
   close $mapfile;
}



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
   my $field = $this_record->field('001');
   $holding = $field->data();
   $holding =~ s/\s+//g;
    
   my $bib = $this_record->field('999');
   $Biblink = $bib->subfield('b') || "NO BIB FOUND";

   my $bibbranch  = $this_record->field('852');
   $branch = $bibbranch->subfield('b') || "NFGAD";

   if ( exists($frommap{$holding}) ) {
         $debug and print "MAPPED: $holding  TO $frommap{$holding}\n";
         $fromdate = $frommap{$holding};
      }
   else {
    print "$holding could not be mapped to from date\n";
    $fromdate = "NONE";
   }

   if ( exists($tomap{$holding}) ) {
         $debug and print "MAPPED: $holding  TO $tomap{$holding}\n";
         $todate = $tomap{$holding};
      }
   else {
    print "$holding could not be mapped to to date\n";
    $todate = "NONE";
   }

   $pred_field = $this_record->field('853');
   if ($pred_field) {
   $pred_a = $pred_field->subfield('a') || " ";
   $pred_b = $pred_field->subfield('b') || " ";
   $pred_b = $pred_field->subfield('c') || " ";
   $pred_u = $pred_field->subfield('u') || " ";
   $pred_y = $pred_field->subfield('y') || " ";
   }

   print {$out_fh} "$Biblink|$holding|$branch|$pred_a|$pred_b|$pred_c|$pred_u|$pred_y|$fromdate|$todate\n";
   $written++;
}

close $out_fh;
close $in_fh;

print << "END_REPORT";


$i records read.
$written records written.
END_REPORT

exit;
