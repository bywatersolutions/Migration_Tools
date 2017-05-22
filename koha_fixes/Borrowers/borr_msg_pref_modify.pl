#!/usr/bin/perl
#---------------------------------
# Copyright 2015 ByWater Solutions
#
#---------------------------------
#
# -D Ruth Bavousett
#  -modified by:
#    J Nelson, took borrower modification script and change to modify messaging preferences from email to nothing (print)
#---------------------------------
#
# EXPECTS:
#   -input CSV in this form:
#      <borrowernumber>
#
# DOES:
#   -updates the values described, if --update is set
#
# CREATES:
#   -nothing
#
# REPORTS:
#   -count of records read
#   -count of borrowers modified

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use Text::CSV_XS;
use C4::Context;
use C4::Members;
$|=1;
my $debug = 0;
my $doo_eet = 0;
my $i=0;
my $written=0;

my $infile_name = q{};

GetOptions(
   'in:s'     => \$infile_name,
   'debug'    => \$debug,
   'update'   => \$doo_eet,
);

if ($infile_name eq q{}) {
   print "Something's missing.\n";
   exit;
}

my $csv=Text::CSV_XS->new();
my $dbh=C4::Context->dbh();
open my $infl,"<",$infile_name;

RECORD:
while (my $line=$csv->getline($infl)){
   last RECORD if ($debug and $i>50); 
   $i++;
   print "." unless ($i % 10);
   print "\r$i" unless ($i % 100);
   my @data = @$line; 
$debug and print "borrower: $data[0] \n";
   my $borrower=$data[0];

   if ($doo_eet && $borrower){
     print "$data[0] => $borrower to be updated\n";
     my $update_sth =$dbh->prepare("DELETE from borrower_message_transport_preferences where borrower_message_preference_id in (select borrower_message_preference_id from borrower_message_preferences where borrowernumber=?)");
     $update_sth->execute($borrower);
     my $digest_sth = $dbh->prepare("update borrower_message_preferences set wants_digest=0 where borrowernumber=?");
     $digest_sth->execute($borrower);
     $written++;
   }
}

print "\n\n$i records read.\n$written borrowers updated.\n";
