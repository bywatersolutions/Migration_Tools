#!/usr/bin/perl
#---------------------------------
# Copyright 2012 ByWater Solutions
#
#---------------------------------
#
# -D Ruth Bavousett
# 
# Modification log: (initial and date)
#
#---------------------------------
#
# EXPECTS:
#  -barcodes of items in a csv file
#
# DOES:
#  -removes entry from issues table
#  -inserts entry for checkout into old_issues
#  -deletes the item
#
# CREATES:
#   -nothing
#
# REPORTS:
#   -count of items deleted

use autodie;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use English qw( -no_match_vars );
use Getopt::Long;
use Readonly;
use Text::CSV_XS;
use C4::Context;
use C4::Items;

local    $OUTPUT_AUTOFLUSH =  1;
Readonly my $NULL_STRING   => q{};

my $debug   = 0;
my $doo_eet = 0;
my $i       = 0;
my $j       = 0;
my $k       = 0;
my $written = 0;
my $problem = 0;
my $returndate;
my $barcodefile;

GetOptions(
    'file:s'       => \$barcodefile,
    'returndate:s' => \$returndate,
    'debug'        => \$debug,
    'update'       => \$doo_eet,
);

for my $var ($returndate, $barcodefile) {
   croak ("You're missing something") if $var eq $NULL_STRING;
}

my $csv=Text::CSV_XS->new({ binary => 1});
open my $infl,"<",$barcodefile;

my $dbh=C4::Context->dbh;
my $sth=$dbh->prepare("SELECT itemnumber,biblionumber FROM issues 
                              JOIN items USING (itemnumber)
                              WHERE barcode=?");
my $getissue_sth=$dbh->prepare ("SELECT borrowernumber,date_due,branchcode,issuedate  from issues where itemnumber=?");
my $del_sth=$dbh->prepare("DELETE FROM issues WHERE itemnumber=?");
my $oldissue_sth=$dbh->prepare("INSERT INTO old_issues (borrowernumber,itemnumber,date_due,branchcode,returndate,issuedate) VALUES (?,?,?,?,?,?)");


LINE:
while (my $line=$csv->getline($infl)){
   last RECORD if ($debug and $i>5000);
   $i++;
   print "." unless ($i % 10);
   print "\r$i" unless ($i % 100);
   my @data = @$line;

   $sth->execute($data[0]);

   my $rec=$sth->fetchrow_hashref(); 
   if (!$rec) {
     next LINE;
   }
   else {
     $debug and print "Item $rec->{itemnumber}\n";
   }

   if ($doo_eet) {

      $getissue_sth->execute($rec->{itemnumber});
      my $issue=$getissue_sth->fetchrow_hashref();

      $del_sth->execute($rec->{itemnumber});

      $oldissue_sth->execute($issue->{borrowernumber},$rec->{itemnumber},$issue->{date_due},$issue->{branchcode},$returndate,$issue->{issuedate});

      DelItem($dbh,$rec->{biblionumber},$rec->{itemnumber});
      $written++;
   }
}

print << "END_REPORT";

$i items found.
$written items dropped.
END_REPORT

exit;
