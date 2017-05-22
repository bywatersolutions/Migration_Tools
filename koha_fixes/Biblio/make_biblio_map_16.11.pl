#!/usr/bin/perl
#---------------------------------
# Copyright 2011 ByWater Solutions
#
#---------------------------------
#
# -D Ruth Bavousett
# -Rocio Dressler
#  updated to work on 16.11
#---------------------------------

use Data::Dumper;
use Getopt::Long;
use Modern::Perl;
use C4::Context;
use C4::Biblio;
use C4::Items;
use C4::Serials;
use MARC::Record;
use MARC::Field;
use MARC::Charset;

$|=1;
my $debug=0;
my $i=0;

my $tagfield="";
my $tagsubfield="";
my $outfilename="";
my $whereclause="";

GetOptions(
    'tag=s'         => \$tagfield,
    'sub=s'         => \$tagsubfield,
    'out=s'         => \$outfilename,
    'where=s'       => \$whereclause,
    'debug'         => \$debug,
);

if (($tagfield eq q{}) || ($tagfield > 10 && $tagsubfield eq q{}) || ($outfilename eq q{})){
   print "Something's missing.\n";
   exit;
}

my $field_not_present=0;
my $written=0;

my $dbh=C4::Context->dbh();
my $dum=MARC::Charset->ignore_errors(1);
my $query = "SELECT biblioitems.biblionumber AS biblionumber FROM biblioitems JOIN biblio USING (biblionumber)";
if ($whereclause ne '') {
   $query .= " WHERE $whereclause";
}
my $sth=$dbh->prepare($query);
$sth->execute();

open my $out,">",$outfilename;

RECORD:
while (my $row=$sth->fetchrow_hashref()){
   $i++;
   print ".";
   print "\r$i" unless ($i % 100);

   my $rec = GetMarcBiblio($row->{'biblionumber'});
   $debug and print Dumper($rec);

   my $field;
   my $data;
   my $this_one = 0;
TAGG:
   foreach my $tagg ($rec->field($tagfield)) {

      if ($tagfield < 10){
         $field = $tagg->data();
      }
      else{
         $field = $tagg->subfield($tagsubfield);
      }
      $debug and print "$row->{'biblionumber'}\n";
      $debug and say "$field";
      if (!$field){
         next TAGG;
      }
      $field =~ s/\"/'/g;
      if ($field =~ m/\,/){
         $field = '"'.$field.'"';
      }
      print {$out} "$field,$row->{biblionumber}\n";
      $written++;
      $this_one = 1;
   }
   if (!$this_one) {
      $field_not_present++;
      next RECORD;
   }
}

close $out;

print "\n$i records read from database.\n$written lines in output file.\n";
print "$field_not_present records not considered due to missing or invalid field.\n\n";

