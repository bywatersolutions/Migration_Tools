#!/usr/bin/perl
#---------------------------------
# Copyright 2011 ByWater Solutions
#
#---------------------------------
#
# -D Ruth Bavousett
# modified to use itemnumber - DE
#---------------------------------
#
# EXPECTS:
#   -input CSV in this form:
#      <item barcode>,<new value>
#   -which value is to be changed
#   -what tool to use to process the data
#
# DOES:
#   -updates the value described, if --update is set
#
# CREATES:
#   -nothing
#
# REPORTS:
#   -count of records read
#   -count of items modified
#   -count of items not modified due to missing barcode
#   -details of what will be changed, if --debug is set

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use Text::CSV_XS;
use C4::Context;
use C4::Items;
$|=1;
my $debug = 0;
my $doo_eet = 0;
my $i=0;

my $infile_name = q{};
my $field_to_change = q{};
my $tool = q{};
my $csv_delim            = 'comma';
my $barprefix = "";
my $barlength = 0;

GetOptions(
   'in:s'     => \$infile_name,
   'field:s'  => \$field_to_change,
'delimiter=s'  => \$csv_delim,
   'tool:s'   => \$tool,
   'itemprefix:s' => \$barprefix,
   'barlength:s' => \$barlength,
   'debug'    => \$debug,
   'update'   => \$doo_eet,
);

if (($infile_name eq q{}) || ($field_to_change eq q{})){
   print "Something's missing.\n";
   exit;
}

my %delimiter = ( 'comma' => ',',
                  'tab'   => "\t",
                  'pipe'  => '|',
                );
my $written=0;
my $item_not_found=0;
my $csv=Text::CSV_XS->new({ binary => 1, sep_char => $delimiter{$csv_delim} });
my $dbh=C4::Context->dbh();
my $sth=$dbh->prepare("SELECT itemnumber FROM items WHERE itemnumber = ?");
open my $infl,"<",$infile_name;

RECORD:
while (my $line=$csv->getline($infl)){
   last RECORD if ($debug and $i>1000);
   $i++;
   print "." unless ($i % 10);
   print "\r$i" unless ($i % 100);
   my @data = @$line; 

   if ($barprefix ne '' || $barlength > 0) {
            my $curbar = $data[0];
            my $prefixlen = length($barprefix);
            if (($barlength > 0) && (length($curbar) <= ($barlength-$prefixlen))) {
               my $fixlen = $barlength - $prefixlen;
               while (length ($curbar) < $fixlen) {
                  $curbar = '0'.$curbar;
               }
               $curbar = $barprefix . $curbar;
            }
            $data[0] = $curbar;
   }


   $sth->execute($data[0]);
   my $rec=$sth->fetchrow_hashref();

   if (!$rec){
      $item_not_found++;
      next RECORD;
   }

   my $new_value=$data[1];
   if ($tool ne q{}) {
      $new_value = _manipulate_data($tool,$data[1]);
   }
   $debug and print "$data[0] ($rec->{itemnumber})  $field_to_change => $new_value\n";

   if ($doo_eet){
      C4::Items::ModItem({ $field_to_change => $new_value },undef,$rec->{'itemnumber'});
   }
   $written++;
}
close $infl;
print "\n\n$i records read.\n$written items updated.\n$item_not_found not updated due to unknown itenumber.\n";

exit;

sub _manipulate_data {
   my $tool = shift;
   my $data = shift;
   return '' if ($data eq '');

   if ($tool eq 'uc') {
      $data = uc $data;
      $data =~ s/^\s+//g;
      $data =~ s/\s+$//g;
   }
   if ($tool eq 'money') {
      $data =~ s/[^0-9\.]//g;
   }
   if ($tool =~ /^if:/) {
      my (undef,$conditional) = split (/:/,$tool, 2);
      if ($data =~ /$conditional/) {
         $data =~ s/$conditional//g;
      }
      else {
         $data = '';
      }
   }
   if ($tool =~ /^div:/) {
      my (undef,$val) = split (/:/,$tool,2);
      $data = $data / $val;
   }
   if ($tool eq 'date') {
      $data =~ s/ //g;
      my ($month,$day,$year) = $data =~ /(\d+).(\d+).(\d+)/;
      if ($month && $day && $year){
         my @time = localtime();
         my $thisyear = $time[5]+1900;
         $thisyear = substr($thisyear,2,2);
         if ($year < $thisyear) {
            $year += 2000;
         }
         elsif ($year < 100) {
            $year += 1900;
         }
         $data = sprintf "%4d-%02d-%02d",$year,$month,$day;
         if ($data eq "0000-00-00") {
            $data = '';
         }
      }
      else {
         $data= '';
      }
   }
   if ($tool eq 'date2') {
      $data =~ s/ //g;
      if (length($data) == 8) {
         $debug and print "BEFORE:$data\n";
         my $year  = substr($data,0,4);
         my $month = substr($data,4,2);
         my $day   = substr($data,6,2);
         if ($month && $day && $year){
            $data = sprintf "%4d-%02d-%02d",$year,$month,$day;
         $debug and print "AFTER:$data\n";
         }
         else {
            $data= '';
         }
      }
      else {
         $data = '';
      }
   }
   if ($tool eq 'date3') {
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
         $data= '';
      }
   }
   if ($tool eq 'date4') {
      my ($month,$day,$year) = $data =~ /(\d+).(\d+).(\d+)/;
      if ($month && $day && $year){
         $data = sprintf "%4d-%02d-%02d",$year,$month,$day;
         if ($data eq "0000-00-00") {
            $data = '';
         }
      }
      else {
         $data= '';
      }
   }
   if ($tool eq 'date5') {
      my %months =(
                   JAN => 1, FEB => 2,  MAR => 3,  APR => 4,
                   MAY => 5, JUN => 6,  JUL => 7,  AUG => 8,
                   SEP => 9, OCT => 10, NOV => 11, DEC => 12
                  );
      $data = uc $data;
      $data =~ s/,//;
      my ($day, $monthstr,$year) = split(/\-/,$data);
      my @time = localtime();
      my $thisyear = $time[5]+1900;
      $thisyear = substr($thisyear,2,2);
      if ($year && $year <= $thisyear) {
         $year += 100;
      }
      $year+= 1900;
      if ($monthstr && $day && $year){
         $data = sprintf "%4d-%02d-%02d",$year,$months{$monthstr},$day;
      }
      else {
         $data= '';
      }
   }
   return $data;
}
