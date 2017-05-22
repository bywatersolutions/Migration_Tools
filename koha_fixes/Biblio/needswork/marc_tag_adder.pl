#!/usr/bin/perl
#---------------------------------
# Copyright 2011 ByWater Solutions
#
#---------------------------------
#
# -D Ruth Bavousett
# -Joy Nelson, 
#
#---------------------------------

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use Text::CSV_XS;
use MARC::Charset;
use MARC::Record;
use MARC::Field;
use C4::Context;
use C4::Biblio;
use C4::Items;
$|=1;
my $debug=0;
my $doo_eet=0;

my $tag;
my $sub;
my $value;

GetOptions(
    'tag:s'      => \$tag,
    'sub:s'      => \$sub,
    'value:s'    => \$value,
    'debug'      => \$debug,
    'update'     => \$doo_eet,
);

my $dbh=C4::Context->dbh();
my $i=0;
my $modified=0;

my $iggy = MARC::Charset::ignore_errors(1);
my $setting = MARC::Charset::assume_encoding('utf8');

my $sth = $dbh->prepare("SELECT biblionumber from biblio");
$sth->execute();
my $framework_sth = $dbh->prepare("SELECT frameworkcode from biblio where biblionumber=?");

RECORD:
while (my $row = $sth->fetchrow_hashref()) {
   last RECORD if ($debug and $i > 10);
   $i++;
   print ".";
   print "\r$i" unless ($i % 100);

   my $record = GetMarcBiblio($row->{biblionumber});

   $framework_sth->execute($row->{biblionumber});
   my $frmwrk = $framework_sth->fetchrow_hashref();


   $debug and print "Biblio: $row->{biblionumber}   adding $tag $sub: $value\n";
   my $field=MARC::Field->new($tag," "," ",$sub => $value);
   $record->insert_grouped_field($field);
   if ($doo_eet){
      C4::Biblio::ModBiblioMarc($record,$row->{biblionumber}, $frmwrk->{'frameworkcode'});
      $modified++;
   }
}
print "\n\n$i records examined.\n$modified records modified.\n";


