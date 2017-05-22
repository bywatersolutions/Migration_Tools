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
my $numberlength;
my $additem;

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
                                    opacdisplaycount,status,countissuesperunit) 
                                    VALUES (?,?,?,?,
                                            ?,?,?,?,?,
                                            1,14,12,
                                            12,1,1)");
my $hist_insert_sth = $dbh->prepare("INSERT INTO subscriptionhistory 
                                     (biblionumber, subscriptionid, histstartdate,recievedlist,missinglist) 
                                     VALUES (?,?,?,?,' ')");
my $getbibitemnumber_sth = $dbh->prepare ("SELECT biblioitemnumber from biblioitems where biblionumber = ?");
my $get_subscripid_sth = $dbh->prepare("SELECT subscriptionid from subscription WHERE biblionumber = ? and branchcode = ?");
my $add_serial_sth = $dbh->prepare("INSERT into serial (biblionumber, subscriptionid, serialseq, status, planneddate,publisheddate) 
                                   VALUES (?,?,?,2,?,?)");


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

   my $biblink = $line->{'Biblink'};
   my $biblionumber = $biblio_map{$biblink};
$debug and print "$biblink is now $biblionumber\n";
   if (!$biblionumber) {
      print "DANGER DANGER DANGER REPORT THIS biblio record: $biblink not found in the map!\n";
      $problem++;
      next LINE;
   }

   my $volume =  " ";
   $default_branchcode = $line->{'branch'};
   my $intnotes = $line->{'853a'}.$line->{'853b'}.$line->{'853c'}.$line->{'853u'}.$line->{'853y'} ;
   $createddate = $line->{'fromdate'} || "2015-11-16";
   if ($createddate eq 'NONE') {
       $createddate = '2015-11-16';
   }

   $checkin = $line->{'holdingnumber001'} || "koha";
   $libhas =  " ";

$debug and print  "details:volume $volume :branch $default_branchcode  :notes $intnotes :fromdate $createddate :checkin $checkin :libhas $libhas\n";

   $closed=0;
   $numberlength = $line->{'853u'};

   $debug and print "frequency is $periodicity\n";
   if  ($numberlength eq '12') {
    $periodicity=7;
   }
   elsif ($numberlength eq '13') {
    $periodicity=7;
   }
   elsif ($numberlength eq '26') {
    $periodicity= 5;
   }
   elsif ($numberlength eq '4') {
    $periodicity= 9;
   }
   elsif ($numberlength eq '52') {
    $periodicity=4;
   }
   elsif ($numberlength eq '6') {
    $periodicity=8 ;
   }
   else {
    $periodicity = 13;
   }

$debug and print "periodicity $periodicity  closed $closed\n";

   #check to see if subscription exists for this biblionumber and branchcode
   $get_subscripid_sth->execute($biblionumber,$default_branchcode);
   my $rec=$get_subscripid_sth->fetchrow_hashref();
   $subscription_id = $rec->{'subscriptionid'};

   if ($subscription_id) {
     print "$subscription_id found - adding second subscription.\n";
   }
   else {
     print "no subscription id found -adding subscription.\n"; 
   }

   #Add subscription and history record
   if ( $doo_eet ) {
      print "$biblionumber,$checkin,$default_branchcode\n";
       $sub_insert_sth->execute($biblionumber,$checkin, $default_branchcode,$createddate,$createddate, $intnotes,$closed,$periodicity,$numberlength);
       my $addedsubscription_id = $dbh->last_insert_id(undef, undef, undef, undef);
       $hist_insert_sth->execute($biblionumber, $addedsubscription_id, $createddate, $libhas);
       $add_serial_sth ->execute($biblionumber, $addedsubscription_id, $volume, $createddate,$createddate);
       $serials++;
       $written++;
     #add item if additem is specified.
     if ($additem) {
       $getbibitemnumber_sth ->execute($biblionumber);
#       my $rec2=$getbibitemnumber_sth->fetchrow_hashref();
#       my $binumber = $rec2->{'biblioitemnumber'};
#       my $itype = 'PERIODICAL';
#       if ( ($loc eq 'mmcft') || ($loc eq 'intej') || ($loc eq 'acelr') || ($loc eq 'csuij')|| ($loc eq 'cuwir')|| ($loc eq 'shste')|| ($loc eq 'wlcas') ) {
#         $itype = 'EJNL';
#       }
#       print "itemtype is $itype,$biblink,$biblionumber,$binumber,$default_branchcode, $location, $ccode\n";
#       $additem_sth->execute($biblionumber,$binumber,$default_branchcode,$default_branchcode,$location,$ccode,$itype);
#       $itemadded++;
     }
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

