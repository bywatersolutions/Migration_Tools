#!/usr/bin/perl
#---------------------------------
# Copyright 2011 ByWater Solutions
#
#---------------------------------
#
# -D Ruth Bavousett
#   -11-29-2012 jen only look for MeSH indicators (2nd indicator=2)
#   -12-13-2012 jen added functionality to read a map file of old->new MeSH headings instead of old/new runtime options
#
#---------------------------------
#
# EXPECTS:
#   -tag/subfield to edit
#   -file of old and new values
#
# DOES:
#   -trolls the Koha database for biblios containing a specified tag, and edits them, if --update is specified
#
# CREATES:
#   -nothing
#
# REPORTS:
#   -what would be done, if --debug is specified
#   -count of biblios considered
#   -count of biblios modified

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

GetOptions(
    'debug'    => \$debug,
    'update'   => \$doo_eet,
);

my $dbh = C4::Context->dbh();
my $sth = $dbh->prepare("SELECT biblionumber from biblio;");
$sth->execute();

RECORD:
while (my $row = $sth->fetchrow_hashref()){
  last RECORD if ($debug and $written >4000);
  $i++;
  print '.' unless ($i % 10);
  print "\r$i" unless ($i % 100);

  my $record;
  eval {$record = GetMarcBiblio($row->{biblionumber}); };
  if ($@) {
     print "Problem with record $row->{biblionumber}\n";
     next RECORD;
  }
  next RECORD if (!$record->subfield('020','a'));

#  $debug and print "biblio -> $row->{biblionumber}";

  foreach my $tagtocheck ($record->field('020')) {
     my $isbn_count =0;
     foreach my $subtocheck ($tagtocheck->subfield('a')) {
       $isbn_count++;
       if ($isbn_count > 1) {
         $debug and print "biblio is $row->{biblionumber}\n";
       }
     }
  } #end foreach loop
}

print << "END_REPORT";

$i records read.
$written records modified.
END_REPORT

exit;

