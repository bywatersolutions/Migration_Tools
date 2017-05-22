#!/usr/bin/perl
#---------------------------------
# Copyright 2015 ByWater Solutions
#
#---------------------------------
#
#  Joy Nelson 
#---------------------------------
#
# EXPECTS:
#   -nothing
#
# DOES:
#   -trolls the Koha database for biblios pulls out value in leader 6,2
#
# CREATES:
#   -nothing
#
# REPORTS:
#   -count of biblios considered

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
my %type;

GetOptions(
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

  foreach my $field ($record->leader()){
     my $item_type = substr($record->leader(),6,2);
     $type{$item_type}++;
  }

}


print "\n\n$i records examined.\n\n";
foreach my $kee (sort keys %type) {
   print "$kee:  $type{$kee}";
}
