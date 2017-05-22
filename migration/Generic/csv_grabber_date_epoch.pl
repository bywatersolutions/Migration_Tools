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
use Date::Calc qw( Add_Delta_Days );

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
     if ( ($data[$column] =~ m/^[0-9]/)) {
        $data[$column] =  manip_date_epoch($data[$column]);
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

sub manip_date_epoch {


#date for epoch julian in days
			my ($date) = @_;
            my ($year, $month, $day) = Add_Delta_Days(1970, 1, 1, $date);
            $date = sprintf "%4d-%02d-%02d",$year,$month,$day;
			return $date;      
}

