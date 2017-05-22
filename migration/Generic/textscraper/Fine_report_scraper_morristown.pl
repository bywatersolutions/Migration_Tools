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
my @charge_fields= qw{ borrowerbar description amount amountoutstanding accounttype};

open my $infl,"<",$infile_name;
open my $outfl,">",$outfile_name || die ('problem opening $outfile_name');
for my $j (0..scalar(@charge_fields)-1){
   print $outfl $charge_fields[$j].',';
}
print $outfl "\n";

my $NULL_STRING = '';
my $borr;
my $desc;
my $amount;
my $datedue;

LINE:
while (my $line=$csv->getline($infl)){
   last LINE if ($debug && $written >50);
   $i++;
   print ".";
   print "\r$i" unless ($i % 100);

   my @data = @$line;
   
#   next LINE if $line eq q{};
   next LINE if $line =~ /^No overdue materials/;
   next LINE if $line =~ /\s{40}/;
   next LINE if $line =~ /^Current estimated fines/;

   if ($data[3] =~ m/[0-9]{2,14}/) {
      $borr = $data[3];
       if ($borr =~ m/^20\d\d\d\d\d\d\d\d\d\d$/) {
             $borr =~ s/^20/2VS0/ ;
       }

      next LINE;
   }

   if ( $data[0] =~ m/Outstanding fines balance/) {
          $desc = 'Outstanding fines balance from Athena';
          $amount = $data[9];
          $amount =~ s/\$//;
	  print $outfl $borr.','.$desc.','.$amount.','.$amount.',F'."\n";
      next LINE;
	  $written++;
   }
   if ($data[10] =~ m/^\$\d/ ) {
          $data[0] =~  s/\s+$//;
          $desc = 'Overdue item: '. $data[0] . ' -- ' . $data[7];
          $amount = $data[10];
          $amount =~ s/\$//;
          print $outfl $borr.','.$desc.','.$amount.','.$amount.',F'."\n";
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
      my %months =(
                   JAN => 1, FEB => 2,  MAR => 3,  APR => 4,
                   MAY => 5, JUN => 6,  JUL => 7,  AUG => 8,
                   SEP => 9, OCT => 10, NOV => 11, DEC => 12
                  );
   $the_date = uc $the_date;
   $the_date =~ s/,//;
   my ($day,$monthstr,$year) = split(/\s/,$the_date);


   if ($monthstr && $day && $year){
       $the_date = sprintf "%4d-%02d-%02d",$year,$months{$monthstr},$day;
       if ($the_date eq "0000-00-00") {
           $the_date = $NULL_STRING;
       }
    }
   else {
         $the_date= $NULL_STRING;
   }
   return $the_date;
}

