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
my $itemcount_sth = $dbh->prepare("SELECT count(*) FROM items WHERE biblionumber = ?");

my $problem = 0;
my $final_tag;

my $sth = $dbh->prepare("SELECT biblionumber from biblio ");
$sth->execute();

RECORD:
while (my $row = $sth->fetchrow_hashref()){
  last RECORD if ($debug and $written > 0);
  $i++;
  print '.' unless ($i % 10);
  print "\r$i" unless ($i % 100);

  my $record = GetMarcBiblio($row->{'biblionumber'});
  my $bibnum = $row->{'biblionumber'};
  next RECORD if (!$record->subfield('856','u'));
  $debug and print "Biblionumber is $bibnum\n";
#spin through all 856 tags
TAG:
 foreach my $urltag ($record->field("856")){
  my $tag = $urltag->subfield("u") || "NONE FOUND";
  
  if ($tag =~ m/$vendor/) {
     ($final_tag) = $tag =~ m/(=\d+)$/;
     if ($final_tag) {
      $final_tag =~ s/^=//;
     }
     else {
      $final_tag = "INVALID";
      print "$bibnum has invalid final tag in $tag\n";
    }
  }
  else {
     $final_tag = "NO VENDOR";
  }

  if ((exists $ebooks{$final_tag}) && $doo_eet){
        print "This is the tag $tag\n and the final tag $final_tag \n";
        $itemcount_sth->execute($bibnum);
        my $itemcountfetch=$itemcount_sth->fetchrow_hashref();
        my $itemcount = $itemcountfetch->{'count(*)'};
        print "Number of items found is $itemcount\n";

        if ($itemcount == 0) {
          C4::Biblio::DelBiblio($bibnum);
          print "\n DELETED eresource: $final_tag with bibnumber $bibnum \n";
          $deleted++;
        }
        if ($itemcount == 1) {
          $item_sth->execute($bibnum);
          my $db_item_fetch=$item_sth->fetchrow_hashref();
          my $itemnum=$db_item_fetch->{'itemnumber'};
          print "NUKING: items and biblio for biblionumber: $bibnum\n";
          C4::Items::DelItem({itemnumber=>$itemnum,biblionumber=>$bibnum});
          C4::Biblio::DelBiblio($bibnum);
          print "\n DELETED eresource: $final_tag with bibnumber $bibnum \n";
          $deleted++;
        }
        if ($itemcount > 1) {
          print "\n Cannot delete $final_tag on biblionumber $bibnum Because multiple items found \n";
          $problem++;
        }
  }
 }

}

print "\n\n$problem problem records found\n$deleted records deleted.\n";


