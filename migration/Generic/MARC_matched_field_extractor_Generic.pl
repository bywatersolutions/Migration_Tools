#!/usr/bin/perl
#---------------------------------
# Copyright 2011 ByWater Solutions
#
#---------------------------------
#
# -D Ruth Bavousett
# -Joy Nelson
#   edited to make more Generic 5/2/2013
#
#---------------------------------
#
# EXPECTS:
#   -MARC file
#   -tag1= a tag number
#   -tag2= a tag number
#   -sub1= a subfield of tag1
#   -sub2= a subfield of tag2
# 
# OPTIONS:
#   -tags-flipped Second tag is in reverse order
#
# DOES:
#   -nothing
#
# CREATES:
#   -CSV with two subfields
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
my $tag1;
my $tag2;
my $sub1;
my $sub2;
my $tags_flipped;

GetOptions(
    'in=s'          => \$input_filename,
    'out=s'         => \$output_filename,
    'debug'         => \$debug,
    'tag1=s'        => \$tag1,
    'tag2=s'        => \$tag2,
    'tags-flipped'  => \$tags_flipped,
    'sub1=s'        => \$sub1,
    'sub2=s'        => \$sub2,
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

RECORD:
while () {
   last RECORD if ($debug and $i > 999);
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

   my @fields1 = $this_record->field($tag1);
   my @fields2 = $this_record->field($tag2);
   if (scalar @fields1 != scalar @fields2) {
      print "Unequal number of tags, skipped (at record #$i)\n";
     next RECORD;
   }
   #next RECORD unless @fields1;
FIELD:
   foreach my $j ( 0..$#fields1 ) {
      my $sub1_value=$fields1[$j]->subfield($sub1) || " ";
      my $j2 = $tags_flipped ? ( scalar @fields1 - $j - 1 ) : $j;
      my $sub2_value=$fields2[$j2]->subfield($sub2) || " ";
# two lines below strip text and spaces from date field - used for VT-Catamount-Brooks data
#      $sub2_value =~  s/[A-Za-z]+//g if ($sub2_value);
#      $sub2_value =~ s/\s+//g if ($sub2_value);
#      next FIELD if (!$sub1_value || !$sub2_value);
      print {$out_fh} "$sub1_value,$sub2_value\n";
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

sub _process_date {
   my $data=shift;

   my %months =(
                JAN => 1, FEB => 2,  MAR => 3,  APR => 4,
                MAY => 5, JUN => 6,  JUL => 7,  AUG => 8,
                SEP => 9, OCT => 10, NOV => 11, DEC => 12
               );
   $data = uc $data;
   $data =~ s/,//;
   my ($monthstr,$day,$year) = split(/ /,$data);
   if ($monthstr && $day && $year){
      $data = sprintf "%4d-%02d-%02d",$year,$months{$monthstr},$day;
   }
   else {
      $data= q{};
   }
   return $data;
}

