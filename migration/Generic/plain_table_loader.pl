#!/usr/bin/perl
#---------------------------------
# Copyright 2010 ByWater Solutions
#
#---------------------------------
#
# -D Ruth Bavousett
# - edited by Joy Nelson
#
#---------------------------------

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use Text::CSV;
use C4::Context;
$|=1;

my $infile_name = "";
my $table_name = "";
my $debug=0;
my $doo_eet=0;

GetOptions(
    'in=s'     => \$infile_name,
    'table=s'  => \$table_name,
    'debug'    => \$debug,
    'update'   => \$doo_eet,
);

if (($infile_name eq '') || ($table_name eq '')){
   print "Something's missing.\n";
   exit;
}

my $csv=Text::CSV->new({ binary => 1 });
my $dbh=C4::Context->dbh();
my $j=0;
my $exceptcount=0;
open my $io,"<$infile_name";
my $headerline = $csv->getline($io);
my @fields=@$headerline;
$debug and print Dumper(@fields);
while (my $line=$csv->getline($io)){
   $debug and last if ($j>10); 
   $j++;
   print ".";
   print "\r$j" unless ($j % 100);
   my @data = @$line;
   $debug and print Dumper(@data);
   my $querystr = "INSERT INTO $table_name (";
   my $exception = 0;
   for (my $i=0;$i<scalar(@data);$i++){
      next if ($fields[$i] eq "");
      if ($fields[$i] eq "ignore"){
         next;
      }
      if (($data[$i] ne "") && ($fields[$i] ne "suppress")){
         $querystr .= $fields[$i].",";
      }
   }
   $querystr =~ s/,$//;
   $querystr .= ") VALUES (";
   for (my $i=0;$i<scalar(@fields);$i++){
      if ($fields[$i] eq "ignore"){
         next;
      }
      if ($fields[$i] =~ /date/){
         if (length($data[$i]) == 8){
           $data[$i] =~ s/(\d{4})(\d{2})(\d{2})/$1-$2-$3/;
         }
      }
      if (($data[$i] ne "") && ($fields[$i] ne "suppress")){
         $data[$i] =~ s/\"/\\"/g;
         $querystr .= '"'.$data[$i].'",';
      }
   }
   $querystr =~ s/,$//;
   $querystr .= ");";
   $debug and print $querystr."\n";
   if (!$exception){
      my $sth = $dbh->prepare($querystr);
      if ($doo_eet){
        $sth->execute();
      }
   }
   else {
      $exceptcount++;
      print "\nEXCEPTION:  $exception\n";
      for (my $i=0;$i<scalar(@fields);$i++){
         print $fields[$i].":  ".$data[$i]."\n";
      }
      print "--------------------------------------------\n";
   }
}
print "\n\n$j records processed.  $exceptcount exceptions.\n";
