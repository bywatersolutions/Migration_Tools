#!/usr/bin/perl
# Written by: Joy Nelson
#
# EXPECTS:
#  -csv of borrowernumber
#
# CREATES:
#   -nothing
#
# REPORTS:
#   -count of borrowers deleted
#
# TODO:
# Can we add a backup feature to this script so files are backed up for patrons being deleted?
#  borrowers, circ, reserves, accountlines for just the borrowers listed in the incoming file.
#

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
use C4::Serials;
use C4::Members;
use MARC::Record;
use MARC::Field;
use Koha::Patrons;

$|=1;
my $debug=0;
my $doo_eet=0;
my $i=0;
my $in_file ="";

GetOptions(
    'debug'    => \$debug,
    'update'   => \$doo_eet,
    'file:s'   => \$in_file,
);

if ($in_file eq q{}){
   print "Something's missing.\n";
   exit;
}

my $deleted = 0;
my $dbh = C4::Context->dbh();
my $csv = Text::CSV_XS->new();
open my $infl,"<",$in_file;

my $issues_sth = $dbh->prepare("SELECT count(*) FROM issues where borrowernumber=?");
my $fines_sth = $dbh->prepare("SELECT sum(amountoutstanding) FROM accountlines where borrowernumber=?");

#spin through your CSV and move member to deleted.
my @data;
my $line;

RECORD:
while ($line=$csv->getline($infl)){
  @data = @$line;

  $issues_sth->execute($data[0]);
  my $issue_fetch=$issues_sth->fetchrow_hashref();
  my $issuecount=$issue_fetch->{'count(*)'};

  $fines_sth->execute($data[0]);
  my $fines_fetch=$fines_sth->fetchrow_hashref();
  my $finesum=$fines_fetch->{'sum(amountoutstanding)'};

  if ( ($issuecount > 0)  || ($finesum <> 0) ) {
    print "Not deleting this poor soul...they have checkouts or fines ($finesum) --> borrowernumber: $data[0]\n";
    next RECORD;
  }


  if ($doo_eet){
    my $patron = Koha::Patrons->find( $data[0] );
    if ($patron) {
     $patron->move_to_deleted;
     $patron->delete;
     $deleted++;
    }
   else {
    print "no patron found for borrowernumber $data[0]\n";
   }
  }
}

print "\n$deleted borrower records deleted and moved to deleted_borrower table.\n";




