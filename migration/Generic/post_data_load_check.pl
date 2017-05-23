#!/usr/bin/perl
#---------------------------------
# Copyright 2016 ByWater Solutions
#
#---------------------------------
#
# -Joy Nelson
#
# Modification log: (initial and date)
#  based on tidy_codes.pl  - but does not remove codes, just reports them.
#
#---------------------------------
#
# EXPECTS:
#   -nothing
#
# DOES:
#   - reports unused branch codes, item types, locations, collection codes, and patron categories
#   - reports missing branch codes, item types, locations, collection codes, and patron categories
#   - checks to see if hold priority is set for non found/non transit items
#   - checks for missing branchcode,missing or bad dates (date_due) in issues/old issues
#   - checks for existence of anonymous borrower
#   - checks for Null 0000-00-00 dates in patrons (dateexpiry/dateenrolled)
#   - checks for 0000-00-00 dates in items (onloan/datelastseen/datelastborrowed/dateaccessioned)
#
# CREATES:
#   -nothing
#
# REPORTS:
#   -what would be done, if --debug is set

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

local    $OUTPUT_AUTOFLUSH =  1;
Readonly my $NULL_STRING   => q{};

my $i = 0; 
my $dbh = C4::Context->dbh(); 
my $sth;

print "IDENTIFYING UNUSED BRANCHES,ITYPES,LOC,CCODE\n";
print "\nIdentify UNUSED branches:\n";
$i = 0;
$sth = $dbh->prepare("SELECT branchcode FROM branches 
                      WHERE branchcode NOT IN (SELECT DISTINCT homebranch FROM items)
                      AND branchcode NOT IN (SELECT DISTINCT holdingbranch FROM items)
                      AND branchcode NOT IN (SELECT DISTINCT branchcode FROM borrowers)");
$sth->execute();
while (my $line=$sth->fetchrow_hashref()) {
   $i++;
   print '.'    unless ($i % 10);
   print "\r$i" unless ($i % 100);
   print "$line->{branchcode}\n";
}
print "\n$i branches are unused in items or borrowers.\n\n";

print "Identify UNUSED item types:\n";
$i = 0;
$sth = $dbh->prepare("SELECT itemtype FROM itemtypes 
		where itemtype not in (SELECT DISTINCT itype from items) 
		AND itemtype not in (SELECT DISTINCT itemtype from biblioitems)");
$sth->execute();
ITEMTYPE:
while (my $line=$sth->fetchrow_hashref()) {
   $i++;
   print '.'    unless ($i % 10);
   print "\r$i" unless ($i % 100);
   print "$line->{itemtype}\n";
}
print "\n$i item types unused.\n\n";

print "Identifying unused location codes:\n";
$i = 0;
$sth = $dbh->prepare("SELECT id,authorised_value FROM authorised_values 
                      WHERE category='LOC' 
                      AND authorised_value NOT IN (SELECT DISTINCT location FROM items)");
$sth->execute();
while (my $line=$sth->fetchrow_hashref()) {
   $i++;
   print '.'    unless ($i % 10);
   print "\r$i" unless ($i % 100);
   print "$line->{authorised_value}.\n";
}
print "\n$i location codes unused.\n\n";

print "Identifying unused collection codes:\n";
$i = 0;
$sth = $dbh->prepare("SELECT id,authorised_value FROM authorised_values 
                      WHERE category='CCODE' 
                      AND authorised_value NOT IN (SELECT DISTINCT ccode FROM items)");
$sth->execute();
while (my $line=$sth->fetchrow_hashref()) {
   $i++;
   print '.'    unless ($i % 10);
   print "\r$i" unless ($i % 100);
   print "$line->{authorised_value}.\n";
}
print "\n$i collection codes unused.\n\n";

print "Identifying unused patron category codes:\n";
$i = 0;
$sth = $dbh->prepare("SELECT categorycode FROM categories 
                      WHERE categorycode NOT IN (SELECT DISTINCT categorycode FROM borrowers)");
$sth->execute();
while (my $line=$sth->fetchrow_hashref()) {
   $i++;
   print '.'    unless ($i % 10);
   print "\r$i" unless ($i % 100);
   print "$line->{categorycode}.\n";
}
print "\n$i patron category codes unused.\n\n";
print "\n\n*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-\n\n";
print "Reporting missing branches:\n";
$i = 0;
$sth = $dbh->prepare("SELECT homebranch FROM items 
                      WHERE homebranch NOT IN (SELECT DISTINCT branchcode FROM branches)");
$sth->execute();
while (my $line=$sth->fetchrow_hashref()) {
   $i++;
   print '.'    unless ($i % 10);
   print "\r$i" unless ($i % 100);
   print "homebranch: $line->{homebranch}\n";
}
print "$i homebranches are not found in Branches table.\n";

$i = 0;
$sth = $dbh->prepare("SELECT holdingbranch FROM items
                      WHERE holdingbranch NOT IN (SELECT DISTINCT branchcode FROM branches)");
$sth->execute();
while (my $line=$sth->fetchrow_hashref()) {
   $i++;
   print '.'    unless ($i % 10);
   print "\r$i" unless ($i % 100);
   print "holdingbranch: $line->{holdingbranch}\n";
}
print "\n$i holdingbranch are not found in Branches table.\n\n";

print "Reporting missing itypes\n";
$i = 0;
$sth = $dbh->prepare("SELECT itype FROM items
                      WHERE itype NOT IN (SELECT DISTINCT itemtype FROM itemtypes)");
$sth->execute();
while (my $line=$sth->fetchrow_hashref()) {
   $i++;
   print '.'    unless ($i % 10);
   print "\r$i" unless ($i % 100);
   print "$line->{itype}\n";
}
print "\n$i itemtypes are not found in items table.\n\n";

print "Reporting missing location codes:\n";
$i = 0;
$sth = $dbh->prepare("SELECT DISTINCT location FROM items
                      WHERE location IS NOT NULL
                      AND location NOT IN (SELECT authorised_value FROM authorised_values WHERE category='LOC')");
$sth->execute();
while (my $line=$sth->fetchrow_hashref()) {
   $i++;
   print '.'    unless ($i % 10);
   print "\r$i" unless ($i % 100);
   print "$line->{location}.\n";
}
print "\n$i location codes not found in Authorised Values.\n\n";

print "Reporting missing collection codes:\n";
$i = 0;
$sth = $dbh->prepare("SELECT DISTINCT ccode FROM items
                      WHERE ccode IS NOT NULL
                      AND ccode NOT IN (SELECT authorised_value FROM authorised_values WHERE category='CCODE')");
$sth->execute();
while (my $line=$sth->fetchrow_hashref()) {
   $i++;
   print '.'    unless ($i % 10);
   print "\r$i" unless ($i % 100);
   print "$line->{ccode}.\n";
}
print "\n$i collection codes added.\n\n";

print "Report missing patron category codes:\n";
$i = 0;
$sth = $dbh->prepare("SELECT categorycode FROM borrowers
                      WHERE categorycode NOT IN (SELECT DISTINCT categorycode FROM categories)");
$sth->execute();
while (my $line=$sth->fetchrow_hashref()) {
   $i++;
   print '.'    unless ($i % 10);
   print "\r$i" unless ($i % 100);
   print "$line->{categorycode}.\n";
}
print "\n$i patron category codes missing from Categories table.\n\n";
print "\n\n*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-\n\n";
print "Report Null or 0000-00-00 patron expiration dates:\n";
$i = 0;
$sth = $dbh->prepare("SELECT count(*) FROM borrowers WHERE dateexpiry is NULL");
$sth->execute();

while (my $line=$sth->fetchrow_hashref()) {
   $i++;
   print '.'    unless ($i % 10);
   print "\r$i" unless ($i % 100);
   print "$line->{'count(*)'} patrons have NULL expiration date.  \n";
}

$i = 0;
$sth = $dbh->prepare("SELECT count(*) FROM borrowers WHERE dateexpiry ='0000-00-00'");
$sth->execute();
while (my $line=$sth->fetchrow_hashref()) {
   $i++;
   print '.'    unless ($i % 10);
   print "\r$i" unless ($i % 100);
   print "$line->{'count(*)'} patrons have 0000-00-00 expiration date.  \n";
}

print "\nReport Null or 0000-00-00 patron enrollment dates:\n";

$i = 0;
$sth = $dbh->prepare("SELECT count(*) FROM borrowers WHERE dateenrolled is NULL");
$sth->execute();

while (my $line=$sth->fetchrow_hashref()) {
   $i++;
   print '.'    unless ($i % 10);
   print "\r$i" unless ($i % 100);
   print "$line->{'count(*)'} patrons have NULL dateenrolled. \n";
}

$i = 0;
$sth = $dbh->prepare("SELECT count(*) FROM borrowers WHERE dateenrolled ='0000-00-00'");
$sth->execute();

while (my $line=$sth->fetchrow_hashref()) {
   $i++;
   print '.'    unless ($i % 10);
   print "\r$i" unless ($i % 100);
   print "$line->{'count(*)'} patrons have 0000-00-00 expiration date. \n";
}
print "\n\n*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-\n\n";
print "Report debarred Patrons missing from Borrower_debarment table\n";
$i = 0;
$sth = $dbh->prepare("SELECT count(*) FROM borrowers WHERE debarred is not NULL and borrowernumber not in
		(select borrowernumber from borrower_debarments) ");
$sth->execute();

while (my $line=$sth->fetchrow_hashref()) {
   $i++;
   print '.'    unless ($i % 10);
   print "\r$i" unless ($i % 100);
   print "$line->{'count(*)'} debarred patrons NOT in borrower_debarments. \n";
}

print "\n\n*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-\n\n";
print "Checking for existence of anonymous borrower\n";
$i = 0;
$sth = $dbh->prepare("SELECT value FROM systempreferences WHERE variable='AnonymousPatron' ");
$sth->execute();
my $anonqry = $sth->fetchrow_hashref();
my $anonborr = $anonqry->{'value'} || 0;

print "Anonymous Patron is NOT set. \n" if ($anonborr == 0);
if ($anonborr>0) {
  $sth = $dbh->prepare("SELECT cardnumber,firstname,surname,userid from borrowers where borrowernumber=?");
  $sth->execute($anonborr);
  my $anondetails = $sth->fetchrow_hashref();
  if (!$anondetails->{'surname'}) {
    print "anonymous borrower system preference is set, but no borrower found\n";
  }
  else {
    print "Anonymous Patron syspref is set and borrower details are:\n cardnumber:$anondetails->{'cardnumber'}, surname:$anondetails->{'surname'}, userid:$anondetails->{'userid'}\n";
  }
}

print "\n\n*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-\n\n";
print "Report on missing branchcode in issues and old_issues\n";
$sth = $dbh->prepare("SELECT count(*) FROM issues WHERE branchcode is NULL 
 	or branchcode not in (select branchcode from branches)");
$sth->execute();

while (my $line=$sth->fetchrow_hashref()) {
   print "$line->{'count(*)'} issues have bad or NULL branchcode.  \n";
}
$sth = $dbh->prepare("SELECT count(*) FROM old_issues WHERE branchcode is NULL
        or branchcode not in (select branchcode from branches)");
$sth->execute();

while (my $line=$sth->fetchrow_hashref()) {
   print "$line->{'count(*)'} old_issues have bad or NULL branchcode.  \n";
}

$sth = $dbh->prepare("select max(issue_id) from issues");
my $sth2 = $dbh->prepare("select max(issue_id) from old_issues");
$sth->execute();
$sth2->execute();
while (my $line2=$sth2->fetchrow_hashref()) {
  my $line=$sth->fetchrow_hashref();
  if ( ( $line2->{'max(issue_id)'} ) && ( $line->{'max(issue_id)'} < $line2->{'max(issue_id)'} )) {
   print "\nMax issue_id in issues is NOT larger than old_issues.  This will be a problem.\n"; 
  }
  else {
   print "issue_ids are ok (issues.issue_id < old_issues.issue_id)\n";
  }
}

print "\n\n*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-\n\n";
print "Report on 00:00:00 time or 0000-00-00 date in issues\n";
$sth = $dbh->prepare("SELECT count(*) FROM issues WHERE date_due like '%00:00:00%' or date_due like '0000-%' or date_due is NULL ");
$sth->execute();

while (my $line=$sth->fetchrow_hashref()) {
   print "$line->{'count(*)'} issues have bad date_due  \n";
}

print "\n\n*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-\n\n";
print "Report 0/NULL priority for 'unfound' reserves\n";
$sth = $dbh->prepare("SELECT count(*) FROM reserves WHERE found is NULL and (priority =0 or priority is NULL) ");
$sth->execute();

while (my $line=$sth->fetchrow_hashref()) {
   print "$line->{'count(*)'} reserves have bad priority  \n";
}


print "\n\n*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-\n\n";
print "Report bad onloan for items\n";
$sth = $dbh->prepare("SELECT count(*) FROM items WHERE onloan like '0000%'");
$sth->execute();

while (my $line=$sth->fetchrow_hashref()) {
   print "$line->{'count(*)'} items have bad onloan date \n";
}

print "\n\n*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-\n\n";
print "Report bad datelastseen for items\n";
$sth = $dbh->prepare("SELECT count(*) FROM items WHERE datelastseen like '0000%'");
$sth->execute();

while (my $line=$sth->fetchrow_hashref()) {
   print "$line->{'count(*)'} items have bad datelastseen date \n";
}
print "\n\n*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-\n\n";
print "Report bad datelastborrowed for items\n";
$sth = $dbh->prepare("SELECT count(*) FROM items WHERE datelastborrowed like '0000%'");
$sth->execute();

while (my $line=$sth->fetchrow_hashref()) {
   print "$line->{'count(*)'} items have bad datelastborrowed date \n";
}
print "\n\n*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-\n\n";
print "Report bad dateaccessioned for items\n";
$sth = $dbh->prepare("SELECT count(*) FROM items WHERE dateaccessioned like '0000%'");
$sth->execute();

while (my $line=$sth->fetchrow_hashref()) {
   print "$line->{'count(*)'} items have bad dateaccessioned \n";
}


exit;
