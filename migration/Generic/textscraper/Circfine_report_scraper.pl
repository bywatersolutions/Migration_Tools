#!/usr/bin/perl
#---------------------------------
# Copyright 2011 ByWater Solutions
#
#---------------------------------
#
# -Joy Nelson
#
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
my @charge_fields= qw{ borrowerbar itembar date_due issuedate branchcode };

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
   last LINE if ($debug && $written >50);
   $i++;
   print ".";
   print "\r$i" unless ($i % 100);

   my @data = @$line;

#   next LINE if $data[0] eq q{};
   next LINE if $data[0] =~ /^Brooks/;
   next LINE if $data[0] =~ /^Borrower/;
   next LINE if $data[0] =~ /^Items/;

   if ($data[1] =~ m/[0-9]+/) {
      $data[1] =~ s/ //g;
      $borr = $data[1];
      $itembar = $data[6];
     if ($data[7] =~ m/[0-9]+\/[0-9]+\/[0-9]+/ ) {
       $datedue = format_the_date($data[7]);
       $issued = format_the_date($data[7]);
     }
$debug and print "$borr, $itembar, $datedue and $issued\n";
     if (!$debug) {
     print $outfl $borr.','.$itembar.','.$datedue.','.$issued.',BROOKSBRAT'."\n";
     }
     next LINE;
     $written++;
   }
   if ($data[1] =~ m//) {
     $itembar = $data[6];
     if ($data[7] =~ m/[0-9]+\/[0-9]+\/[0-9]+/ ) {
       $datedue = format_the_date($data[7]);
       $issued = format_the_date($data[7]);
     }
$debug and print "$borr, $itembar, $datedue and $issued\n";
     if (!$debug) {
     print $outfl $borr.','.$itembar.','.$datedue.','.$issued.',BROOKSBRAT'."\n";
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
