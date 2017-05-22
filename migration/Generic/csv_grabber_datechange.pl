#!/usr/bin/perl
#---------------------------------
# Copyright 2012 ByWater Solutions
#
#---------------------------------
#
# -D Ruth Bavousett
#
#---------------------------------
#
# EXPECTS:
#   -file of CSV-delimited data
#   -which columns you want  ie. what number column: 1,2,3,4,5,etc
#
# DOES:
#   -nothing
#
# CREATES:
#   -csv with grabbed columns
#
# REPORTS:
#   -count of lines read and output
#

use autodie;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use English qw( -no_match_vars );
use Getopt::Long;
use Readonly;
use Text::CSV_XS;

local    $OUTPUT_AUTOFLUSH =  1;
Readonly my $NULL_STRING   => q{};

my $debug   = 0;
my $doo_eet = 0;
my $i       = 0;
my $j       = 0;
my $k       = 0;
my $written = 0;
my $problem = 0;

my $input_filename  = $NULL_STRING;
my $output_filename = $NULL_STRING;
my $csv_delim       = 'comma';
my $skip_header     = 0;
my @columns;
my @datecolumns;

GetOptions(
    'in=s'         => \$input_filename,
    'out=s'        => \$output_filename,
    'delimiter=s'  => \$csv_delim,
    'skip_header'  => \$skip_header,
    'column=s'     => \@columns,
    'datecolumn=s' => \@datecolumns,
    'debug'        => \$debug,
);

my %delimiter = ( 'comma' => ',',
                  'tab'   => "\t",
                  'pipe'  => '|',
                );

for my $var ($input_filename) {
   croak ("You're missing something") if $var eq $NULL_STRING;
}

my $csv=Text::CSV_XS->new({ binary => 1, sep_char => $delimiter{$csv_delim} });
my $csv_out=Text::CSV_XS->new({binary => 1, sep_char => $delimiter{$csv_delim} });

open my $input_file, '<',$input_filename;
open my $output_file,'>',$output_filename;
if ($skip_header) {
   my $dummy = $csv->getline($input_file);
}

RECORD:
while (my $line = $csv->getline($input_file)) {
   last RECORD if ($debug && $i>9);
   $i++;
   print '.'    unless ($i % 10);
   print "\r$i" unless ($i % 100);
   my @data=@$line;

   my @new_columns;


   foreach my $column (@columns) {

    if ( grep(/$column/,@datecolumns) ) {
     if ( ($data[$column] =~ m/^\d+\/\d+\/\d+/) || ($data[$column] =~ m/^\d+\-\d+\-\d+/)) {
        $data[$column] =  manip_date($data[$column]);
     }
     if ($data[$column] =~ m/[A-Za-z]{3}\s\d{1,2}\s\d{4}/) {
        $data[$column] = manip_date2($data[$column]);
     }
     if ($data[$column] =~ m/[A-Za-z]{3}\s\d{1,2},\s\d{4}/) {
        $data[$column] = manip_date2($data[$column]);
     }

     if ($data[$column] =~ m/^\d\d\d\d\d\d\d\d$/) {
        $data[$column] = manip_date3($data[$column]);
     }
    }
   print {$output_file} "$data[$column]|";
   }
   $written++;
   print {$output_file} "\n";
}
close $input_file;
print << "END_REPORT";

$i records read.
$written records written.
END_REPORT

exit;

sub manip_date {
      my ($date) = @_;
$debug and print "$date   |  ";
      $date =~ s/PM\s*//;
$debug and print "$date   |  ";
      $date =~ s/AM\s*//;
$debug and print "$date   |  ";

      $date =~ s/\d+:\d\d//;
$debug and print "$date   |  ";
      $date =~ s/ //g;
$debug and print "$date\n";
      my ($month,$day,$year) = $date =~ /(\d+).(\d+).(\d+)/;
      if ($month && $day && $year){
        if (length($year) == 2) {
         $year = '20'.$year;
        }
         $date = sprintf "%4d-%02d-%02d",$year,$month,$day;
         if ($date eq "0000-00-00") {
            $date = '';
         }
      }
      else {
         $date= '';
      }
return $date;
}

sub manip_date2 {
      my ($date) = @_;

      my %monthdigit = (
                'Jan' => '1',  'Feb' => '2', 'Mar' => '3',
                'Apr' => '4',  'May' => '5', 'Jun' => '6',
                'Jul' => '7',  'Aug' => '8', 'Sep' => '9',
                'Oct' => '10',  'Nov' => '11', 'Dec' => '12'
                 );
     $date =~ s/ //g;
     if ($date ne "0") {
       my $month  = substr($date,0,3);
       my $day = substr($date,3,2);
       $day =~ s/,//g;
       my $year   = substr($date,-4);
        if (exists($monthdigit{$month})) {
          $month=$monthdigit{$month};
        }
        if ($month && $day && $year){
           $date = sprintf "%4d-%02d-%02d",$year,$month,$day;
           if ($date eq "0000-00-00") {
              $date = '';
           }
        }
        else {
           $date= '';
       }
     }

return $date;
}

sub manip_date3 {
      my ($date) = @_;
       my $month  = substr($date,4,2);
       my $day = substr($date,-2);
       my $year   = substr($date,0,4);
      if ($month && $day && $year){
         $date = sprintf "%4d-%02d-%02d",$year,$month,$day;
         if ($date eq "0000-00-00") {
            $date = '';
         }
      }
      else {
         $date= '';
      }
return $date;
}

