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
#   -trolls the biblio database for 856$u that contain 'catalog', and edits that term to proxy.
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
my $subtoedit;

GetOptions(
    'tag=s'    => \$tagtoedit,
    'sub=s'    => \$subtoedit,
    'debug'    => \$debug,
    'update'   => \$doo_eet,
);

my $written = 0;
my $dbh = C4::Context->dbh();
my $sth = $dbh->prepare("SELECT biblionumber,frameworkcode from biblio where biblionumber between 17293 and 17295");
$sth->execute();

RECORD:
while (my $row = $sth->fetchrow_hashref()){
  last RECORD if ($debug and $written > 10);
  $i++;
  print '.' unless ($i % 10);
  print "\r$i" unless ($i % 100);

  my $record = GetMarcBiblio($row->{biblionumber});
  next RECORD if (!$record->field($tagtoedit));

  foreach my $tag ($record->field($tagtoedit)){
     next RECORD if (!$tag->subfield($subtoedit)) ;

     foreach my $sub ( $tag->subfield($subtoedit)){
       if ($sub =~ m/^LCPL$/){ 
        $debug and print "$row->{'biblionumber'} $tagtoedit $subtoedit is $sub and matches LCPL\n";
        $sub = 'IaLcPL';
        $debug and print "updated tag/sub is $sub\n";
        if ($doo_eet) {
         $tag->update( $subtoedit => $sub );
         ModBiblioMarc($record,$row->{'biblionumber'},$row->{'frameworkcode'});
         $written++;
        }
       }
       else {
       $debug and print "$row->{'biblionumber'} $tagtoedit $subtoedit is $sub and doesn't matches LCPL\n";
       }
     }

  }


}

print "\n\n$i bib records examined.\n$written tags modified.\n";

