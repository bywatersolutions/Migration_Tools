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
my @charge_fields= qw{ date borrowerbar description amount amountoutstanding accounttype};

open my $infl,"<",$infile_name;
open my $outfl,">",$outfile_name || die ('problem opening $outfile_name');
for my $j (0..scalar(@charge_fields)-1){
   print $outfl $charge_fields[$j].',';
}
print $outfl "\n";

my $NULL_STRING = '';
my $borr;
my $rest;
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
   
   next LINE if $line =~ /^\*\*\*/;

   if (($data[1]) && ($data[1] =~ m/[0-9]+.*res/)) {
#print "$data[0]\n$data[1]\n";;
      my $borrstr = $data[1];
      ($borr,$rest) = split(/\s/,$borrstr); 
       if ($borr =~ m/^20\d\d\d\d\d\d\d\d\d\d$/) {
             $borr =~ s/^20/2VS0/ ;
       }

      next LINE;
   }

   if ( $data[0] =~ m/You have an outstanding fines balance of:/) {
#print "$data[0]\n$data[1]\n";
          $desc = 'Outstanding fines balance from Athena';
          $amount = $data[1];
          $amount =~ s/\$//;
	  print $outfl "2014-09-15,".$borr.','.$desc.','.$amount.','.$amount.',F'."\n";
      next LINE;
	  $written++;
   }
}

close $infl;
close $outfl;

print "\n\n$i lines read.\n$written charges written.\n";
exit;

