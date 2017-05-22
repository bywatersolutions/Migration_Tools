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
#   -file of biblionumber
#
# DOES:
#   -reads a file of biblionumbers, grabs the 856$u and edits that term to proxy.
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

$|=1;
my $debug=0;
my $doo_eet=0;
my $i=0;
my $infile_name;

GetOptions(
    'in=s'     => \$infile_name,
    'debug'    => \$debug,
    'update'   => \$doo_eet,
);

my $csv=Text::CSV_XS->new();
open my $infl,"<",$infile_name;
my $written = 0;
my $dbh = C4::Context->dbh();
my $sth = $dbh->prepare("SELECT biblionumber from biblio where biblionumber=?");
#$sth->execute();

RECORD:
while (my $line=$csv->getline($infl)){
  last RECORD if ($debug and $i > 5);
  $i++;
  print '.' unless ($i % 10);
  print "\r$i" unless ($i % 100);

  my @data = @$line;
  my $bibnumber= $data[0];

  my $tags = 0;
  my $modified = 0;
  
  my $record = GetMarcBiblio($bibnumber);
  next RECORD if (!$record->field(856));

  foreach my $tag ($record->field(856)){
     $tags++;
     my $subu = $tag->subfield('u') || "";
     if ($subu =~ m/^http:\/\/search.ebscohost.com/){ 
$debug and print "$bibnumber 856u tag matches search.ebscohost.com\n";
        $record->delete_field($tag);
        $subu =~ s/^/http:\/\/ripon.idm.oclc.org\/login?url=/;
        $tag->update( 'u' => $subu );
$debug and print "updated tag is $subu\n";
        $record->insert_grouped_field($tag);
        $modified=1;
     }
  }

  next RECORD if (!$modified);


  if ($doo_eet && $modified){
     C4::Biblio::ModBiblio($record,$bibnumber);
  }
  $written++;
}

print "\n\n$i records examined.\n$written records modified.\n";

