#!/usr/bin/perl
#---------------------------------
# Copyright 2013 ByWater Solutions
#
#---------------------------------
#
# -D Ruth Bavousett
# 
# Modification log: (initial and date)
#
#---------------------------------
#
# EXPECTS:
#   -file of biblionumbers
#
# DOES:
#   -creates items, if --update is set
#
# CREATES:
#   -nothing
#
# REPORTS:
#   -what would be done, if --debut is set
#   -number of bibs examined
#   -number of items created

use autodie;
use Carp;
use Data::Dumper;
use English qw( -no_match_vars );
use Getopt::Long;
use Modern::Perl;
use Readonly;
use Text::CSV_XS;
use C4::Context;
use C4::Biblio;
use C4::Items;

local    $OUTPUT_AUTOFLUSH =  1;
Readonly my $NULL_STRING   => q{};
my $start_time             =  time();

my $debug   = 0;
my $doo_eet = 0;
my $i       = 0;
my $j       = 0;
my $k       = 0;
my $written = 0;
my $problem = 0;
my $infile = q{};

GetOptions(
    'in=s'     => \$infile,
    'debug'    => \$debug,
    'update'   => \$doo_eet,
);

my $csv=Text::CSV_XS->new({ binary => 1 });
my $dbh=C4::Context->dbh();

open my $infl,"<",$infile;

BIB:
while (my $line=$csv->getline($infl)){
   last BIB if ($debug and $written >10);
   $i++;
   print '.'    unless ($i % 10);
   print "\r$i" unless ($i % 100);

   my @data = @$line;
   my $bib_number=$data[0];
   $debug and say "\n$bib_number";

   if ($doo_eet) {
      C4::Items::AddItem({ homebranch     => 'LCC',
                           holdingbranch  => 'LCC',
                           itype          => 'EBOOK',
                           barcode        => $bib_number.'-101',
                            }, $bib_number);
      $written++;
   }
}

print << "END_REPORT";

$i records read.
$written item records written.
END_REPORT

my $end_time = time();
my $time     = $end_time - $start_time;
my $minutes  = int($time / 60);
my $seconds  = $time - ($minutes * 60);
my $hours    = int($minutes / 60);
$minutes    -= ($hours * 60);

printf "Finished in %dh:%dm:%ds.\n",$hours,$minutes,$seconds;

exit;
