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
my $sth=$dbh->prepare("DELETE FROM deletedborrowers WHERE borrowernumber = ?");
open my $infl,"<",$in_file;

#spin through your CSV and move member our of deleted.
my @data;
my $line;

while ($line=$csv->getline($infl)){
  @data = @$line;
  if ($doo_eet){
    $sth->execute($data[0]);
    $deleted++;
  }
}

print "\n$deleted borrower records deleted and moved to deleted_borrower table.\n";




