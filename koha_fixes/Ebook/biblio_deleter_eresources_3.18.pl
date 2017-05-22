#!/usr/bin/perl
#
# Joy Nelson
#
# DOES:
#  delete bibs/items based on icoming csv file of eresource bookid numbers
#  these are stored in 856$u tag/subfield in marc.  Only looking at the end of the URL
#  FIXME: add in a check for vendor name in URL?  look for ebsco if deleting ebsco ebooks.
#  
# CREATES:
#   -nothing
#
# REPORTS:
#   -count of biblios considered
#   -count of biblios deleted

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use Text::CSV_XS;
use MARC::Record;
use MARC::Field;
use C4::Context;
use C4::Biblio;
use C4::Items;


$|=1;
my $debug=0;
my $doo_eet=0;
my $i=0;
my $in_file ="";
my %data;
my @data;
my $data;
my %ebooks;
my $vendor;

GetOptions(
    'debug'    => \$debug,
    'update'   => \$doo_eet,
    'file:s'      => \$in_file,
    'vendor:s'   => \$vendor);
  
if ($in_file eq q{}){
   print "Something's missing.\n";
   exit;
   }

my $csv = Text::CSV_XS->new();
my $written = 0;
my $dbh = C4::Context->dbh();

open my $infl,"<",$in_file;

while (my $line=$csv->getline($infl)){
  @data = @$line;
  $ebooks{$data[0]}=1;
}

close $infl;

my $deleted=0;
my $item_sth = $dbh->prepare("SELECT itemnumber FROM items WHERE biblionumber=?");

my $tags = 0;
my $found = 0;

#Read the database, and if an 856$u is present and that substring of it is in the csv
#find the items, delete the items and delete the bib record.

my $sth = $dbh->prepare("SELECT biblionumber from biblio");
$sth->execute();

RECORD:
while (my $row = $sth->fetchrow_hashref()){
  last RECORD if ($debug and $deleted > 9999999);
  $i++;
  print '.' unless ($i % 10);
  print "\r$i" unless ($i % 100);

  my $record = GetMarcBiblio($row->{'biblionumber'});
  my $bibnum = $row->{'biblionumber'};
  next RECORD if (!$record->subfield('856','u'));

  my $tag = ($record->subfield("856","u") || "");
  if ($tag !~ m/$vendor/) {
#    $debug and print "$bibnum 856 found did not match on vendor\n";
    next RECORD;
  }
  my $title = ($record->subfield("245","a"));

  (my $final_tag) = $tag =~ m/(=\d+)$/;
  $final_tag =~ s/^=// if ($final_tag);
  
  if ( ($final_tag) && ($final_tag =~ m/\d+/) ) {
#    $debug and print "$bibnum This is the tag $tag\n and the final tag $final_tag \n";
  }
  else {
    next RECORD;
  }

 if ($final_tag) {
   if ((exists $ebooks{$final_tag}) ){
     $found++;
     $debug and print "Removing|$final_tag|$bibnum|$title|$tag\n";
     $item_sth->execute($bibnum);
     my $db_item_fetch=$item_sth->fetchrow_hashref();
     my $itemnum=$db_item_fetch->{'itemnumber'};
     if ($doo_eet){
         print "NUKING: items for biblionumber: $bibnum\n";
         C4::Items::DelItem({itemnumber=>$itemnum,biblionumber=>$bibnum});
         $item_sth->execute($bibnum);
         $db_item_fetch=$item_sth->fetchrow_hashref();
         $itemnum=$db_item_fetch->{'itemnumber'};
         if ($itemnum) {
           #this should check to see if only 1 item, if more than 1, kick out for manual intervention
           #this runs check for second item.   improve by looking for more than 1 bib. or put check in that if more than 1 item is found, skip that bib??
           C4::Items::DelItem({itemnumber=>$itemnum,biblionumber=>$bibnum});
         }
         if (!$itemnum) {
           $i++;
           C4::Biblio::DelBiblio($bibnum);
           print "\n DELETED eresource book: $final_tag with bibnumber $bibnum \n";
           $deleted++;
         }
#fixme:  remove from deleteditems and deleted biblio?

     }
   }
 }
}

print "\n\n$found records found\n$deleted bib records deleted.\n";


