#!/usr/bin/perl
#---------------------------------
# Copyright 2014 ByWater Solutions
# -joy nelson
#---------------------------------
#
# Checks to see if leader position 5 is N
# Grabs biblionumber and title and outputs to screen
# Outputs to file if specified
#
#---------------------------------

use autodie;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use English qw( -no_match_vars );
use Getopt::Long;
use Readonly;
use Text::CSV_XS;

use MARC::File::USMARC;
use MARC::Record;
use MARC::Batch;
use MARC::Charset;

use C4::Context;
use C4::Biblio;

local    $OUTPUT_AUTOFLUSH =  1;
Readonly my $NULL_STRING   => q{};

my $debug   = 0;
my $doo_eet = 0;
my $i       = 0;
my $j=0;
my %bibtodelete;
my $deletethis;
my $output_filename = "";

GetOptions(
    'debug'    => \$debug,
    'update'   => \$doo_eet,
    'out=s'         => \$output_filename,
);

my $iggy = MARC::Charset::ignore_errors(1);
my $setting = MARC::Charset::assume_encoding('marc8');

my $dbh = C4::Context->dbh();
my $sth = $dbh->prepare("SELECT biblionumber from biblio;");
$sth->execute();

open my $out_fh,">:utf8",$output_filename;

RECORD:
while (my $row = $sth->fetchrow_hashref()){
  last RECORD if ($debug and $j >0);
  $i++;
  print '.' unless ($i % 10);
  print "\r$i" unless ($i % 100);

  my $record;
  eval {$record = GetMarcBiblio($row->{biblionumber}); };
  if ($@) {
     print "Problem with record $row->{biblionumber}\n";
     next RECORD;
  }
  next RECORD if (!$record->subfield('245','a'));

  foreach my $tagtocheck ($record->leader()) {
     $deletethis = substr($record->leader(),5,1);
     $bibtodelete{$deletethis}++;

    if ($deletethis eq 'n'){
     $j++;
     my $bibrecord=  ($record->field("245"));
     my $title = ($bibrecord->subfield('a'));
     my $bibnum = ($record->field("999"));
     my $biblionum = $bibnum->subfield('c');
     print $biblionum . " " . $title. "\n";
     print {$out_fh} "$biblionum,$title\n";
   }
  }
}
close $out_fh;

print "$i records read.\n$j records found to be deleted.\n";

print "\nRESULTS BY Leader position 5\n";
foreach my $kee (sort keys %bibtodelete){
   print $kee.":   ".$bibtodelete{$kee}."\n";
}


exit;


