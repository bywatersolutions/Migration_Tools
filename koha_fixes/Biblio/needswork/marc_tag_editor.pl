#!/usr/bin/perl
#---------------------------------
# Copyright 2014 ByWater Solutions
#
#---------------------------------
#
#  Joy Nelson
#
#---------------------------------
#
# EXPECTS:
#   -nothing
#
# DOES:
#   -trolls the biblio database for tag you specify  and performs action on that tag
#   -current action: remove  -> this will remove the text you enter in $where
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
my $tagtoedit;
my $sub;
my $where;
my $action = 'remove';

GetOptions(
    'tag=s'    => \$tagtoedit,
    'oldsub=s'    => \$sub,
    'where=s'  => \$where,
    'action=s' => \$action,
    'debug'    => \$debug,
    'update'   => \$doo_eet,
);

my $written = 0;
my $dbh = C4::Context->dbh();
my $sth = $dbh->prepare("SELECT biblionumber from biblio");
$sth->execute();

RECORD:
while (my $row = $sth->fetchrow_hashref()){
  last RECORD if ($debug and $written > 0);
  $i++;
  print '.' unless ($i % 10);
  print "\r$i" unless ($i % 100);

  my $tags = 0;
  my $modified = 0;
  

  my $record = GetMarcBiblio($row->{biblionumber});
  next RECORD if (!$record->field($tagtoedit));

if ($action eq 'remove') {
  foreach my $tag ($record->field($tagtoedit)){
     my $subu = $tag->subfield($sub) || "";
     if ($subu =~ m/$where/){ 
       $tags++;
$debug and print "$row->{'biblionumber'} Tag matches $where\n";
        $record->delete_field($tag);
        $subu =~ s/$where//;
        $tag->update( $sub => $subu );
$debug and print "updated tag is $subu\n";
        $record->insert_grouped_field($tag);
        $modified=1;
     }
  }
}
  next RECORD if (!$modified);

  if ($debug){
     print $record->as_formatted();
     print "\n";
  }

  if ($doo_eet && $modified){
     C4::Biblio::ModBiblio($record,$row->{biblionumber});
     $written++;
  }
}

print "\n\n$i records examined.\n$written records modified.\n";

