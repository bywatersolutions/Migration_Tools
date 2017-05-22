#!/usr/bin/perl
#---------------------------------
# Copyright 2011 ByWater Solutions
#
#---------------------------------
#
# -Joy Nelson
#  Written for Standwood Camano school district.  ALEXANDRIA ILS report
#  this script is designed to read a 'text style' Circulation report that has been 
#  fed into a tab delimited file.  It pulls borrowers barcode, itembarcode and datedue from the report
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
my @charge_fields= qw{ borrower item issuedate returndate date_due };

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
my $returned;

LINE:
while (my $line=$csv->getline($infl)){
   last LINE if ($debug && $i>20);
   $i++;
   print ".";
   print "\r$i" unless ($i % 50);

   my @data = @$line;
   
   next LINE if $line eq q{};
   next LINE if $line =~ m/^Barcode/;
   next LINE if $line =~ m/Checked Out/;
   next LINE if $line =~ m/Lost/;
   next LINE if $line =~ m/^s: /;
   next LINE if $line =~ m/^     /;
   next LINE if $line =~ m/^Date/;
   next LINE if $line =~ m/^\d{2}\/\d{2}\/\d{4}/;
   next LINE if $line =~ m/^No patron history records/;
   next LINE if $line =~ m/^The preference/;

$debug and print "data 0 is $data[0]  --> ";
   if ($data[0] =~ m/^Patron History/) {
      $data[0] =~ /\((.+)\)/;
      $borr = $1;
$debug and print "borrower is $borr\n";
      next LINE;
      }

   if ($data[0] =~ m/^[0-9]{3,}/) {
       $data[0] =~ s/\d{1,2}:\d\d (a|p)m//;
       $data[0] =~ s/am//;
       $data[0] =~ s/pm//;
       $data[0] =~ s/\d{1,2}:\d\d//;
$debug and print "$data[0]\n";
#       $data[0] =~ s/,//g;
       $data[0] =~ s/\t/,/g;
       $data[0] =~ s/ //g;
$debug and print "$data[0]\n";

      my @detail = split(',',$data[0]);
      if ( (!$detail[2] ) && (!$detail[3] ) && (!$detail[4] ) ) {
#print "missing dates!\n";
        next LINE;
      }
      if ( !$detail[2] ) {
         next LINE;
      }
$debug and print "$detail[0]=>$detail[1]=>$detail[2]=>$detail[3]=>$detail[4]\n";

      $itembar = $detail[0];

#      if ( ($detail[2] eq '') && ($detail[3] eq '') && ($detail[4] eq '') ) {
#        next LINE;
#      }
      if ( ($detail[3] eq 'Checkedout') || ($detail[3] eq 'Lost') ) {
#print "not a date\n";
        next LINE;
      }
$debug and print "datedue: $detail[4]\n";
      $datedue = format_the_date($detail[4]);
$debug and print "issued: $detail[2]\n";
      $issued = format_the_date($detail[2]);
$debug and print "returned: $detail[3]\n";
      $returned = format_the_date($detail[3]);

      print $outfl $borr.','.$itembar.','.$issued.','.$returned.','.$datedue."\n";
$debug and  print "$borr|$itembar|$issued|$returned|$datedue \n";
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
#   $the_date =~ s/ //g;
   $the_date = substr($the_date,0,10);
   $the_date =~ s/\///g;
$debug and print "$the_date\n";
   my $year  = substr($the_date,4,4);
   my $month = substr($the_date,0,2);
   my $day   = substr($the_date,2,2);
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
