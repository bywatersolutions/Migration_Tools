#!/usr/bin/perl

# Written by: Joy Nelson
#
# CREATES:
#   -nothing
#
# REPORTS:
#   -count of biblios deleted
#
# WARNING!!!
#  This will delete all items on biblio.  Be sure you wish to delete all items before running
#  note 4/18/2013 jn: warning may not be applicable now.  appears delbiblio does not delete all items at all. it wont'
#  delete bibs if items attached.
#

use Modern::Perl;

use Data::Dumper;
use Getopt::Long;
use Text::CSV_XS;
use MARC::Record;
use MARC::Field;

use C4::Context;
use C4::Biblio;
use C4::Items;
use C4::Serials;

$| = 1;
my $doo_eet = 0;
my $i       = 0;
my $in_file = "";
my $delete_items;
my $verbose;
my $help;

GetOptions(
    'u|update'  => \$doo_eet,
    'f|file:s'  => \$in_file,
    'i|items'   => \$delete_items,
    'v|verbose' => \$verbose,
    'h|help'    => \$help,
);

if ( $help || !$in_file ) {
    say "$0 --file <file>";
    say "    -f --file        Specify the CSV file to use [required]";
    say "    -u --update      If set, actually delete the records, otherwise nothing happens";
    say "    -i --items       Deletes records with items";
    say "    -h --help        Displays this message";
    exit;
}

my $csv = Text::CSV_XS->new();
open my $infl, "<", $in_file;

#spin through your CSV and DelBiblio on the biblionumber from csv.
my @data;
my $line;

my $records_deleted = 0;
my $items_deleted   = 0;
while ( $line = $csv->getline($infl) ) {
    @data = @$line;
    if ($doo_eet) {
        my $biblionumber = $data[0];
        if ($delete_items) {
            my $items = GetItemnumbersForBiblio($biblionumber);
            foreach my $itemnumber (@$items) {
                my $success = DelItem( { itemnumber => $itemnumber, biblionumber => $biblionumber } );
                $items_deleted++ if $success;
            }
        }
        my $error = C4::Biblio::DelBiblio($biblionumber);
        $records_deleted++ unless $error;
        say "ERROR DELETING RECORD: $error" if ( $error && $verbose );
    }
}

say "$records_deleted records deleted.";
say "$items_deleted items deleted." if $delete_items;
