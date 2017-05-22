#!/usr/bin/perl
#---------------------------------
# Copyright 2014 ByWater Solutions
#
#---------------------------------
#
# Joy Nelson 6-30-2014
#
#---------------------------------
#
# EXPECTS:
#   -nothing
#
# DOES:
#   -trolls the Koha database for biblios containing a tag/subfield, deletes it, and moves to another tag
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

my $oldtag;
my $oldsub;
my $newtag;
my $newsub;
my $olddata;

GetOptions(
    'oldtag=s' => \$oldtag,
    'oldsub=s' => \$oldsub,
    'newtag=s' => \$newtag,
    'newsub=s' => \$newsub,
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
  next RECORD if (!$record->field($oldtag));

my $oldfield;
  foreach  $oldfield ($record->field($oldtag)) 
  {
    $olddata = $oldfield->subfield($oldsub);  
#who was this for?  Museum HIll???
#    if ($oldsub =~ m/Includes bibliographic/) {
     $debug and print "$olddata\n";
     my $newfield = MARC::Field->new($newtag,,' ',' ',$newsub=>$olddata);
     $record->insert_grouped_field($newfield);
#     $record->delete_field($oldfield);
#    }
  }  


  if ($debug){
     print "\n".Dumper($oldfield)."\n";
     print $record->as_formatted();
     print "\n";
  }

  if ($doo_eet){
     C4::Biblio::ModBiblio($record,$row->{biblionumber});
     $written++;
  }
}


print "\n\n$i records examined.\n$written records modified.\n";
