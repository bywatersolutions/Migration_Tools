#!/usr/bin/perl
#---------------------------------
# Copyright 2011 ByWater Solutions
#
#---------------------------------
#
# -D Ruth Bavousett
#
# THIS IS UNTESTED>>>>>>>DO NOT USE UNTIL YOU HAVE TESTED AND DEBUGGED THIS SCRIPT. jn 9-30-2013
#---------------------------------
#
# EXPECTS:
#   -tag/subfield to edit
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

my $tag = $NULL_STRING;
my $sub = $NULL_STRING;
my $in_value = $NULL_STRING;
my $new_value = $NULL_STRING;

GetOptions(
    'tag=s'    => \$tag,
    'sub=s'    => \$sub,
    'debug'    => \$debug,
    'update'   => \$doo_eet,
);

if ($tag < 10) {
   croak ("This script really is not intended for tags 000-009. That'd be way dangerous.");
}

for my $var ($tag,$sub) {
   croak ("You're missing something") if $var eq $NULL_STRING;
}

my $dbh = C4::Context->dbh();
my $sth = $dbh->prepare("SELECT biblionumber from biblio");
$sth->execute();

RECORD:
while (my $row = $sth->fetchrow_hashref()){
  last RECORD if ($debug and $written >0);
  $i++;
  print '.' unless ($i % 10);
  print "\r$i" unless ($i % 100);

  my $record;
  eval {$record = GetMarcBiblio($row->{biblionumber}); };
  if ($@) {
     print "Problem with record $row->{biblionumber}\n";
     next RECORD;
  }
  next RECORD if (!$record->subfield($tag));

TAG:
  foreach my $tag ($record->field($tag_to_check)) {
      $tags_found++;
SUBFIELD:
      foreach my $sub ($tag->subfield($sub_to_check)){
         $tagcount{$sub}++;
         my $old_value = $sub;
$debug and print "currently:$old_value:\n";
         $old_value =~ s/\s+$//;
$debug and print "stripped:$old_value:\n";
         $record->field($tag)->update( $sub => $old_value);
         if ($doo_eet){
             C4::Biblio::ModBiblio($record,$row->{biblionumber});
         }
      }
  }
}

print << "END_REPORT";

$i records read.
$written records modified.
END_REPORT

exit;

