#!/usr/bin/perl
#---------------------------------
# Copyright 2014 ByWater Solutions
#
#---------------------------------
#
# -Joy Nelson
#
#---------------------------------
#
# EXPECTS:
#   -NOTHING
#
# DOES:
#   -trolls the Koha database for biblios not containing any 6XX tags, and reports them
#
# CREATES:
#   -nothing
#
# REPORTS:
#   -count of biblios considered

use autodie;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use English qw( -no_match_vars );
use Getopt::Long;
use Readonly;
use Text::CSV_XS;

use C4::Context;
use C4::Biblio;
use MARC::Record;
use MARC::Field;

local    $OUTPUT_AUTOFLUSH =  1;
Readonly my $NULL_STRING   => q{};

my $debug   = 0;
my $doo_eet = 0;
my $i       = 0;
my $written = 0;
my $problem = 0;


my $dbh = C4::Context->dbh();
my $title_sth = $dbh->prepare("SELECT title from biblio where biblionumber = ?");
my $sth = $dbh->prepare("SELECT biblionumber from biblio");
$sth->execute();

RECORD:
while (my $row = $sth->fetchrow_hashref()){
  $i++;

  my $record = GetMarcBiblio($row->{biblionumber});
  next RECORD if ($record->field('6..'));

  my $bib = $row->{biblionumber};

  $title_sth->execute($bib);
  my $title_fetch = $title_sth->fetchrow_hashref();
  my $title=$title_fetch->{title};

  print "BIBLIONUMBER: $row->{biblionumber} TITLE: $title\n";
  $written++;
}

print << "END_REPORT";

$i records read.
$written records found.
END_REPORT

exit;

