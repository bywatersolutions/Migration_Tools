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
#   -added option where clause to refine what is pulled
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
my $where   = "";
my $wherecol = '';

my $input_filename  = $NULL_STRING;
my $output_filename = $NULL_STRING;
my $libhas_map_filename =  $NULL_STRING;
my %libhas_map;
my $freq_map_filename = $NULL_STRING;
my %freq_map;
my $csv_delim       = 'comma';
my $skip_header     = 0;
#my @columns;;
my $url;
my $libhas;
my $freq;
my $finalfreq;
my $active;
my $start;

GetOptions(
    'in=s'         => \$input_filename,
    'out=s'        => \$output_filename,
    'delimiter=s'  => \$csv_delim,
    'skip_header'  => \$skip_header,
    'libhasmap=s'  => \$libhas_map_filename,
    'freqmap=s'    => \$freq_map_filename,
#    'column=s'     => \@columns,
#    'wherecolumn=s'=> \$wherecol,
#    'where=s'      => \$where,
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

print "Reading in libhas map file.\n";
if ($libhas_map_filename ne $NULL_STRING) {
   my $csv = Text::CSV_XS->new();
   open my $mapfile,'<',$libhas_map_filename;
   while (my $line = $csv->getline($mapfile)) {
      my @data = @$line;
      $libhas_map{$data[0]} = $data[1];
#$debug and print "$data[0],$libhas_map{$data[0]}\n";
   }
   close $mapfile;
}

print "Reading in frequency map file.\n";
if ($freq_map_filename ne $NULL_STRING) {
   my $csv = Text::CSV_XS->new();
   open my $mapfile,'<',$freq_map_filename;
   while (my $line = $csv->getline($mapfile)) {
      my @data = @$line;
      $freq_map{$data[0]} = $data[1];
   }
   close $mapfile;
}

print {$output_file} "librarian(checkinnumber),Biblink,ACTIVE,startdate,identity,frequency,libhas,copies,vendor,routing_binding\n";


RECORD:
while (my $line = $csv->getline($input_file)) {
   last RECORD if ($debug && $i>9);
   $i++;
   print '.'    unless ($i % 10);
   print "\r$i" unless ($i % 100);
   my @data=@$line;
$debug and print "$data[1]\n";
   $libhas = $libhas_map{$data[1]} || " ";
$debug and print "$libhas\n";
   $start = "2015-12-02";

    $freq=$data[3] || 'x';
    $debug and print "$freq\n";
    $active="A";

   my $identity = $data[2] || " ";
   my $copies = $data[5] || 1;
   my $vendor = $data[6] || " ";
   my $routing = $data[7] || " ";

   print {$output_file} $data[1].",".$data[0].",".$active.",".$start.",".$start.",".$identity.",".$freq.",\"".$libhas."\"".",".$copies.",".$vendor.",\"".$routing."\"\n";
   $written++;

}
close $input_file;
print << "END_REPORT";

$i records read.
$written records written.
END_REPORT

exit;


sub manip_date {
      my ($date) = @_;
      $date =~ s/ //g;
      my ($month,$day,$year) = $date =~ /(\d+).(\d+).(\d+)/;
      if ($month && $day && $year){
        if ((length($year) == 2) ) {
         $year = '19'.$year;
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
