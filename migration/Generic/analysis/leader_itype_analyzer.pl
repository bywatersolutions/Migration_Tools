#!/usr/bin/perl
#---------------------------------
# Copyright 2017 ByWater Solutions
#
#---------------------------------
#
# -D Ruth Bavousett
# edited: Joy Nelson
# 01272017 - made more generic to read leader itemtype
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

GetOptions(
    'in=s'          => \$infile_name,
    'debug'         => \$debug,
);


my $fh = IO::File->new($infile_name);
my $batch = MARC::Batch->new('USMARC',$fh);
$batch->warnings_off();
$batch->strict_off();
my $iggy = MARC::Charset::ignore_errors(1);
my $setting = MARC::Charset::assume_encoding('marc8');
my $i=0;
my $j=0;
my $no_852=0;
my $bad_852=0;
my %type;
my %location;
my %sublocation;

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

   foreach my $field ($record->leader()){
     my $item_type = substr($record->leader(),6,2);
     $type{$item_type}++;
   }

}


print "\nRESULTS BY ITEM TYPE\n";
foreach my $kee (sort keys %type){
   print $kee.":   ".$type{$kee}."\n";
}



exit
