#!/usr/bin/perl
#---------------------------------
# Copyright 2012 ByWater Solutions
#
#---------------------------------
#
# -D Ruth Bavousett, based on some earlier work by Ian Walls
# 
# Modification log: (initial and date)
#    Joy Nelson - modified for Brooks 
#
#---------------------------------
#
# EXPECTS:
#   -Serials export
#   -branchcode
#
# DOES:
#   -checks to see if item is already loaded in items table, if so, skips
#   -inserts subscriptions and manual history, if --update is set
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

my $input_filename      = $NULL_STRING;
my $biblio_map_filename = $NULL_STRING;
my $location_map_filename = $NULL_STRING;
my $itype_map_filename = $NULL_STRING;
my $default_branchcode  = $NULL_STRING;
my $default_librarian   = 'koha';
my $csv_delimiter       = ',';
my %biblio_map;
my %location_map;
my %itype_map;
my %vendor_map;
my $patternname;
my $period;
my $numbpattern;
my $internalnote = " ";

GetOptions(
    'in=s'         => \$input_filename,
    'biblio_map=s' => \$biblio_map_filename,
    'location_map=s'=> \$location_map_filename,
    'itype_map=s'  => \$itype_map_filename,
    'def_branch=s' => \$default_branchcode,
    'def_user=s'   => \$default_librarian,
    'delimiter=s'  => \$csv_delimiter,
    'debug'        => \$debug,
    'update'       => \$doo_eet,
);

for my $var ($input_filename,$biblio_map_filename,$location_map_filename) {
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
print "Reading in location map file.\n";
if ($location_map_filename ne $NULL_STRING) {
   my $csv = Text::CSV_XS->new();
   open my $mapfile,'<',$location_map_filename;
   while (my $line = $csv->getline($mapfile)) {
      my @data = @$line;
      $location_map{$data[0]} = $data[1];
   }
   close $mapfile;
}

print "Reading in itype map file.\n";
if ($itype_map_filename ne $NULL_STRING) {
   my $csv = Text::CSV_XS->new();
   open my $mapfile,'<',$itype_map_filename;
   while (my $line = $csv->getline($mapfile)) {
      my @data = @$line;
      $itype_map{$data[0]} = $data[1];
   }
   close $mapfile;
}

my $subscription_id;
my $serials = 0;
my $dbh = C4::Context->dbh();
my $sub_insert_sth = $dbh->prepare("INSERT INTO subscription (biblionumber, librarian, branchcode, notes,  
                                     location, countissuesperunit, serialsadditems, graceperiod, status,
                                     callnumber, internalnotes, staffdisplaycount,opacdisplaycount, periodicity, numberlength) 
                                    VALUES (?,'koha','COLLEGE','The current issue of this magazine does not circulate.',
                                            ?,1,1,14,1,
                                            ?,?,99,99,?,?)");
my $hist_insert_sth = $dbh->prepare("INSERT INTO subscriptionhistory 
                                     (biblionumber, subscriptionid, librariannote, recievedlist) 
                                     VALUES (?,?,?,?)");

my $get_subscripid_sth = $dbh->prepare("SELECT subscriptionid from subscription WHERE biblionumber = ?");
my $upd_subhistory_sth = $dbh->prepare("UPDATE subscriptionhistory set recievedlist = concat(recievedlist,'; ',?) 
                                               where subscriptionid =?");

my $add_serial_sth = $dbh->prepare("INSERT into serial (biblionumber, subscriptionid, serialseq, status, notes, routingnotes) 
                                   VALUES (?,?,?,2,?,?)");

#QUERIES FOR ADDING TO ITEMS
my $getbibitemnumber_sth = $dbh->prepare ("SELECT biblioitemnumber from biblioitems where biblionumber = ?");
my $add_items_sth = $dbh->prepare("INSERT INTO items (biblionumber, biblioitemnumber, barcode, homebranch, holdingbranch,
                                  notforloan, damaged,itemlost,withdrawn,location, enumchron, itemcallnumber, itype)
                                  VALUES (?,?,?,'COLLEGE','COLLEGE',0,0,0,0,?,?,?,?)");

#QUERY FOR ADDING TO SERIALITEMS
my $find_item_sth = $dbh->prepare("SELECT itemnumber from items where barcode =?");
my $get_serialid_sth =$dbh->prepare("SELECT serialid from serial where routingnotes = ?");
my $insert_serialitem_sth = $dbh->prepare("INSERT INTO serialitems (itemnumber, serialid) VALUES (?,?)");

my $csv=Text::CSV_XS->new({ binary => 1, sep_char => $delimiter{$csv_delimiter} });

open my $input_file,'<:utf8',$input_filename;
$csv->column_names($csv->getline($input_file));

LINE:
while (my $line=$csv->getline_hr($input_file)) {
   last LINE if ($debug && $i>6000);
   $i++;
   print '.'    unless ($i % 10);
   print "\r$i" unless ($i % 100);
#   $debug and print Dumper($line);

   my $biblink = $line->{'Biblink'};
   my $biblionumber = $biblio_map{$biblink};
   if (!$biblionumber) {
      print "TLC biblio record: $biblink not found in the map!\n";
      $problem++;
      next LINE;
   }
#   $debug and print "TLC bib: $biblink has map value of $biblio_map{$biblink}\n";

   my $itype = $line->{'852suba'};
   my $itemtype = $itype_map{$itype};
#$debug and print "$itype and $itemtype\n";
   my $loc = $line->{'852suba'} || " ";
   my $location = $location_map{$itype} || " ";
#$debug and print "$loc and $location\n";
   my $callnum  = $line->{'subi'} || " ";
   my $callnum2 = $line->{'subj'} || " ";
   my $callnum3 = $line->{'receiveddate'} || " ";
   my $total_callnum = $callnum . " " . $callnum2. " " .$callnum3;
#$debug and print "$total_callnum\n";
#   my $subscrip_note =  $line->{'852subx'}  || " ";
   my $volume = ($line->{'subi'}. ':' . $line->{'subj'}) || "Supplement";
 #  my $volume_note = $line->{'864a'} || " ";
#   $internalnote = $itype ." ". $loc ." ". $callnum ." ". $subscrip_note;
   my $barcode = $line->{'barcode'} || " ";
  
# if ($barcode eq " ") {
    # $barcode = "AUTO" . $i;
  # }
#$debug and print "$barcode\n";

#set periodicity and numbering pattern
#   $patternname = $line->{'853w'} || 'x' ;
#   if ($patternname eq 'q' ){   #quarterly
#      $period = 7;
#      $numbpattern = 4;
#   }
#   elsif ($patternname eq 'b'){  #bimonthly
#      $period = 6;
#      $numbpattern = 6;
#   }
#   elsif ($patternname eq 'a'){  #annual
#      $period = 10;
#      $numbpattern = 1;
#   }
#   elsif ($patternname eq 'e'){  #biweekly
#      $period = 3;
#      $numbpattern = 26;
#   }
#   elsif ($patternname eq 'f'){ #semiannual
#      $period = 9;
#      $numbpattern = 2;
#   }
#   elsif ($patternname eq 'm'){ #monthly
#      $period = 5;
#      $numbpattern = 12;
#   }
#   elsif ($patternname eq 's'){  #semimonthly
#      $period = 6;
#      $numbpattern = 24;
#   }
#   elsif ($patternname eq 'x'){ #irregular
#      $period =32;
#      $numbpattern = 0;
#   }
#   elsif ($patternname eq 'w'){ #weekly
#      $period = 2;
#      $numbpattern = 52;
#   }
#   elsif ($patternname eq '6'){   #6  6 times a year?
#      $period = 6;
#      $numbpattern = 6;
#   }
#$debug and print "$period, $numbpattern\n";



#check to see if there is already an item loaded for this serial (duplicate barcode)
   $find_item_sth->execute($barcode);
   my $itemexist=$find_item_sth->fetchrow_hashref();
   my $item_already=$itemexist->{'itemnumber'};
   if ($item_already) {
     $skipped++;
     print "Duplicate barcode: $item_already, $barcode serial record skipped\n";
     next LINE;
   }   

   #check to see if subscription exists for this biblionumber
   $get_subscripid_sth->execute($biblionumber);
   my $rec=$get_subscripid_sth->fetchrow_hashref();
   $subscription_id = $rec->{'subscriptionid'};

   if ($subscription_id) {
     print "$subscription_id found - updating.\n";
   }
   else {
     print "no subscription id found -adding subscription.\n"; 
   }

   #no subscription then add subscription record and history record
   if ( (!$subscription_id ) && $doo_eet ) {
       $sub_insert_sth->execute($biblionumber, $location, $total_callnum,$internalnote,$period,$numbpattern);
       my $addedsubscription_id = $dbh->last_insert_id(undef, undef, undef, undef);
#       $subscription_id = $addedsubscription_id;
       $hist_insert_sth->execute($biblionumber, $addedsubscription_id, $volume);
       $add_serial_sth ->execute($biblionumber, $addedsubscription_id, $volume, $barcode);
      $serials++;
      $written++;
   }

   #if subscription found then fill out subhistory received list and add serial record
    if (($doo_eet) && ($subscription_id)) {
    $upd_subhistory_sth ->execute($volume, $subscription_id);
    $add_serial_sth ->execute($biblionumber, $subscription_id, $volume, $barcode);
    $serials++;
    }

if ($doo_eet) {
#add item record
$getbibitemnumber_sth ->execute($biblionumber);
my $rec2=$getbibitemnumber_sth->fetchrow_hashref();
my $bibitemnum = $rec2->{'biblioitemnumber'};

$add_items_sth->execute($biblionumber, $bibitemnum, $barcode,$location,$volume,$total_callnum,$itemtype);

#get itemnumber and serialid
$find_item_sth->execute($barcode);
my $rec4=$find_item_sth->fetchrow_hashref();
my $item_num=$rec4->{'itemnumber'};
$itemadded++;
$get_serialid_sth->execute($barcode);
my $rec3=$get_serialid_sth->fetchrow_hashref();
my $serial_id=$rec3->{'serialid'};

#create serialitems record 
$insert_serialitem_sth->execute($item_num,$serial_id);
}

next LINE;

}
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

