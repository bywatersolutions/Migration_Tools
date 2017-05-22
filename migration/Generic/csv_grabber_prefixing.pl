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
my $barprefix;
my $barlength;
my $barcolumn;

GetOptions(
    'in=s'         => \$input_filename,
    'out=s'        => \$output_filename,
    'delimiter=s'  => \$csv_delim,
    'barprefix=s'  => \$barprefix,
    'barlength=i'  => \$barlength,
    'skip_header'  => \$skip_header,
    'barcolumn=i' => \$barcolumn,
    'column=s'     => \@columns,
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

   if ($barprefix ne '' || $barlength > 0) {
      my $curbar = $data[$barcolumn] || "NONE";
$debug and print "curbar is $curbar\n";
      my $prefixlen = length($barprefix);
      my $curbarlength = length($curbar);
      if (($barlength > 0) && ($curbarlength <= ($barlength-$prefixlen))) {
         my $fixlen = $barlength - $prefixlen;
         while (length ($curbar) < $fixlen) {
            $curbar = '0'.$curbar;

         }
         $curbar = $barprefix . $curbar;
       }
       $data[$barcolumn] = $curbar;
   }
$debug and print "$data[$barcolumn]\n";
#   foreach my $column (@columns) {
#      push @new_columns,$data[$barcolumn];
#   }
#   $csv_out->combine(@new_columns);

#   my $output_string = $csv_out->string();
   print {$output_file} "$data[$barcolumn]\n";
   $written++;
}
close $input_file;
print << "END_REPORT";

$i records read.
$written records written.
END_REPORT

exit;
