#!/usr/bin/perl
#---------------------------------
# Copyright 2011 ByWater Solutions
#
#---------------------------------
#
# -D Ruth Bavousett
#
#---------------------------------
#  
use strict;
use warnings;
use Getopt::Long;
use Text::CSV;
use C4::Context;
use C4::Members;
$|=1;
my $debug=0;
my $doo_eet=0;

GetOptions(
    'update'     => \$doo_eet,
    'debug'      => \$debug,
);

my $dbh=C4::Context->dbh();
my $i=0;
my $modified=0;
my $query = "SELECT borrowernumber,city FROM borrowers where city <> '' ";

my $find = $dbh->prepare($query);
$find->execute();

RECORD:
while (my $row=$find->fetchrow_hashref()){
  my $city;
  my $state;
  my $zip;
   $i++;
   print ".";
   print "\r$i" unless ($i % 100);
   my $address =   $row->{city};
   if ($address =~ m/^(\w+\s?\w{3,}\,?)\s+([A-Z][A-Z],{0,1})\s+(\d{5}\-?\d{0,4})$/g ) {
       $address =~m/^(\w+\s?\w{3,}\,?)\s+([A-Z][A-Z],{0,1})\s+(\d{5}\-?\d{0,4})$/g;
       $city=$1;
       $state=$2;
       $zip=$3;
       $city =~ s/,//g;
       $city =~ s/\s$//g;
       $city =~ s/^\s//g;
       $state =~ s/,//g;
       $state =~ s/\s$//g;
       $state =~ s/^\s//g;
       $zip =~ s/\s$//g;
       $zip =~ s/^\s//g;

       $debug and print "$address => $city   ---   $state   ---   $zip\n";
   }

   if ($city && $state && $zip){
      $debug and print "Changing $row->{'borrowernumber'} $address   NEW CITY:$city  NEW ST:$state NEW ZIP:$zip \n";
      $doo_eet and C4::Members::ModMember(borrowernumber => $row->{'borrowernumber'}, 
                                          city           => $city,
                                          state          => $state,
                                          zipcode        => $zip);
      $modified++;
   }
}

print "\n$i records examined.\n$modified records modified.\n";
