#!/usr/bin/perl
#---------------------------------
# Copyright 2014 ByWater Solutions
#
#---------------------------------
#
# -Joy Nelson
#
#---------------------------------
#
# EXPECTS:
#   -input CSV with these columns, borrower cardnumber, reserve date, cancel date, branchcode, item barcode:
#
# DOES:
#   -inserts current holds into database, if --update is set
#
# CREATES:
#   -nothing
#
# REPORTS:
#   -what would have been done, if --debug is set
#   -problematic records
#   -count of records read
#   -count of records inserted
#   -count of failed insertions

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use Text::CSV_XS;
use C4::Context;
use C4::Items;
use C4::Members;
$|=1;
my $debug=0;
my $doo_eet=0;
my $i=0;

my $infile_name = "";
my $item_map_filename = q{};
my $borr_map_filename = q{};

GetOptions(
    'in=s'            => \$infile_name,
    'item=s'          => \$item_map_filename,
    'borr=s'          => \$borr_map_filename,
    'debug'           => \$debug,
    'update'          => \$doo_eet,
);

if (($infile_name eq '') ){
  print "Something's missing.\n";
  exit;
}

print "Loading item barcode map:\n";
my $mapcsv = Text::CSV_XS->new();
my %item_map;
open my $itemmap,"<",$item_map_filename;
while (my $map_line = $mapcsv->getline($itemmap)) {
   $i++;
   print '.'    unless ($i % 10);
   print "\r$i" unless ($i % 100);
   my @data = @$map_line;
   $item_map{$data[0]} = $data[1];
}

print "Loading borrower map:\n";
my $mapcsv2 = Text::CSV_XS->new();
my %borr_map;
open my $borrmap,"<",$borr_map_filename;
while (my $map_line = $mapcsv2->getline($borrmap)) {
   $i++;
   print '.'    unless ($i % 10);
   print "\r$i" unless ($i % 100);
   my @data = @$map_line;
   $borr_map{$data[0]} = $data[1];
}


print "Processing issues.\n";
$i=0;
my $csv = Text::CSV_XS->new();
open my $in,"<$infile_name";
$csv->column_names( $csv->getline($in) );
my $written=0;
my $problem=0;
my $dbh = C4::Context->dbh();
my $borr_sth = $dbh->prepare("SELECT borrowernumber FROM borrowers WHERE cardnumber=?");
my $item_sth = $dbh->prepare("SELECT itemnumber,biblionumber FROM items WHERE barcode=?");
my $rsv_sth = $dbh->prepare("INSERT INTO reserves
                 (borrowernumber,reservedate,cancellationdate,itemnumber,biblionumber,branchcode, constrainttype,suspend,suspend_until)
                  VALUES (?, ?, ?, ?,?,?,'a',?,?)");

RECORD:
while (my $line = $csv->getline_hr($in)) {
   $i++;
   print ".";
   print "\r$i" unless $i % 100;

   my $thisborrower = $line->{'cardnumber'};
   $thisborrower =~ s/\s//;
$debug and print "$thisborrower\n";

   if (exists $borr_map{$thisborrower}) {
     $thisborrower=$borr_map{$thisborrower};
   }
#   else {
#    print "No borr found for $thisborrower in map\n";
#    next RECORD;
#   }


   $borr_sth->execute($thisborrower);
   my $hash=$borr_sth->fetchrow_hashref();
   $thisborrower=$hash->{'borrowernumber'};
   if (!$thisborrower) {
     print "no borrower found in database for $thisborrower\n";
     next RECORD;
   }

   my $thisitem=$line->{'barcode'};
   if (exists $item_map{$thisitem}) {
     $thisitem=$item_map{$thisitem};
   }
#   else {
#    print "No barcode found for $thisitem in map\n";
#    next RECORD;
#   }

#print "value of this item is $thisitem\n";
   $item_sth->execute($thisitem);
   my $hash2=$item_sth->fetchrow_hashref();
   my $thisbib=$hash2->{'biblionumber'};
   $thisitem=$hash2->{'itemnumber'};

   if (!$thisitem) {
     print "no item found in database for $line->{'itemnumber'}\n";
     next RECORD;
   }

#   my $this_reserve_date = _process_date($line->{reservedate});
#   my $this_cancel_date = _process_date($line->{cancellationdate});
   my $this_reserve_date = ($line->{reservedate});
   my $this_cancel_date = ($line->{expirationdate});

   my $suspend = ($line->{'suspend'}) || 0;
   my $suspend_until = ($line->{'suspend_until'}) || 'NULL';

   if ($thisborrower && $thisitem && $this_reserve_date ) {
      $written++;
#      my $item = GetItem($thisitem);
      my $borrower = GetMemberDetails($thisborrower);
      $debug and print "B:$thisborrower I:$thisitem B:$thisbib O:$this_reserve_date Br:$borrower->{branchcode}\n";
      if ($doo_eet){
         $rsv_sth->execute($thisborrower,
                             $this_reserve_date,
                             $this_cancel_date,
                             $thisitem,
                             $thisbib,
                             $borrower->{branchcode},
                             $suspend,
                             $suspend_until
                          );
      }
   }
   else{
      print "\nProblem record:\n";
      print "B:$thisborrower  I:$thisitem  Date:$line->{'reservedate'}\n";
      $problem++;
   }
   last if ($debug && $written>20);
   next;
}

close $in;

print "\n\n$i lines read.\n$written issues loaded.\n$problem problem issues not loaded.\n";
exit;

sub _process_date {
   my $datein=shift;
   return undef if $datein eq q{};
   my ($month,$day,$year) = split /\//, $datein;
   return sprintf "%4d-%02d-%02d",$year,$month,$day;
}
