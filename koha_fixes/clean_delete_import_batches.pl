#!/usr/bin/perl
#---------------------------------
# Copyright 2012 ByWater Solutions
#
#---------------------------------
#
# -D Ruth Bavousett
# 
# Modification log: (initial and date)
# 2017-04-20 new feature in 16.05 to allow deleting of batches
#    modified to allow optional deleting of batches
#    -joy nelson
#
#
#---------------------------------
#
# EXPECTS:
#   -date before which batches should be deleted
#   -option -d if you wish to delete batches also
#
# DOES:
#   -cleans import batches, if --update is set
#   -deletes import batchs, if --d and --update is set
#
# CREATES:
#   -nothing
#
# REPORTS:
#   -what would be done, if --debug is set
#   -number of batches cleaned
#   -number of batches deleted

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
use C4::ImportBatch;

local    $OUTPUT_AUTOFLUSH =  1;
Readonly my $NULL_STRING   => q{};

my $debug   = 0;
my $doo_eet = 0;
my $i       = 0;
my $j       = 0;
my $k       = 0;
my $written = 0;
my $deleted = 0;
my $problem = 0;
my $todelete = 0;

my $date = $NULL_STRING;

GetOptions(
    'before=s' => \$date,
    'debug'    => \$debug,
    'd'        => \$todelete,
    'update'   => \$doo_eet,
);

for my $var ($date) {
   croak ("You're missing something") if $var eq $NULL_STRING;
}

my $dbh = C4::Context->dbh();
my $sth = $dbh->prepare("SELECT import_batch_id,upload_timestamp FROM import_batches WHERE upload_timestamp < '$date'");
$sth->execute();

LINE:
while (my $line=$sth->fetchrow_hashref()) {
   $i++;
   print '.'    unless ($i % 10);
   print "\r$i" unless ($i % 100);
   $debug and print "Cleaning batch $line->{import_batch_id} ($line->{upload_timestamp}).\n";
   if ($doo_eet) {
      CleanBatch($line->{import_batch_id});
      $written++;
     if ($todelete) {
       DeleteBatch($line->{import_batch_id});
       $deleted++;
     }
   }
}

print << "END_REPORT";

$i batches found.
$written batches cleaned.
$deleted batches deleted.
END_REPORT

exit;
