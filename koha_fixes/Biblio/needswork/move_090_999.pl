#!/usr/bin/perl
#---------------------------------
# Copyright 2011 ByWater Solutions
#
#---------------------------------
#
# -D Ruth Bavousett
#
#---------------------------------
#
# EXPECTS:
#   -nothing
#
# DOES:
#   -trolls the Koha database for biblios containing a 440, and edits them in accordance
#    with LC standard to 490/830.
#
# CREATES:
#   -nothing
#
# REPORTS:
#   -count of biblios considered
#   -count of biblios modified

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use Text::CSV_XS;
use C4::Context;
use C4::Biblio;
use MARC::Record;
use MARC::Field;

$|=1;
my $debug=0;
my $doo_eet=0;
my $i=0;

my $new_only = 0;

GetOptions(
    'new_only' => \$new_only,
    'debug'    => \$debug,
    'update'   => \$doo_eet,
);

my $written = 0;
my $dbh = C4::Context->dbh();
my $sth = $dbh->prepare("SELECT biblionumber from biblio");
$sth->execute();

RECORD:
while (my $row = $sth->fetchrow_hashref()){
  last RECORD if ($debug and $written > 5);
  $i++;
  print '.' unless ($i % 10);
  print "\r$i" unless ($i % 100);

  my $record = GetMarcBiblio($row->{biblionumber});
  next RECORD if !$record;
  next RECORD if (!$record->field('090'));

  my $oldfield = $record->field('090');
print "oldfield is $oldfield\n";
  my $suba = $oldfield->subfield('c') || "";
print "suba is $suba\n";
  my $newfield = MARC::Field->new('999',' ',' ','c'=>$suba);
$record->encoding('UTF-8');
     $record->insert_grouped_field($newfield);


  if ($debug){
     print "\n".Dumper($oldfield)."\n";
     print $record->as_formatted();
     print "\n";
  }

  if ($doo_eet){
     C4::Biblio::ModBiblio($record,$row->{biblionumber});
  }
  $written++;
}


print "\n\n$i records examined.\n$written records modified.\n";
