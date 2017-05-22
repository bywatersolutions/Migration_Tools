#!/usr/bin/perl
#
# Joy Nelson
#
# DOES:
#   updates item record from infile of 001 tag value
#  
# EXPECTS:
#   infile of 001 value
#   runtime option needed: field to update and value for that field
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
use MARC::Record;
use MARC::Field;
use C4::Context;
use C4::Biblio;
use C4::Items;

$|=1;
my $debug=0;
my $doo_eet=0;
my $i=0;
my $in_file ="";
my %data;
my @data;
my $data;
my %bibs;
my $updatefield;
my $value;
my $modified =0;

GetOptions(
    'debug'    => \$debug,
    'field=s'  => \$updatefield,
    'value=s'  => \$value,
    'update'   => \$doo_eet,
    'file:s'      => \$in_file,);

if ($in_file eq q{}){
   print "Something's missing.\n";
   exit;
   }

my $csv = Text::CSV_XS->new();
my $written = 0;
my $dbh = C4::Context->dbh();

open my $infl,"<",$in_file;

#creates hash of 001 with value of 1
while (my $line=$csv->getline($infl)){
  @data = @$line;
  $bibs{$data[0]}=1;
  print "$data[0] and $bibs{$data[0]}\n";
}
close $infl;

my $upd_sth = $dbh->prepare("UPDATE items SET $updatefield = '$value' where biblionumber=?");
my $tags = 0;

#Read the database, and if an 001 is present and is in the csv update the items accordingly.

my $sth = $dbh->prepare("SELECT biblionumber from biblio");
$sth->execute();

RECORD:
while (my $row = $sth->fetchrow_hashref()){
  last RECORD if ($debug and $written > 10);
  $i++;
  print '.' unless ($i % 10);
  print "\r$i" unless ($i % 100);

  my $record = GetMarcBiblio($row->{'biblionumber'});
  my $bibnum = $row->{'biblionumber'};
#print "$bibnum\n";
  next RECORD if (!$record->field('001'));

  my $ctrltag = ($record->field('001') || "");
  my $tag = $ctrltag->data();
  $tag =~ s/\s//g;
  $tag =~ s/^c//;

  if ($tag) {
   print "tag found - $tag\n";
   if (exists $bibs{$tag}){
     print "found in map\n";
     if ( $doo_eet ){
       print "Updating $bibnum with 001 value of $tag\n";
       $upd_sth->execute($bibnum);
       $modified++;
      }
   }
  }
}

print "\n$modified items modified.\n";


