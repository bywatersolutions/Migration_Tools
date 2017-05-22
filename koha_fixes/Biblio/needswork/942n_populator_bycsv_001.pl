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

my $in_file="";
my $val=0;
my %ebooks;

GetOptions(
    'file=s'       => \$in_file,
    '942n_value=i'   => \$val,
    'debug'         => \$debug,
    'update'        => \$doo_eet,
);

if (($in_file eq '')){
  print "Something's missing.\n";
  exit;
}

my $dbh=C4::Context->dbh();
my $csv = Text::CSV_XS->new();
my $i=0;
my $modified=0;

my $iggy = MARC::Charset::ignore_errors(1); 
my $setting = MARC::Charset::assume_encoding('utf8');

open my $infl,"<",$in_file;

while (my $line=$csv->getline($infl)){
  @data = @$line;
  $ebooks{$data[0]}=1;
}

close $infl;

my $sth=$dbh->prepare("SELECT biblionumber,frameworkcode from biblio");
$sth->execute();

RECORD:
while (my $thisrec=$sth->fetchrow_hashref()){
   last RECORD if ($debug and $modified > 0);
   $i++;
   print ".";
   print "\r$i" unless ($i % 100);
   my $rec = GetMarcBiblio($thisrec->{'biblionumber'});

   my $ctrlfield = $rec->field('001');
   next RECORD if (!$rec->field('001')); 
   my $ctrltag = ($record->field('001') || "NONE");
   my $tag = $ctrltag->data();
   next RECORD if ($tag eq "NONE");

   if (exists $ebooks{$tag}) {
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
}
print "\n\n$i records examined.\n$modified records modified.\n";

