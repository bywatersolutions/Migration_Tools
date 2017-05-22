# Written by: Joy Nelson
#
# EXPECTS:
#  -csv of borrower's cardnumber
#
# CREATES:
#   -nothing
#
# REPORTS:
#   -count of borrowers deleted

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
my $patron_sth = $dbh->prepare("SELECT borrowernumber FROM borrowers WHERE cardnumber=?");
my $issues_sth = $dbh->prepare("SELECT count(*) FROM issues where borrowernumber=?");
my $fines_sth = $dbh->prepare("SELECT sum(amountoutstanding) FROM accountlines where borrowernumber=?");

#spin through your CSV and move member to deleted.
my @data;
my $line;

RECORD:
while ($line=$csv->getline($infl)){
  @data = @$line;

  $patron_sth->execute($data[0]);
  my $patron_fetch=$patron_sth->fetchrow_hashref();
  my $patron_num=$patron_fetch->{'borrowernumber'};

  $issues_sth->execute($patron_num);
  my $issue_fetch=$issues_sth->fetchrow_hashref();
  my $issuecount=$issue_fetch->{'count(*)'};

  $fines_sth->execute($patron_num);
  my $fines_fetch=$fines_sth->fetchrow_hashref();
  my $finesum=$fines_fetch->{'sum(amountoutstanding)'};

  if ( ($issuecount > 0)  || ($finesum <> 0) ) {
    print "Not deleting this poor soul...they have checkouts or fines ($finesum --> $patron_num : $data[0]\n";
    next RECORD;
  }

  if ($patron_num) {
    print "deleting patron borrowernumber: $patron_num with cardnumber $data[0]\n";

    if ($doo_eet){
      my $patron = Koha::Patrons->find( $patron_num );
      $patron->move_to_deleted;
      $patron->delete;   
      $deleted++;
    }
  }
}

print "\n$deleted borrower records deleted and moved to deleted_borrower table.\n";




