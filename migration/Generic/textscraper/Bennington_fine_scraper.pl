#!/usr/bin/perl
#---------------------------------
# Copyright 2011 ByWater Solutions
#
#---------------------------------
#
# -Joy Nelson
#
#  this script is designed to read a 'text style' Fines report that has been 
#  fed into a csv file.  It pulls borrowers barcode, itembarcode and fine info (description, note, date, amount)  from the report
#
#---------------------------------

use strict;
use warnings;
use Data::Dumper;
use Encode;
use Getopt::Long;
use Text::CSV;
use Text::CSV::Simple;
$|=1;
my $debug=0;

my $infile_name = "";
my $outfile_name = "";
my $branch = '';
my $csv=Text::CSV->new( { binary=>1} );

GetOptions(
    'in=s'          => \$infile_name,
    'out=s'         => \$outfile_name,
    'debug'         => \$debug,
);

if (($infile_name eq '') || ($outfile_name eq '')){
  print "Something's missing.\n";
  exit;
}
my $i=0;
my $written=0;

my %thisrow;
my @charge_fields= qw{ borrowerbar itembar date description amount amountoutstanding accounttype };

open my $infl,"<",$infile_name;
open my $outfl,">",$outfile_name || die ('problem opening $outfile_name');
for my $j (0..scalar(@charge_fields)-1){
   print $outfl $charge_fields[$j].',';
}
print $outfl "\n";

my $NULL_STRING = '';
my $borr;
my $itembar;
my $issued;
my $date;
my $desc;
my $amount;


LINE:
while (my $line=$csv->getline($infl)){
   last LINE if ($debug && $written >50);
   $i++;
   print ".";
   print "\r$i" unless ($i % 100);

   my @data = @$line;

   if ($data[0] =~ m/[0-9]+/) {
      $data[0] =~ s/ //g;
      $borr = $data[0];
      $itembar = $data[1];
      $date = $data[4];
      $desc = $data[2] ." " . $data[3];
      $amount = $data[5];
$debug and print "$borr, $itembar, $date, $desc, $amount \n";
     if (!$debug) {
     print $outfl $borr.','.$itembar.','.$date.','.$desc.','.$amount.','.$amount.",F\n";
     }
     next LINE;
     $written++;
   }
   if ($data[0] =~ m//) {
     $itembar = $data[1];
     $date = $data[4];
     $desc = $data[2] ." " . $data[3];
     $amount = $data[5];
$debug and print "$borr, $itembar, $date, $desc, $amount \n";
     if (!$debug) {
      print $outfl $borr.','.$itembar.','.$date.','.$desc.','.$amount.','.$amount. ",F\n";
     }
     next LINE;
     $written++;
   }


}

close $infl;
close $outfl;

print "\n\n$i lines read.\n$written charges written.\n";
exit;

sub format_the_date {
   my $the_date=shift;
   $the_date =~ s/ //g;
#   $the_date =~ s/\///g;
#   my $year  = substr($the_date,4,4);
#   my $month = substr($the_date,0,2);
#   my $day   = substr($the_date,2,2);
my ($month,$day,$year) = split(/\//,$the_date);
   if ($month && $day && $year){
       $the_date = sprintf "%4d-%02d-%02d",$year,$month,$day;
       if ($the_date eq "0000-00-00") {
           $the_date = $NULL_STRING;
       }
    }
   else {
         $the_date= $NULL_STRING;
   }
   return $the_date;
}
