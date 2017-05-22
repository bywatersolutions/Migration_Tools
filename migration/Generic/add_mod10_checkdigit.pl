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
#   -nothing
#
# DOES:
#   -modifies borrower.cardnumber and items.barcode, if --update is set
#
# CREATES:
#   -nothing
#
# REPORTS:
#   -number of borrowers, items considered
#   -number of borrowers, items modified

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
use List::Util qw( sum );
use Algorithm::LUHN qw/check_digit is_valid/;

local    $OUTPUT_AUTOFLUSH =  1;
Readonly my $NULL_STRING   => q{};
my $start_time             =  time();

my $debug   = 0;
my $doo_eet = 0;
my $i       = 0;
my $j       = 0;
my $k       = 0;
my $z       = 0;
my $written = 0;
my $written2 = 0;
my $problem = 0;
my $branch = "";

GetOptions(
    'branch=s' => \$branch,
    'debug'    => \$debug,
    'update'   => \$doo_eet,

);

my $dbh = C4::Context->dbh();
my $cardnumb_sth = $dbh->prepare("SELECT cardnumber FROM borrowers where branchcode= ?");
my $checkdig_sth = $dbh->prepare("UPDATE borrowers SET cardnumber = ? WHERE cardnumber = ?");
#my $item_sth = $dbh->prepare("SELECT barcode FROM items where homebranch= ?");
#my $barcodedig_sth = $dbh->prepare("UPDATE items set barcode = ? WHERE barcode = ?");

$cardnumb_sth->execute($branch);

LINE:
while (my $line=$cardnumb_sth->fetchrow_hashref()) {
   $i++;
   print '.'    unless ($i % 10);
   print "\r$i" unless ($i % 100);

   my $borr = $line->{cardnumber};

   if ( ($borr =~ m/[A-Za-z]/ ) || (length($borr) >13) ) {
     next LINE;
   }

   my $newcard = addCheckDigit($borr);
   $debug and print "borrowers: $line->{cardnumber}, $newcard\n";

   if ($doo_eet) {
      $checkdig_sth->execute($newcard,$borr);
   }
   $written++;
}

#$item_sth->execute($branch);

#ITEM:
#while (my $line2=$item_sth->fetchrow_hashref()) {
#   $z++;
#   print '.'    unless ($i % 10);
#   print "\r$i" unless ($i % 100);
#
#   my $item = $line2->{barcode};
#
#   if (! $item) {
#    next ITEM;
#   }
#
#   if ( ($item =~ m/[A-Za-z]/ ) || (length($item) >13) ) {
#       next ITEM;
#   }
#
#   my $newbar = addCheckDigit($item);
#   $debug and print "item: $line2->{barcode}, $newbar\n";
#
#   if ($doo_eet) {
#      $barcodedig_sth->execute($newbar,$item);
#   }
#   $written2++;
#}

print << "END_REPORT";

$i borrowers  read.
#$z items read.
$written borrowers updated.
#$written2 items updated.
END_REPORT

my $end_time = time();
my $time     = $end_time - $start_time;
my $minutes  = int($time / 60);
my $seconds  = $time - ($minutes * 60);
my $hours    = int($minutes / 60);
$minutes    -= ($hours * 60);

printf "Finished in %dh:%dm:%ds.\n",$hours,$minutes,$seconds;

exit;

sub addCheckDigit {
    my ($barcode) = @_;
#    my @digits = reverse( split( //, $barcode ) );
#    my @odds = @digits[ grep( { !( $_ & 1 ) } 0..(@digits - 1) ) ];
#    my @evens = @digits[ grep( { $_ & 1 } 1..(@digits - 1) ) ];
#    my $sum = sum( join( '', reverse( @odds ) ) * 2 );
#    my $checksum = sum( @evens ) + $sum;
#    return $barcode . ( ( 10 - ( $checksum % 10 ) ) % 10 );
my $c = check_digit($barcode);
return $barcode . $c;
}
