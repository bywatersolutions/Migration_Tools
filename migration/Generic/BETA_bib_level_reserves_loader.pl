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
#   -input CSV with these columns, borrower cardnumber, bibid, reserve date, cancel date, branchcode,suspend,suspend_until
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
my $borr_map_filename = q{};
my $bib_map_filename = q{};

GetOptions(
    'in=s'            => \$infile_name,
    'borr_map=s'      => \$borr_map_filename,
    'bib_map=s'       => \$bib_map_filename,
    'debug'           => \$debug,
    'update'          => \$doo_eet,
);

if (($infile_name eq '') ){
  print "Something's missing.\n";
  exit;
}

print "Loading bib map:\n";
my $mapcsv = Text::CSV_XS->new();
my %bib_map;
open my $bibmap,"<",$bib_map_filename;
while (my $map_line = $mapcsv->getline($bibmap)) {
   $i++;
   print '.'    unless ($i % 10);
   print "\r$i" unless ($i % 100);
   my @data = @$map_line;
   $bib_map{$data[0]} = $data[1];
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


print "Processing holds.\n";
$i=0;
my $csv = Text::CSV_XS->new();
open my $in,"<$infile_name";
$csv->column_names( $csv->getline($in) );
my $written=0;
my $problem=0;
my $dbh = C4::Context->dbh();
my $borr_sth = $dbh->prepare("SELECT borrowernumber FROM borrowers WHERE cardnumber=?");
#my $item_sth = $dbh->prepare("SELECT itemnumber,biblionumber FROM items WHERE barcode=?");
my $rsv_sth = $dbh->prepare("INSERT INTO reserves
                 (borrowernumber,reservedate,cancellationdate,biblionumber,branchcode, priority,constrainttype,suspend,suspend_until)
                  VALUES (?, ?, ?, ?,?,?,'a',?,?)");

RECORD:
while (my $line = $csv->getline_hr($in)) {
   $i++;
   print ".";
   print "\r$i" unless $i % 100;
   $line->{cardnumber} =~ s/\s//;
   $borr_sth->execute($line->{cardnumber});
   my $hash=$borr_sth->fetchrow_hashref();
   my $thisborrower=$hash->{'borrowernumber'};

   if (!$thisborrower) {
     print "no borrower found for $line->{cardnumber}\n";
     next RECORD;
   }
   my $priority = $line->{priority};
   my $branchcode = $line->{branchcode};
   my $thisbib = $line->{bibid};

   if (exists $bib_map{$thisbib}) {
     $thisbib=$bib_map{$thisbib};
   }
   else {
    print "No bib found for $thisbib\n";
    next RECORD;
   }

#   my $this_reserve_date = _process_date($line->{reservedate});
#   my $this_cancel_date = _process_date($line->{cancellationdate});
   my $this_reserve_date = ($line->{reservedate});
   my $this_cancel_date = ($line->{cancellationdate});
   my $suspend = ($line->{'suspend'}) || 0;
   my $suspend_until = ($line->{'suspend_until'}) || 'NULL';

   if ($thisborrower && $thisbib && $this_reserve_date ) {
      $written++;

      $debug and print "Borr:$thisborrower  Bib:$thisbib O:$this_reserve_date Br:$branchcode\n";
      if ($doo_eet){
         $rsv_sth->execute($thisborrower,
                             $this_reserve_date,
                             $this_cancel_date,
                             $thisbib,
                             $branchcode,
                             $priority,
                             $suspend,
                             $suspend_until
                          );
      }
   }
   else{
      print "\nProblem record:\n";
      print "B:$line->{cardnumber}  bib:$line->{bibid}  O:$line->{reservedate}\n";
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
