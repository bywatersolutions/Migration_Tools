#!/usr/bin/perl
#-----------------
# Copyright 2017 ByWater Solutions
#
#----------------
#
# EXPECTS:
#  option inputs for branchcode - 
#      -b  will remove links for bibs where there is at least 1 item at the branch specified
#      -o  will remove links for bibs where ALL the items belong to the branch specified
#  Use -c to commit changes to database
#  Without -c it will do a 'dry-run'
#
#---------------






use Modern::Perl;

use C4::Context;
use C4::Biblio;

use Getopt::Long;

say "Unlinking all authorities on database " . C4::Context->config( 'database' );
print "\n";

my ( $actually_commit, $branchcode, $only_branchcode );

GetOptions(
	'c' => \$actually_commit,
	'b:s' => \$branchcode, # Only edit bibs with items from this branch
	'o:s' => \$only_branchcode, # Only edit bibs with only items from this branch
);

my ( $q, @args );

if ( $only_branchcode ) {
	$q = q{
	    SELECT GROUP_CONCAT(items.homebranch SEPARATOR ',') AS homebranches, biblio.biblionumber, frameworkcode
	    FROM items LEFT JOIN biblio USING(biblionumber)
	    GROUP BY biblionumber
	    HAVING homebranches = ?
	};
	push @args, $only_branchcode;
} elsif ( $branchcode ) {
	$q = q{
	    SELECT biblio.biblionumber, frameworkcode
	    FROM items LEFT JOIN biblio USING(biblionumber)
	    WHERE items.homebranch = ?
	};
	push @args, $branchcode;
} else {
	$q = q{
	    SELECT biblio.biblionumber, frameworkcode
	    FROM biblio
	};
}

my $bibs = C4::Context->dbh->selectall_arrayref( $q, { Slice => {} }, @args );

my $invalid_records = 0;
my $updated_records = 0;
my $removed_links = 0;

foreach my $bib ( @$bibs ) {
    my $record = GetMarcBiblio( $bib->{'biblionumber'} );
    
    if ( !$record ) {
        $invalid_records++;
        next;
    }

    my $updated = 0;

    foreach my $field ( $record->field( '[124678]..' ) ) {
        my @links = $field->subfield( '9' );
        if ( $field->delete_subfield( code => '9' ) ) {
            say "Removed link from bib #" . $bib->{'biblionumber'} . ", tag " . $field->tag() . " to auth #" . join( ', ', @links );
            $removed_links++;
            $updated = 1;
        }
    }

    if ( $updated ) {
        $updated_records++;
        if ( $actually_commit ) {
            ModBiblio( $record, $bib->{'biblionumber'}, $bib->{'frameworkcode'} );
        }
    }
}

print "\n";
say "Final report:";
say "  Updated biblios: " . $updated_records;
say "  Invalid biblios: " . $invalid_records;
say "  Removed links: " . $removed_links;

unless ( $actually_commit ) {
    print "\n";
    say "This was a dry run, re-run with -c to save changes.";
}
