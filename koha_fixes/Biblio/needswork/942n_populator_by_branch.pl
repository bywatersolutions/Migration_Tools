#!/usr/bin/perl
#---------------------------------
# Copyright 2011 ByWater Solutions
#
#---------------------------------
#
# -D Ruth Bavousett
# -Joy Nelson, edited
#---------------------------------

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use Text::CSV;
use MARC::Charset;
use MARC::Record;
use MARC::Field;
use C4::Context;
use C4::Biblio;
use C4::Items;
$|=1;
my $debug=0;
my $doo_eet=0;

my $branch_name="";
my $val=0;

GetOptions(
    'branch=s'       => \$branch_name,
    '942n_value=i'   => \$val,
    'debug'         => \$debug,
    'update'        => \$doo_eet,
);

if (($branch_name eq '')){
  print "Something's missing.\n";
  exit;
}

my $dbh=C4::Context->dbh();
my $i=0;
my $modified=0;

my $iggy = MARC::Charset::ignore_errors(1);
my $setting = MARC::Charset::assume_encoding('utf8');

my $sth=$dbh->prepare("SELECT DISTINCT biblionumber,frameworkcode from items 
                       JOIN biblio USING (biblionumber)
                       WHERE homebranch=?");
$sth->execute( $branch_name );

RECORD:
while (my $thisrec=$sth->fetchrow_hashref()){
   last RECORD if ($debug and $modified > 0);
   $i++;
   print ".";
   print "\r$i" unless ($i % 100);
   my $rec = GetMarcBiblio($thisrec->{'biblionumber'});

   my $field=$rec->field('942');
   if ($field){
      my $curval = $field->subfield("n") || "";
      if ($curval ne $val){
         $debug and print "Biblio: $thisrec->{'biblionumber'}  Old: $curval New: $val\n";
         $field->update('n' => $val);
         if ($doo_eet){
            C4::Biblio::ModBiblioMarc($rec,$thisrec->{'biblionumber'}, $thisrec->{'frameworkcode'});
         }
         $modified++;
      }
   }
   else{
      my $field=MARC::Field->new("942"," "," ","n" => $val);
      $rec->insert_grouped_field($field);
      if ($doo_eet){
         C4::Biblio::ModBiblioMarc($rec,$thisrec->{'biblionumber'}, $thisrec->{'frameworkcode'});
      }
      $modified++;
   }
}
print "\n\n$i records examined.\n$modified records modified.\n";

