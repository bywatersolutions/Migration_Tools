#!/usr/bin/perl
#---------------------------------
# Copyright 2011 ByWater Solutions
#
#---------------------------------
#
# -Joy Nelson
# written to scrape Essex circ data - FOLLETT ILS
#  this script is designed to read a 'text style' Circulation report that has been 
#  fed into a csv file.  It pulls borrowers barcode, itembarcode and datedue from the report
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
my @charge_fields= qw{ borrower item datedue };

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
my $datedue;

LINE:
while (my $line=$csv->getline($infl)){
   last LINE if ($debug && $i >5000);
   $i++;
   print ".";
   print "\r$i" unless ($i % 100);

   my @data = @$line;

   if ($data[0] =~ /^Patron Name/) {
      $debug and print "$data[0] is patronname-skipping\n";
      next LINE;
   }
   if ($data[0] =~ /^!!br0ken!!/) {
      $debug and print "$data[0] is br0ken-skipping\n";
      next LINE;
   }
   if ($data[0] =~ /^  Title/) {
      $debug and print "$data[0] is title-skipping\n";
       next LINE;
   }
   if ($data[0] =~ /^    Call Number/ ) {
      $debug and print "$data[0] is callnumber-skipping\n";
       next LINE;
   }
   if ($data[0] =~ /^-----/ ) {
      $debug and print "$data[0] is -----skipping\n";
     next LINE;
   }
   if ($data[0] =~ /^\d+\/\d+\/\d\d\d\d/ ) {
      $debug and print "$data[0] is date-skipping\n";
      next LINE;
   }

   if ( ($data[1] =~ m/^\s+(C|E|F|H|I|J|M|R|S|U|W|X).{0,3}\s/) || ($data[1] =~ m/E71/) || ($data[1] =~ m/VSQ7/) ) {
      $borr = $data[1];
$debug and print "\nBorrower is : $borr\n";
      next LINE;
   }

   if ( $data[3] =~ m/^TVSQ/) {
          $itembar = $data[3];
$debug and print "itembarcode=>$itembar\n";
   }
  
   if ( $data[1] =~ m/\d{1,2}\/\d{1,2}\/\d\d\d\d/ ) {
	  $datedue = format_the_date($data[1]);
$debug and print "borrower=>$borr  item=>$itembar  datedue=>$datedue\n";
	  print $outfl $borr.','.$itembar.','.$datedue."\n";
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
#   $the_date =~ s/\///g;
   my ($month, $day, $year) = split('/',$the_date);
#   my $year  = substr($the_date,4,4);
#   my $month = substr($the_date,0,2);
#   my $day   = substr($the_date,2,2);
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
