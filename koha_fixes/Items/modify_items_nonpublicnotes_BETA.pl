#!/usr/bin/perl
#---------------------------------
# Copyright 2011 ByWater Solutions
#
#---------------------------------
#
# -Joy Nelson
#
#---------------------------------
#
# EXPECTS:
#   -input CSV in this form:
#      <item barcode>,<nonpublic note>
#
# DOES:
#   -updates the value described, if --update is set
#
# CREATES:
#   -nothing
#
# REPORTS:
#   -count of records read
#   -count of items modified
#   -count of items not modified due to missing barcode
#   -details of what will be changed, if --debug is set

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use Text::CSV_XS;
use C4::Context;
use C4::Items;
$|=1;
my $debug = 0;
my $doo_eet = 0;
my $i=0;

my $infile_name = q{};
my $csv_delim            = 'comma';
my $barprefix = "";
my $barlength = 0;

GetOptions(
   'in:s'     => \$infile_name,
   'delimiter=s'  => \$csv_delim,
   'itemprefix:s' => \$barprefix,
   'barlength:s' => \$barlength,
   'debug'    => \$debug,
   'update'   => \$doo_eet,
);

if (($infile_name eq q{})){
   print "Something's missing.\n";
   exit;
}

my %delimiter = ( 'comma' => ',',
                  'tab'   => "\t",
                  'pipe'  => '|',
                );
my $written=0;
my $item_not_found=0;
my $csv=Text::CSV_XS->new({ binary => 1, sep_char => $delimiter{$csv_delim} });
my $dbh=C4::Context->dbh();
my $sth=$dbh->prepare("SELECT itemnumber, biblionumber FROM items WHERE barcode = ?");
open my $infl,"<",$infile_name;

RECORD:
while (my $line=$csv->getline($infl)){
   last RECORD if ($debug and $i>1000);
   $i++;
   print "." unless ($i % 10);
   print "\r$i" unless ($i % 100);
   my @data = @$line; 

   if ($barprefix ne '' || $barlength > 0) {
            my $curbar = $data[0];
            my $prefixlen = length($barprefix);
            if (($barlength > 0) && (length($curbar) <= ($barlength-$prefixlen))) {
               my $fixlen = $barlength - $prefixlen;
               while (length ($curbar) < $fixlen) {
                  $curbar = '0'.$curbar;
               }
               $curbar = $barprefix . $curbar;
            }
            $data[0] = $curbar;
   }


   $sth->execute($data[0]);
   my $rec=$sth->fetchrow_hashref();

   if (!$rec){
      $item_not_found++;
      next RECORD;
   }

   my $new_value=$data[1];
   $debug and print "$data[0] ($rec->{itemnumber})  note to adde => $new_value\n";

   my $itemmarc=C4::Items::GetMarcItem($rec->{'biblionumber'},$rec->{'itemnumber'}); 
   my $unlinked_item_subfields = C4::Items::_get_unlinked_item_subfields( $itemmarc, ' ' );
print @unlinked_item_subfields;
   if ($doo_eet){
      C4::Items::ModItem({'more_subfields_xml' => $new_value },$rec->{'biblionumber'},$rec->{'itemnumber'},$unlinked_item_subfields);
   }
   $written++;
}
close $infl;
print "\n\n$i records read.\n$written items updated.\n$item_not_found not updated due to unknown barcode.\n";

exit;

