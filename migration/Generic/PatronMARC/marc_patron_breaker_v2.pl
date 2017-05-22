#!/usr/bin/perl
#---------------------------------
# Copyright 2010 ByWater Solutions
#
#---------------------------------
#
# This script is intended to ingest a MARC-formatted patron file from 
# VTLS Virtua, and write an output file in a form that can be 
# fed to ByWater's General Purpose Database Table Loader script.
#
# -D Ruth Bavousett
#
#---------------------------------

use Getopt::Long;
use MARC::File::USMARC;
use MARC::Record;
use MARC::Batch;
use MARC::Charset;


my $infile_name = "";
my $outfile_name = "";
my $staticbranch;
my $staticcategory;

GetOptions(
    'in=s'     => \$infile_name,
    'out=s'    => \$outfile_name,
    'branchcode=s' => \$staticbranch,
    'category=s'   => \$staticcategory,
);

if (($infile_name eq '') || ($outfile_name eq '')){
    print << 'ENDUSAGE';

Usage:  marc_patron_breaker --in=<infile> --out=<outfile> 

<infile>     A MARC-formatted data file, from which you wish to extract data.

<outfile>    A pipe file to feed to the Data Table Loader.

ENDUSAGE
exit;
}

open OUTFL,">$outfile_name";
print OUTFL "cardnumber|";
print OUTFL "branchcode|categorycode";
print OUTFL "surname|";
print OUTFL "firstname|";
print OUTFL "middle|";
print OUTFL "address|";
print OUTFL "city|";
print OUTFL "state|";
print OUTFL "zipcode|";
print OUTFL "phone|";
print OUTFL "mobile|";
print OUTFL "borrowernotes|";
print OUTFL "userid|";
print OUTFL "B_address|";
print OUTFL "B_city|";
print OUTFL "B_state|";
print OUTFL "B_zipcode|";
print OUTFL "otherphone|";
print OUTFL "email";
print OUTFL "\n";

my $fh = IO::File->new($infile_name);
my $batch = MARC::Batch->new('USMARC',$fh);
$batch->warnings_off();
$batch->strict_off();
my $i=0;
my %categories;
while () {
   my $record = $batch->next();
   if ($@){
      print "Bogusness skipped\n";
      next;
   }
   last unless ($record);
   $i++;
   print ".";
   print "\r$i" unless $i % 100;

   # CARDNUMBER in 001
   if ($record->field("001")) { 
    my $barcodefield=$record->field("001");
    my $barcode=$barcodefield->data();
    print OUTFL $barcode."|"; 
   }
   else { print OUTFL "AUTO".$i."|";}


# foreach my $field ($this_record->field('001')) {
#      my $info=$field->data();
#      next FIELD if (!$info);
#      print {$out_fh} "$info\n";
#      $written++;
#   }


   # BRANCHCODE
   if ($staticbranch) {
     print OUTFL "$staticbranch|";
   }
   
   # Categorycode
   if ($staticcategory) {
     print OUTFL "$staticcategory|";
   }
  

   # NAME
   if ($record->subfield("100","a")){ print OUTFL $record->subfield("100","a")."|"; }
   else { print OUTFL "|";}
   if ($record->subfield("100","b")){ print OUTFL $record->subfield("100","b")."|"; }
   else { print OUTFL "|";}
   if ($record->subfield("100","c")){ print OUTFL $record->subfield("100","c")."|"; }
   else { print OUTFL "|";}

   # ADDRESS AND PHONE

   if ($record->subfield("110","a")) {print OUTFL $record->subfield("110","a")."|"; }
   else { print OUTFL "|";}
   if ($record->subfield("110","b")) {print OUTFL $record->subfield("110","b")."|"; }
   else { print OUTFL "|";}
   if ($record->subfield("110","c")) {print OUTFL $record->subfield("110","c")."|"; }
   else { print OUTFL "|";}
   if ($record->subfield("110","e")) {print OUTFL $record->subfield("110","e")."|"; }
   else { print OUTFL "|";}
   if ($record->subfield("110","k")) {print OUTFL $record->subfield("110","k")."|"; }
   else { print OUTFL "|";}
   if ($record->subfield("120","e")) {print OUTFL $record->subfield("120","e")."|"; }
   else { print OUTFL "|";}

   #borrowernotes
   my $borrowernotes;
   if ($record->subfield("112","k")) {$borrowernotes = $record->subfield("112","k");}
   if ($record->subfield("200","A")) {$borrowernotes .= $record->subfield("200","A");}
   if ($record->subfield("210","a")) {$borrowernotes .= $record->subfield("210","a");}
   if ($borrowernotes) {
     print OUTFL "$borrowernotes|";
   }
   else { print OUTFL "|";}

   #userid
   if ($record->subfield("852","p")) {print OUTFL $record->subfield("852","p")."|"; }
   else { print OUTFL "|";}

   #B_address
   if ($record->subfield("111","a")) {print OUTFL $record->subfield("111","a")."|"; }
   else { print OUTFL "|";}
   if ($record->subfield("111","b")) {print OUTFL $record->subfield("111","b")."|"; }
   else { print OUTFL "|";}
   if ($record->subfield("111","c")) {print OUTFL $record->subfield("111","c")."|"; }
   else { print OUTFL "|";}
   if ($record->subfield("111","e")) {print OUTFL $record->subfield("111","e")."|"; }
   else { print OUTFL "|";}
   if ($record->subfield("111","k")) {print OUTFL $record->subfield("111","k")."|"; }
   else { print OUTFL "|";}
   if ($record->subfield("113","m")) {print OUTFL $record->subfield("113","m"); }
   else { print OUTFL " ";}

   print OUTFL "\n";
}

print "\n";
close OUTFL;


