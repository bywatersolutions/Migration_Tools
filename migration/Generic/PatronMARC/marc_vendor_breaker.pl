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

GetOptions(
    'in=s'     => \$infile_name,
    'out=s'    => \$outfile_name,
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
#print OUTFL "branchcode|";
print OUTFL "name|";
#print OUTFL "presurname|";
#print OUTFL "surname|";
#print OUTFL "firstname|";
#print OUTFL "middle|";
#print OUTFL "title|";
print OUTFL "contact|";
print OUTFL "address1|";
print OUTFL "address2|";
print OUTFL "address3|";
print OUTFL "address4|";
#print OUTFL "otherphone|";
print OUTFL "notes|";
print OUTFL "phone\n";
#print OUTFL "dateexpiry|";
#print OUTFL "852a|";
#print OUTFL "852o|";
#print OUTFL "852q\n";

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

   # BRANCHCODE

#   print OUTFL "CC|"; 

   # BARCODE

#   if ($record->subfield("920","a")){ print OUTFL $record->subfield("920","a")."|"; }
#   else { print OUTFL "AUTO".$i."|";}



   # NAME
   if ($record->subfield("920","a")){ print OUTFL $record->subfield("920","a")."|"; }
   else { print OUTFL "|";}

#   if ($record->subfield("920","c")) {
#   my $surname = $record->subfield("920","c");
#   $surname =~ s/^ *//;
#   $surname =~ s/ *$//;
#   $surname =~ s/  / /g;
#   print OUTFL $surname."|";
#   }
#   else {
#   print OUTFL "|";
#   }   

#   if ($record->subfield("920","r")) {
#   my $firstname = $record->subfield("920","r");
#   $firstname =~ s/^ *//;
#   $firstname =~ s/ *$//;
#   $firstname =~ s/  / /g;
#   print OUTFL $firstname."|";
#   }
#   else {
#   print OUTFL "|";
#   }

   # ADDRESS AND PHONE

   
   if ($record->subfield("920","c")) {print OUTFL $record->subfield("920","c")."|"; }
   else { print OUTFL "|";}
   if ($record->subfield("920","d")){ print OUTFL $record->subfield("920","d")."|"; }
   else { print OUTFL "|";}
   if ($record->subfield("920","e")){ print OUTFL $record->subfield("920","e")."|"; }
   else { print OUTFL "|";}
   if ($record->subfield("920","f")){ print OUTFL $record->subfield("920","f")."|"; }
   else { print OUTFL "|";}
   if ($record->subfield("920","g")){ print OUTFL $record->subfield("920","g")."|"; }
   else { print OUTFL "|";}

#vendornotes
if ($record->subfield("920","b")) {
my $notes;
my $notes2;
my $notes3;
my $finalnotes;
   if ($record->subfield("920","b")) {$notes = "vendor number: " . $record->subfield("920","b"); }
   else {$notes = " ";}
   if ($record->subfield("920","i")){ $notes2= $record->subfield("920","i"); }
   else { $notes2 =  " ";}
   if ($record->subfield("920","j")){ $ntoes3 = $record->subfield("920","j"); }
   else { $notes3 = " ";}
   $finalnotes = $notes . " " . $notes2 ." ". $notes3 ."|";
   print OUTFL $finalnotes;
}

   if ($record->subfield("920","p")){ print OUTFL $record->subfield("920","p")."|"; }
   else { print OUTFL ;}

   # NOTES

#   if ($record->subfield("853","c")) {
#   my $notestr = $record->subfield("853","c");
#   $notestr =~ s/^.$//;
#   $notestr =~ s/^M//g;
#   print OUTFL $notestr."|";
#   }
#   else {
#   print OUTFL "|";
#   }

#   # DATE EXIPRING
#   if ($record->subfield("853","e")) {   
#   my $dateexp = $record->subfield("853","e");
#   $dateexp =~ s/(\d{4})(\d{2})(\d{2}).*/$1-$2-$3/;
#   print OUTFL $dateexp."|";
#   }
#   else {
#   print OUTFL "|";
##   }

   #other fields
#   if ($record->subfield("852","a")){ print OUTFL $record->subfield("852","a")."|"; }
#   else { print OUTFL "|";}
#   if ($record->subfield("852","o")){ print OUTFL $record->subfield("852","o")."|"; }
#   else { print OUTFL "|";}
#   if ($record->subfield("852","q")){ print OUTFL $record->subfield("852","q")."|"; }
#   else { print OUTFL "|";}

   print OUTFL "\n";
}

print "\n";

close OUTFL;


