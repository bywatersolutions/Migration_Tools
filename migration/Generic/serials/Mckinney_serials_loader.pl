#!/usr/bin/perl
#---------------------------------
# Copyright 2012 ByWater Solutions
#
#---------------------------------
#
# -D Ruth Bavousett, based on some earlier work by Ian Walls
# 
# Modification log: (initial and date)
#    Joy Nelson - modified for Rutgers
#
#---------------------------------
#
# EXPECTS:
#   -Serials export
#
# DOES:
#   -inserts subscriptions and history, if --update is set
#   -inserts into serial table
#
# CREATES:
#   -nothing
#
# REPORTS:
#   -what would be done, if --debug is set
#   -count of records read
#   -count of subscriptions created

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

my $debug   = 0;
my $doo_eet = 0;
my $i       = 0;
my $j       = 0;
my $k       = 0;
my $written = 0;
my $problem = 0;
my $itemadded =0;
my $skipped =0;

my $input_filename        = $NULL_STRING;
my $biblio_map_filename   = $NULL_STRING;
my $location_map_filename = $NULL_STRING;
my $ccode_map_filename    = $NULL_STRING;
my $itype_map_filename    = $NULL_STRING;
my $default_branchcode    = $NULL_STRING;
my $vendor_map_filename   = $NULL_STRING;
my $default_librarian     = 'koha';
my $csv_delimiter         = ',';
my %biblio_map;
my $patternname;
my $period;
my $numbpattern;
my $internalnote = " ";
my $itype;
my $checkin;
my $createddate;
my $libhas;
my $closed;
my $periodicity;
my $pattern;
my $numberlength;
my $additem;
my $status;
my $planned;
my $arrived;
my $claim;

GetOptions(
    'in=s'           => \$input_filename,
    'biblio_map=s'   => \$biblio_map_filename,
    'def_branch=s'   => \$default_branchcode,
    'def_user=s'     => \$default_librarian,
    'delimiter=s'    => \$csv_delimiter,
    'additem'        => \$additem,
    'debug'          => \$debug,
    'update'         => \$doo_eet,
);

for my $var ($input_filename,$biblio_map_filename) {
   croak ("You're missing something") if $var eq $NULL_STRING;
}

my %delimiter = ( 'comma' => ',',
                  'tab'   => "\t",
                  'pipe'  => '|',
                );


print "Reading in biblio map file.\n";
if ($biblio_map_filename ne $NULL_STRING) {
   my $csv = Text::CSV_XS->new();
   open my $mapfile,'<',$biblio_map_filename;
   while (my $line = $csv->getline($mapfile)) {
      my @data = @$line;
      $biblio_map{$data[0]} = $data[1];
   }
   close $mapfile;
}

my $subscription_id;
my $serials = 0;
my $dbh = C4::Context->dbh();
my $sub_insert_sth = $dbh->prepare("INSERT INTO subscription (biblionumber, librarian, branchcode,startdate,
                                    firstacquidate,internalnotes,closed,periodicity,numberlength,
                                    serialsadditems, graceperiod, staffdisplaycount,
                                    opacdisplaycount,status,countissuesperunit,numberpattern) 
                                    VALUES (?,?,?,?,
                                            ?,?,0,?,?,
                                            1,14,12,
                                            12,1,1,?)");
my $hist_insert_sth = $dbh->prepare("INSERT INTO subscriptionhistory 
                                     (biblionumber, subscriptionid, histstartdate,recievedlist,missinglist) 
                                     VALUES (?,?,?,?,' ')");
my $upd_subhistory_sth = $dbh->prepare("UPDATE subscriptionhistory set recievedlist = concat(recievedlist,'; ',?)
                                               where subscriptionid =?");


my $getbibitemnumber_sth = $dbh->prepare ("SELECT biblioitemnumber from biblioitems where biblionumber = ?");
my $get_subscripid_sth = $dbh->prepare("SELECT subscriptionid from subscription WHERE biblionumber = ? and branchcode = ?");
my $add_serial_sth = $dbh->prepare("INSERT into serial (biblionumber, subscriptionid, serialseq, status, planneddate,publisheddate,claimdate) 
                                   VALUES (?,?,?,?,?,?,?)");


my $csv=Text::CSV_XS->new({ binary => 1, sep_char => $delimiter{$csv_delimiter} });

open my $input_file,'<:utf8',$input_filename;
$csv->column_names($csv->getline($input_file));

LINE:
while (my $line=$csv->getline_hr($input_file)) {
   last LINE if ($debug && $i>6000);
   $i++;
   print '.'    unless ($i % 10);
   print "\r$i" unless ($i % 100);
   $debug and print Dumper($line);

   my $biblink = $line->{'BibId'};
   my $biblionumber = $biblio_map{$biblink};
$debug and print "$biblink is now $biblionumber\n";
   if (!$biblionumber) {
      print "DANGER DANGER DANGER REPORT THIS biblio record: $biblink not found in the map!\n";
      $problem++;
      next LINE;
   }

   my $volume = $line->{'serialseq'} || "no volume information provided";
#   $default_branchcode = $line->{'branch'};
   my $intnotes = $line->{'staffnote'} || " " ;
   $createddate =  "2016-09-08";
   $planned = $line->{'chronologydate'} || "2016-09-08";
   $arrived = $line->{'arrivaldate'} || "2016-09-08";
   $claim = $line->{'claimdate'} || "NULL";

   $checkin =  "koha";


   $closed=0;
   $numberlength = 12;
   $periodicity =13;
   $pattern =1;
   
   $status = $line->{'status'} || 2;
   if ($status eq 'Not Available') {
     $status = 4;
   }
   if ($status eq 'Pending Claim') {
     $status = 7;
   }
   if ($status eq 'Received') {
     $status = 2;
   }

   #check to see if subscription exists for this biblionumber and branchcode
   $get_subscripid_sth->execute($biblionumber,$default_branchcode);
   my $rec=$get_subscripid_sth->fetchrow_hashref();
   $subscription_id = $rec->{'subscriptionid'};

   if ($subscription_id) {
     print "$subscription_id found - updating subscription.\n";
   }
   else {
     print "no subscription id found -adding subscription.\n"; 
   }

   #Add subscription and history record
 if ( (!$subscription_id ) && $doo_eet ) {
      print "$biblionumber,$checkin,$default_branchcode\n";
       $sub_insert_sth->execute($biblionumber,$checkin, $default_branchcode,$createddate,$createddate, $intnotes,$periodicity,$numberlength,$pattern);
       my $addedsubscription_id = $dbh->last_insert_id(undef, undef, undef, undef);
       $hist_insert_sth->execute($biblionumber, $addedsubscription_id, $createddate, $volume);
       $add_serial_sth ->execute($biblionumber, $addedsubscription_id, $volume,$status, $planned,$arrived,$claim);
       $serials++;
       $written++;
     #add item if additem is specified.
     if ($additem) {
       $getbibitemnumber_sth ->execute($biblionumber);
     }
   }
   #if subscription found then fill out subhistory received list and add serial record
    if (($doo_eet) && ($subscription_id)) {
    $upd_subhistory_sth ->execute($volume, $subscription_id);
    $add_serial_sth ->execute($biblionumber, $subscription_id, $volume,$status,$planned,$arrived,$claim);
    $serials++;
    }


}

#next LINE;


close $input_file;

print << "END_REPORT";

$i records read.
$written subscription records written.
$serials serial records added.
$itemadded item records added.
$problem records not loaded due to missing bibliographic records.
$skipped records not loaded due to duplicate barcodes.
END_REPORT

exit;



#   if (exists $pattern_map{$ct_num}){
#      $patternname = $pattern_map{$ct_num};
#      $debug and print "$patternname\n";
#   }
#   else {
#      $patternname = 'Irregular';
#   }



#   my $subscription_start_date = $sub_start;
#   $subscription_start_date =~ m/^.*(\d{4}).*$/;
#   if ($1) {
#      $subscription_start_date = $1 . '-01-01';
#   }
#   else {
#      $subscription_start_date = undef;
#   }
#   $debug and print "Biblio: $biblionumber START: $subscription_start_date\n";

