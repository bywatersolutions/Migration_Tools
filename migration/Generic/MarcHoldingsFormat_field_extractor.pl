#!/usr/bin/perl
#---------------------------------
# Copyright 2011 ByWater Solutions
#
#---------------------------------
#
# -D Ruth Bavousett
#a variation of MARC_field_extractor.pl(drnoe)
#---------------------------------
#
# EXPECTS:
#   -MARC file
#
# DOES:
#   -pulls 035a, 852a, 866 tags
#
# CREATES:
#   -CSV with ???
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

my $branchtag ='';
my $holdingbranch;

print {$out_fh} "Biblink|holdings\n";

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
   my $field = $this_record->field('035');
   $Biblink = $field->subfield('a');
   
#   $branchtag = $this_record->field('852');
#   $holdingbranch = $branchtag->subfield('a');
#   $holdingbranch = substr ($holdingbranch,0,6);

   foreach my $field ($this_record->field('866')) {
       my $holding=$field->subfield('a') || " ";
#       my $note=$field->subfield('z') || " ";
#       print {$out_fh} "$Biblink|$holdingbranch|";
       print {$out_fh} "$Biblink|";
        print {$out_fh} "$holding \n";
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
