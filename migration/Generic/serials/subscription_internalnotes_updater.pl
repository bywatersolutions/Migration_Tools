#!/usr/bin/perl
#---------------------------------
# Copyright 2013 ByWater Solutions
#
#---------------------------------
#
# -Joy Nelson
#  --edited to append notes to existing notes
#---------------------------------

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use Text::CSV;
use C4::Context;
use C4::Items;
$|=1;
my $debug=0;
my $doo_eet=0;
my $infile_name = "";
my $biblio_map_filename;
my %biblio_map;
my $NULL_STRING = "";
my $csv_delim = "comma";

GetOptions(
    'in=s'            => \$infile_name,
    'debug'           => \$debug,
    'update'          => \$doo_eet,
    'biblio_map=s'      => \$biblio_map_filename,
    'delimiter=s'     => \$csv_delim,
);

my %DELIMITER = ( 'comma' => q{,},
                  'tab'   => "\t",
                  'pipe'  => q{|},
                );

if (($infile_name eq '')){
  print "Something's missing.\n";
  exit;
}

print "Reading in biblio map file.\n";
if ($biblio_map_filename ne $NULL_STRING) {
   my $csv = Text::CSV_XS->new();
   open my $biblio_mapfile,'<',$biblio_map_filename;
   while (my $line = $csv->getline($biblio_mapfile)) {
      my @data = @$line;
      $biblio_map{$data[0]} = $data[1];
   }
   close $biblio_mapfile;
}

open my $in,"<$infile_name";
my $i=0;
my $k=0;
my $dbh = C4::Context->dbh();
my $sth = $dbh->prepare("UPDATE subscription SET internalnotes=? WHERE biblionumber=?");
my $note_sth = $dbh->prepare("SELECT biblionumber,internalnotes FROM subscription WHERE biblionumber=?");

my $csv=Text::CSV->new({ binary => 1, sep_char => $DELIMITER{$csv_delim} });
my $exceptcount=0;
my $j=0;
open my $io,"<$infile_name";
my $headerline = $csv->getline($io);
my @fields=@$headerline;
$debug and print Dumper(@fields);

RECORD:
while (my $line=$csv->getline($io)){
   $debug and last if ($i>10);
   $i++;
   print ".";
   print "\r$i" unless $i % 100;
   my @data = @$line;
   $debug and print Dumper(@data);

   my $finalnote=q{};
   next RECORD if $data[0] eq '';

#map bibid to biblionumber
   if ( exists($biblio_map{$data[0]}) ) {
      $debug and print "MAPPED Biblink: $data[0]  TO $biblio_map{$data[0]}\n";
      $data[0] = $biblio_map{$data[0]};
   }

   $note_sth->execute($data[0]);

   my $rec=$note_sth->fetchrow_hashref();
   my $bibnumber = $rec->{'biblionumber'};
   my $currnotes = $rec->{'internalnotes'} ;

   if (!$bibnumber) {
     next RECORD;
   }

   if ( !$currnotes )  {
      $finalnote = $data[1];
   }
   else {
      $finalnote = $currnotes."\n".$data[1];
   }

   $debug and print "Biblio: $bibnumber  NOTE: $finalnote\n";
   if ($bibnumber && $doo_eet){
      $sth->execute($finalnote,$bibnumber);
      $j++;
   }
}

close $in;

print "\n\n$i lines read.\n$j notes loaded.\n";
exit;
