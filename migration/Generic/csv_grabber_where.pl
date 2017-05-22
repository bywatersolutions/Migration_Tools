#!/usr/bin/perl
#---------------------------------
# Copyright 2012 ByWater Solutions
#
#---------------------------------
#
# -D Ruth Bavousett
#   Updated Joy Nelson 1/15/2016
#
#---------------------------------
#
# EXPECTS:
#   -file of CSV-delimited data
#   -which columns you want  ie. what number column: 1,2,3,4,5,etc
#   -added option where clause to refine what is pulled
#   1-15-2016 : added ability to pull data if data is 'NOT' equal to X
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
my $where;
my $wherenot;
my $wherecol = '';

my $input_filename  = $NULL_STRING;
my $output_filename = $NULL_STRING;
my $csv_delim       = 'comma';
my $skip_header;
my @columns;

GetOptions(
    'in=s'         => \$input_filename,
    'out=s'        => \$output_filename,
    'delimiter=s'  => \$csv_delim,
    'skip_header'  => \$skip_header,
    'column=s'     => \@columns,
    'wherecolumn=s'=> \$wherecol,
    'where=s'      => \$where,
    'wherenot=s'   => \$wherenot,
    'debug'        => \$debug,
);

my %delimiter = ( 'comma' => ',',
                  'tab'   => "\t",
                  'pipe'  => '|',
                );

for my $var ($input_filename, $wherecol) {
   croak ("You're missing something") if $var eq $NULL_STRING;
}

my $csv=Text::CSV_XS->new({ binary => 1, sep_char => $delimiter{$csv_delim} });
my $csv_out=Text::CSV_XS->new({binary => 1, sep_char => $delimiter{$csv_delim} });

open my $input_file, '<',$input_filename;
open my $output_file,'>',$output_filename;
my @new_headercolumns;

if ($skip_header) {
   my $dummy = $csv->getline($input_file);
}
else {
   my $dummy = $csv->getline($input_file);
   my @header = @$dummy;
   foreach my $headercolumn (@columns) {
      push @new_headercolumns,$header[$headercolumn];
   }
   $csv_out->combine(@new_headercolumns);
   my $output_string = $csv_out->string();
   print {$output_file} "$output_string\n";
}

RECORD:
while (my $line = $csv->getline($input_file)) {
   last RECORD if ($debug && $i>9);
   $i++;
   print '.'    unless ($i % 10);
   print "\r$i" unless ($i % 100);
   my @data=@$line;
   $debug and print Dumper(@data);

   my @new_columns;

   foreach my $column (@columns) {
      push @new_columns,$data[$column];
   }
   $csv_out->combine(@new_columns);

if ($where) {
  if ($data[$wherecol] eq $where) {
     my $output_string = $csv_out->string();
     print {$output_file} "$output_string\n";
     $written++;
  }
}
if ($wherenot) {
  if ($data[$wherecol] ne $wherenot) {
     my $output_string = $csv_out->string();
     print {$output_file} "$output_string\n";
     $written++;
  }
}


}
close $input_file;
print << "END_REPORT";

$i records read.
$written records written.
END_REPORT

exit;
