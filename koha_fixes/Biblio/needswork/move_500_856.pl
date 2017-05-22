#!/usr/bin/perl
#---------------------------------
# Copyright 2014 ByWater Solutions
#
#---------------------------------
#
# Joy Nelson 1-9-2013
#
#---------------------------------
#
# EXPECTS:
#   -nothing
#
# DOES:
#   -trolls the Koha database for biblios containing a 500, and moves to 856 tag
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


GetOptions(
    'debug'    => \$debug,
    'update'   => \$doo_eet,
);

my $written = 0;
my $dbh = C4::Context->dbh();
my $sth = $dbh->prepare("SELECT biblionumber from biblio where biblionumber=13607");
$sth->execute();

RECORD:
while (my $row = $sth->fetchrow_hashref()){
  last RECORD if ($debug and $written > 5);
  $i++;
  print '.' unless ($i % 10);
  print "\r$i" unless ($i % 100);

  my $record = GetMarcBiblio($row->{biblionumber});
  next RECORD if !$record;
  next RECORD if (!$record->field(500));


  foreach my $oldfield ($record->field('500')) 
  {
    my $newa = "";
    my $suba = $oldfield->subfield('a') || "";  
    $newa = $suba;
    if ($newa =~ m/Location map: /) {
     $newa =~ s/Location map: / /g;
     $newa =~ s/\s+$//g;
     $newa = "http:\/\/media.bywatersolutions.com\/Esri\/maps\/" . $newa;
     my $newfield = MARC::Field->new('856,'4',' ','u'=>$newa,'y'=>"Location map:");
     $record->insert_grouped_field($newfield);
     $record->delete_field($oldfield);
    }
  }  


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
